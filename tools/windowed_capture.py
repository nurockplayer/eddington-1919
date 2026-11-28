#!/usr/bin/env python3
"""Run Godot capture scripts inside an admitted tachi-run host command."""

import argparse
import os
from pathlib import Path
import selectors
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import time


GODOT = "/Applications/Godot.app/Contents/MacOS/Godot"
STAGES = ("staging", "draw expected", "first frame saved", "done")
ENGINE_ERRORS = ("SCRIPT ERROR:", "SHADER ERROR:", "STYLE ERROR:", "ERROR:")


class CaptureFailure(Exception):
    def __init__(self, message, status=1):
        super().__init__(message)
        self.status = status


def terminate_group(process):
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except PermissionError:
        # macOS can deny a group signal while its exited leader awaits reaping.
        if process.poll() is None:
            raise
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    except ProcessLookupError:
        pass


def run_phase(label, command, env, deadline, first_frame_seconds, interrupted, log):
    log(f"CAPTURE {label}: {shlex.join(command)}")
    with subprocess.Popen(
        command, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        start_new_session=True,
    ) as process, selectors.DefaultSelector() as output:
        output.register(process.stdout, selectors.EVENT_READ)
        pending = b""
        stages = []
        first_frame_deadline = None

        def record(line):
            nonlocal first_frame_deadline
            text = line.decode(errors="replace").rstrip("\r")
            log(text)
            if text.startswith(ENGINE_ERRORS):
                raise CaptureFailure(f"{label}: {text}")
            if label == "windowed run" and text.startswith("CAPTURE "):
                stage = text.removeprefix("CAPTURE ")
                if stage in STAGES:
                    if tuple(stages + [stage]) != STAGES[:len(stages) + 1]:
                        raise CaptureFailure(f"unexpected capture stage: {stage}")
                    stages.append(stage)
                    if stage == "draw expected":
                        first_frame_deadline = time.monotonic() + first_frame_seconds
                    elif stage == "first frame saved":
                        first_frame_deadline = None

        try:
            while True:
                if interrupted():
                    raise CaptureFailure(f"{label} interrupted", 128 + interrupted())
                now = time.monotonic()
                if now >= deadline:
                    stage = stages[-1] if stages else label
                    raise CaptureFailure(f"wall-clock limit exceeded at {stage}", 124)
                if first_frame_deadline is not None and now >= first_frame_deadline:
                    raise CaptureFailure("first-frame deadline exceeded after draw expected", 124)
                if not output.get_map() and process.poll() is not None:
                    break
                next_deadline = min(deadline, first_frame_deadline or deadline)
                for key, _ in output.select(min(0.2, next_deadline - now)):
                    chunk = os.read(key.fd, 65536)
                    if not chunk:
                        output.unregister(key.fileobj)
                        if pending:
                            record(pending)
                        continue
                    *lines, pending = (pending + chunk).split(b"\n")
                    for line in lines:
                        record(line)
            if process.returncode:
                code = process.returncode
                raise CaptureFailure(f"{label} exited {code}", code if code > 0 else 128 - code)
            if label == "windowed run" and tuple(stages) != STAGES:
                raise CaptureFailure(f"capture exited without completion (last stage: {stages[-1] if stages else 'none'})")
        except BaseException:
            terminate_group(process)
            raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--settings", type=Path)
    parser.add_argument("--wall-seconds", type=float, required=True)
    parser.add_argument("--first-frame-seconds", type=float, required=True)
    parser.add_argument("--engine-arg", action="append", default=[])
    parser.add_argument("--expect", action="append", required=True, metavar="COUNT:GLOB")
    parser.add_argument("output_parent", type=Path)
    parser.add_argument("script")
    separator = sys.argv.index("--") if "--" in sys.argv else len(sys.argv)
    args = parser.parse_args(sys.argv[1:separator])
    script_args = sys.argv[separator + 1:]
    if not (0 < args.wall_seconds < float("inf") and 0 < args.first_frame_seconds < float("inf")):
        parser.error("deadlines must be finite positive seconds")

    expected = []
    for spec in args.expect:
        count, _, pattern = spec.partition(":")
        if not count.isdecimal() or int(count) < 1 or not pattern or Path(pattern).is_absolute() or ".." in Path(pattern).parts:
            parser.error(f"expected COUNT:GLOB relative to the attempt directory, got {spec!r}")
        expected.append((int(count), pattern))

    received_signal = 0

    def interrupt(signum, _frame):
        nonlocal received_signal
        received_signal = signum

    for signum in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(signum, interrupt)

    args.output_parent.mkdir(parents=True, exist_ok=True)
    attempt = Path(tempfile.mkdtemp(prefix="attempt-", dir=args.output_parent.resolve()))
    settings = attempt / "settings.cfg"
    if args.settings:
        shutil.copyfile(args.settings, settings)
    else:
        settings.touch()
    env = dict(os.environ, EDD_CAPTURE_DIR=str(attempt), EDD_SETTINGS_PATH=str(settings), TZ="Asia/Tokyo")
    script = args.script if args.script.startswith("res://") else str(Path(args.script).resolve())
    common = [GODOT, "--path", str(args.project.resolve())]

    with (attempt / "render.log").open("w", encoding="utf-8") as log_file:
        def log(message):
            print(message, file=log_file, flush=True)
            print(message, file=sys.stderr, flush=True)

        deadline = time.monotonic() + args.wall_seconds
        log(f"CAPTURE attempt: {attempt}")
        try:
            for label, options in (
                ("import", ["--headless", "--import"]),
                ("check-only", ["--headless", "--check-only", "--script", script]),
                ("windowed run", [
                    "--windowed", "--resolution", "1280x720", "--fixed-fps", "60", "--always-on-top",
                    *args.engine_arg, "--script", script, "--", *script_args,
                ]),
            ):
                run_phase(label, common + options, env, deadline, args.first_frame_seconds,
                          lambda: received_signal, log)
            for count, pattern in expected:
                found = sum(path.is_file() and path.stat().st_size > 0 for path in attempt.glob(pattern))
                if found != count:
                    raise CaptureFailure(f"expected {count} nonempty outputs matching {pattern}, found {found}")
        except CaptureFailure as error:
            log(f"CAPTURE FAILED: {error}")
            return error.status
    print(attempt)
    return 0


if __name__ == "__main__":
    sys.exit(main())
