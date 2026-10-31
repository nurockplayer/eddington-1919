#!/usr/bin/env python3
"""Report objective numbers for a rendered cue (OGG or WAV). Report only.

Prints duration, peak, RMS, the loop-seam step against the 99th-percentile
step inside the file, the fraction of 50 ms frames that are near-silent, the
strength of the 1.9 kHz band (score.gd suppresses the metronome band) and
F#4 against F4 (F-sharp is coda-only and must not appear in this cue).

Usage: uv run --with numpy python tools/music/check_cue.py <cue.ogg|cue.wav>
Always exits 0; read the numbers.
"""
import subprocess
import sys

import numpy as np

RATE = 48000
FRAME_S = 0.05
SILENT_RMS = 0.005


def decode(path: str) -> np.ndarray:
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"],
        check=True, capture_output=True,
    ).stdout
    return np.frombuffer(raw, dtype="<f4").astype(np.float64)


def goertzel_amplitude(x: np.ndarray, frequency: float) -> float:
    n = np.arange(x.size)
    return 2.0 * abs(np.dot(x, np.exp(-2j * np.pi * frequency * n / RATE))) / x.size


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    x = decode(sys.argv[1])
    if x.size < 2:
        print("empty audio")
        return
    peak = float(np.max(np.abs(x)))
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
    print(f"file            {sys.argv[1]}")
    print(f"duration        {x.size / RATE:.3f} s")
    print(f"peak            {peak:.4f}")
    print(f"rms             {rms:.4f}")
    print(f"seam |delta|    {seam:.6f}")
    print(f"p99 |delta|     {p99:.6f}   ({'seam <= p99' if seam <= p99 else 'SEAM EXCEEDS P99'})")
    print(f"near-silent      {near_silent * 100:.1f} % of 50 ms frames")
    print(f"1900 Hz amp/rms  {band / rms:.4f}" if rms > 0 else "1900 Hz amp/rms  n/a")
    print(f"F#4 amp          {fs4:.6f}")
    print(f"F4 amp           {f4:.6f}")
    print(f"F#4/F4           {fs4 / f4:.4f}" if f4 > 0 else "F#4/F4           n/a")


if __name__ == "__main__":
    main()
