#!/usr/bin/env python3
"""Mix the cambridge_rain stems into one seamless 64 s loop.

Each stem is folded onto the loop length (everything past the loop start is
added back at the top), gained and panned, then a deterministic small-room
reverb is applied as a circular convolution so the reverb tail wraps around
the loop seam too. The result is normalised to a fixed peak and written as a
16-bit stereo WAV for oggenc.

With `--oneshot` the cue does not loop: nothing is folded, the reverb is a
linear convolution whose tail rings past the last note, the mix is padded or
cut to `--seconds`, and the last `--fade` seconds get a raised-cosine fade so
the cut does not click. Peak normalisation is the same as for the loop.

Usage:
  uv run --with numpy python tools/music/mix.py --out mix.wav --seconds 64 \
      --stem harmonium harm.wav 0.8 0.0 --stem cello cello.wav 1.0 -0.2 ...
"""
import argparse
import subprocess
import sys
import wave

import numpy as np

RATE = 48000
RT60_S = 1.6
PREDELAY_S = 0.015
LPF_HZ = 5000.0
SEED = 1919


def decode(path: str) -> np.ndarray:
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"],
        check=True, capture_output=True,
    ).stdout
    return np.frombuffer(raw, dtype="<f4").astype(np.float64)


def fold(x: np.ndarray, count: int) -> np.ndarray:
    """Overlap-add everything past `count` samples onto the start."""
    if x.size <= count:
        return np.pad(x, (0, count - x.size))
    out = x[:count].copy()
    tail = x[count:]
    pos = 0
    while pos < tail.size:
        take = min(count, tail.size - pos)
        out[:take] += tail[pos:pos + take]
        pos += take
    return out


def fit(x: np.ndarray, count: int) -> np.ndarray:
    """Pad with silence or cut to exactly `count` samples."""
    if x.size >= count:
        return x[:count].copy()
    return np.pad(x, (0, count - x.size))


def make_ir(seed: int) -> np.ndarray:
    """Deterministic stereo small-room impulse response, RT60 1.6 s."""
    pre = int(PREDELAY_S * RATE)
    length = int(RT60_S * RATE)
    t = np.arange(length) / RATE
    decay = np.exp(-6.907755 * t / RT60_S)  # -60 dB at RT60
    freqs = np.fft.rfftfreq(pre + length, 1.0 / RATE)
    tilt = 1.0 / np.sqrt(1.0 + (freqs / LPF_HZ) ** 6.0)
    channels = []
    for channel in range(2):
        rng = np.random.default_rng(seed + channel)
        ir = np.zeros(pre + length)
        ir[pre:] = rng.standard_normal(length) * decay
        spectrum = np.fft.rfft(ir) * tilt
        ir = np.fft.irfft(spectrum, ir.size)
        ir /= np.sqrt(np.sum(ir * ir))
        channels.append(ir)
    return channels


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True)
    parser.add_argument("--seconds", type=float, default=64.0)
    parser.add_argument("--wet", type=float, default=0.25)
    parser.add_argument("--peak", type=float, default=0.5)
    parser.add_argument("--oneshot", action="store_true",
                        help="no folding, linear reverb tail, fade out instead")
    parser.add_argument("--fade", type=float, default=1.5,
                        help="raised-cosine fade over the last N s (--oneshot only)")
    parser.add_argument("--stem", nargs=4, action="append", metavar=("NAME", "PATH", "GAIN", "PAN"))
    args = parser.parse_args()
    if not args.stem:
        sys.exit("no stems")

    count = int(round(args.seconds * RATE))
    dry = np.zeros((2, count))
    cello_rms = None
    rms_by_stem = {}
    for name, path, gain, pan in args.stem:
        samples = decode(path)
        mono = (fit(samples, count) if args.oneshot else fold(samples, count)) * float(gain)
        angle = (float(pan) + 1.0) * np.pi / 4.0
        dry[0] += mono * np.cos(angle)
        dry[1] += mono * np.sin(angle)
        rms = float(np.sqrt(np.mean(mono * mono)))
        rms_by_stem[name] = rms
        if name == "cello":
            cello_rms = rms

    for name, rms in rms_by_stem.items():
        relative = 20.0 * np.log10(rms / cello_rms) if cello_rms else 0.0
        print(f"stem {name:10s} rms {rms:.4f}  vs cello {relative:+.1f} dB")

    irs = make_ir(SEED)
    dry_rms = float(np.sqrt(np.mean(dry * dry)))
    wet = np.zeros_like(dry)
    if args.oneshot:
        # Linear convolution: the tail rings out past the last note instead of
        # wrapping onto the top, then we keep just the cue length.
        nfft = 1 << (count + irs[0].size - 1).bit_length()
        for channel in range(2):
            wet[channel] = np.fft.irfft(
                np.fft.rfft(dry[channel], nfft) * np.fft.rfft(irs[channel], nfft),
                nfft)[:count]
    else:
        for channel in range(2):
            wet[channel] = np.fft.irfft(
                np.fft.rfft(dry[channel]) * np.fft.rfft(irs[channel], count), count)
    wet_rms = float(np.sqrt(np.mean(wet * wet)))
    if wet_rms > 0.0:
        wet *= args.wet * dry_rms / wet_rms
    mix = dry + wet

    if args.oneshot:
        mix = fit(mix, count)
        fade = int(round(min(args.fade, args.seconds) * RATE))
        if fade > 0:
            window = 0.5 * (1.0 + np.cos(np.pi * (np.arange(fade) + 0.5) / fade))
            mix[:, -fade:] *= window

    # check_cue.py decodes with `ffmpeg -ac 1`, whose downmix is (L+R)/sqrt(2),
    # so the target peak has to hold for that downmix as well as per channel.
    peak = max(float(np.max(np.abs(mix))),
               float(np.max(np.abs((mix[0] + mix[1]) / np.sqrt(2.0)))))
    if peak > 0.0:
        mix *= args.peak / peak
    print(f"dry rms {dry_rms:.4f}  wet rms {wet_rms:.4f}  peak {peak:.4f} -> {args.peak}")

    pcm = np.clip(mix.T, -1.0, 1.0)
    frames = (pcm * 32767.0).round().astype("<i2").tobytes()
    with wave.open(args.out, "wb") as out:
        out.setnchannels(2)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(frames)


if __name__ == "__main__":
    main()
