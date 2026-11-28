"""Run the windowed capture acceptance cases inside tachi-run --heavy --host."""

import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile


TOOLS = Path(__file__).resolve().parent
FIXTURE = """extends SceneTree

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    root.size = Vector2i(160, 90)
    var mode := OS.get_cmdline_user_args()[0]
    var out := OS.get_environment("EDD_CAPTURE_DIR")
    print("CAPTURE staging")
    if mode == "suppress":
        RenderingServer.render_loop_enabled = false
    print("CAPTURE draw expected")
    await RenderingServer.frame_post_draw
    if mode == "suppress":
        return
    if mode == "block":
        print("FIXTURE blocked pid=", OS.get_process_id())
        await process_frame
        while true:
            OS.delay_msec(100)
    if mode == "partial_cloud":
        var interrupted := "res://interrupted"
        if not FileAccess.file_exists(interrupted):
            FileAccess.open(interrupted, FileAccess.WRITE).store_string("yes")
            print("FIXTURE interrupt after day_clear")
            await create_timer(3600.0).timeout
    for i in 960:
        FileAccess.open(out.path_join("f_%05d.png" % (i + 1)), FileAccess.WRITE).store_string("frame")
        if i == 0:
            print("CAPTURE first frame saved")
    FileAccess.open(out.path_join("camera.tsv"), FileAccess.WRITE).store_string("camera")
    print("CAPTURE done")
    quit()
"""


def check(result, code, message):
    print(result.stdout, end="", flush=True)
    assert result.returncode == code and message in result.stdout, (result.returncode, message)


def main(root):
    project = root / "fixture"
    row2_script = project / "tools/row2/capture.gd"
    row2_script.parent.mkdir(parents=True)
    (project / "project.godot").write_text(
        'config_version=5\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',
    )
    row2_script.write_text(FIXTURE)
    broken = root / "broken.gd"
    broken.write_text("extends SceneTree\nfunc broken(\n")
    outputs = root / "outputs"

    def capture(mode, script=row2_script, wall=25, first=15):
        return subprocess.run(
            [sys.executable, str(TOOLS / "windowed_capture.py"),
             "--wall-seconds", str(wall), "--first-frame-seconds", str(first),
             "--engine-arg=--resolution", "--engine-arg=160x90",
             "--expect", "1:camera.tsv", str(outputs / mode), str(script), "--", mode],
            cwd=project, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        )

    check(capture("suppress", first=2), 124, "first-frame deadline exceeded")
    print("PASS 1 suppressed first draw", flush=True)
    block = capture("block", wall=18, first=60)
    check(block, 124, "wall-clock limit exceeded at draw expected")
    assert "Godot Engine" in block.stdout.split("CAPTURE windowed run:", 1)[1]
    pid = int(block.stdout.split("FIXTURE blocked pid=", 1)[1].splitlines()[0])
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        pass
    else:
        raise AssertionError(f"blocked Godot is still running (pid {pid})")
    print("PASS 2 blocked loop terminated", flush=True)
    invalid = capture("broken", broken)
    check(invalid, 1, "CAPTURE FAILED: check-only")
    assert "CAPTURE windowed run:" not in invalid.stdout
    print("PASS 3 broken script caught before window launch", flush=True)

    command = ["/bin/bash", str(TOOLS / "row2/capture.sh"), str(outputs / "row2")]
    with subprocess.Popen(command, cwd=project, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          start_new_session=True, text=True) as first_attempt:
        for line in first_attempt.stdout:
            print(line, end="", flush=True)
            if line.strip() == "FIXTURE interrupt after day_clear":
                os.killpg(first_attempt.pid, signal.SIGTERM)
                break
        tail, _ = first_attempt.communicate()
        print(tail, end="", flush=True)
        assert first_attempt.returncode == -signal.SIGTERM
        assert "CAPTURE FAILED: windowed run interrupted" in tail
    check(subprocess.run(command, cwd=project, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True),
          0, "CAPTURE done")
    expected = {"day_clear": 2, "partial_cloud": 2, "totality_clear": 1, "totality_thin": 1}
    for state, count in expected.items():
        attempts = sorted((outputs / "row2" / state).glob("attempt-*"), key=lambda path: path.stat().st_mtime_ns)
        assert len(attempts) == count
        assert (attempts[-1] / "f_00960.png").is_file()
        if state == "partial_cloud":
            assert not (attempts[0] / "f_00001.png").exists()
    print("PASS 4 Row 2 restarted with fresh attempts after day_clear", flush=True)


if __name__ == "__main__":
    with tempfile.TemporaryDirectory(prefix="edd-windowed-capture-") as scratch:
        main(Path(scratch))
