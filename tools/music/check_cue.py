#!/usr/bin/env python3
"""Report objective numbers for a rendered cue (OGG or WAV). Report only.

Prints duration, peak, RMS, the loop-seam step against the 99th-percentile
step inside the file, the fraction of 50 ms frames that are near-silent, the
strength of the 1.9 kHz band (score.gd suppresses the metronome band) and
F#4 against F4 (F-sharp is coda-only and must not appear in this cue).

With `--oneshot` the cue does not loop, so the seam lines are replaced by the
RMS of the last 50 ms, which the fade-out is meant to bring under 0.002.

With `--strict` the same numbers are checked against the limits the render
scripts rely on and any violation exits 1: peak <= 0.5; a loop's seam step <=
its p99 step; a one-shot's last-50 ms RMS <= 0.002; F#4/F4 <= 0.05 (F-sharp is
coda-only, so coda_resolution is exempt); and, when `--expect-seconds` is
given, a duration within 0.01 s of it.

Usage: uv run --with numpy python tools/music/check_cue.py
           [--oneshot] [--strict] [--expect-seconds N] <cue.ogg|cue.wav>
Without --strict it always exits 0; read the numbers.
"""
import argparse
import subprocess
import sys
from pathlib import Path

import numpy as np

RATE = 48000
FRAME_S = 0.05
SILENT_RMS = 0.005


def decode(path: str, channels: int = 1) -> np.ndarray:
    """Decode to float64 at RATE: mono by default, or the given channel count."""
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", str(channels), "-ar", str(RATE), "-"],
        check=True, capture_output=True,
    ).stdout
    return np.frombuffer(raw, dtype="<f4").astype(np.float64)


def channel_peak(path: str) -> float:
    """Largest |sample| over every source channel, not just the mono downmix."""
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=channels",
         "-of", "csv=p=0", path],
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    return float(np.max(np.abs(decode(path, int(probe or "1")))))


def goertzel_amplitude(x: np.ndarray, frequency: float) -> float:
    n = np.arange(x.size)
    return 2.0 * abs(np.dot(x, np.exp(-2j * np.pi * frequency * n / RATE))) / x.size


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--oneshot", action="store_true",
                        help="one-shot cue: no loop seam, report the final 50 ms")
    parser.add_argument("--strict", action="store_true",
                        help="exit 1 if any number is outside its limit")
    parser.add_argument("--expect-seconds", type=float, default=None,
                        help="expected duration in seconds (checked with --strict)")
    parser.add_argument("path")
    args = parser.parse_args()
    x = decode(args.path)
    if x.size < 2:
        print("empty audio")
        if args.strict:
            print("strict violation empty audio")
            sys.exit(1)
        return
    peak = max(float(np.max(np.abs(x))), channel_peak(args.path))
    rms = float(np.sqrt(np.mean(x * x)))
    steps = np.abs(np.diff(x))
    seam = float(abs(x[0] - x[-1]))
    p99 = float(np.percentile(steps, 99))
    frames = x.size // int(RATE * FRAME_S)
    if frames:
        framed = x[: frames * int(RATE * FRAME_S)].reshape(frames, int(RATE * FRAME_S))
        frame_rms = np.sqrt(np.mean(framed * framed, axis=1))
        near_silent = float(np.mean(frame_rms < SILENT_RMS))
    else:
        near_silent = 1.0
    band = goertzel_amplitude(x, 1900.0)
    fs4 = goertzel_amplitude(x, 369.99)
    f4 = goertzel_amplitude(x, 349.23)
    print(f"file            {args.path}")
    print(f"duration        {x.size / RATE:.3f} s")
    print(f"peak            {peak:.4f}")
    print(f"rms             {rms:.4f}")
    if args.oneshot:
        tail = x[-int(RATE * FRAME_S):]
        tail_rms = float(np.sqrt(np.mean(tail * tail)))
        verdict = "ok" if tail_rms <= 0.002 else "EXCEEDS 0.002"
        print(f"last-50ms rms   {tail_rms:.6f}   ({verdict})")
    else:
        print(f"seam |delta|    {seam:.6f}")
        print(f"p99 |delta|     {p99:.6f}   ({'seam <= p99' if seam <= p99 else 'SEAM EXCEEDS P99'})")
    print(f"near-silent      {near_silent * 100:.1f} % of 50 ms frames")
    print(f"1900 Hz amp/rms  {band / rms:.4f}" if rms > 0 else "1900 Hz amp/rms  n/a")
    print(f"F#4 amp          {fs4:.6f}")
    print(f"F4 amp           {f4:.6f}")
    print(f"F#4/F4           {fs4 / f4:.4f}" if f4 > 0 else "F#4/F4           n/a")

    if not args.strict:
        return
    violations = []
    if peak > 0.5:
        violations.append(f"peak {peak:.4f} > 0.5")
    if args.oneshot:
        if tail_rms > 0.002:
            violations.append(f"last-50ms rms {tail_rms:.6f} > 0.002")
    elif seam > p99:
        violations.append(f"seam |delta| {seam:.6f} > p99 {p99:.6f}")
    if Path(args.path).stem != "coda_resolution":
        ratio = fs4 / f4 if f4 > 0 else (float("inf") if fs4 > 0 else 0.0)
        if ratio > 0.05:
            violations.append(f"F#4/F4 {ratio:.4f} > 0.05")
    if args.expect_seconds is not None:
        duration = x.size / RATE
        # Compare sample counts: the float difference is 0.010000000000005
        # at exactly 0.01 s, which would fail a "> 0.01" test on the boundary.
        delta_samples = abs(x.size - round(args.expect_seconds * RATE))
        delta = delta_samples / RATE
        if delta_samples > round(0.01 * RATE):
            violations.append(f"duration {duration:.3f} s differs from "
                              f"{args.expect_seconds:.3f} s by {delta:.3f} s > 0.01")
    for violation in violations:
        print(f"strict violation {violation}")
    if violations:
        sys.exit(1)
    print("strict          ok")


if __name__ == "__main__":
    main()
