#!/usr/bin/env python3
"""Render one voice of an SFZ patch to a 48 kHz stereo float WAV.

A small SFZ player covering what the cambridge_rain patches use: default
sample paths, global/master/group/region inheritance, key and velocity
ranges, round robin (always take round 1), pitch by resampling, region
volume, sample offset and a plain attack/sustain/release envelope. Regions
that need a sustain pedal or are release-triggered are skipped.

Usage:
  uv run --with numpy --with soundfile python tools/music/sfz_render.py \
      <patch.sfz> <part.mid> <out.wav>
"""
import os
import re
import struct
import sys

import numpy as np
import soundfile as sf

RATE = 48000
MIN_RELEASE_S = 0.25  # keep string note tails overlapping slightly
SUPPORTED = {
    "default_path", "lokey", "hikey", "key", "lovel", "hivel", "sample",
    "pitch_keycenter", "tune", "volume", "offset", "pitch_keytrack",
    "seq_length", "seq_position", "trigger", "on_locc64", "on_hicc64",
    "ampeg_attack", "ampeg_release", "amp_veltrack", "ampeg_dynamic",
}
NOTE_PITCH = {"c": 0, "d": 2, "e": 4, "f": 5, "g": 7, "a": 9, "b": 11}


def parse_sfz(path: str) -> tuple[dict, list[dict], set[str]]:
    sections = []
    kind = None
    ops = {}
    for line in open(path, encoding="utf-8", errors="replace"):
        line = line.split("//")[0].strip()
        if not line:
            continue
        if line.startswith("<"):
            if kind is not None:
                sections.append((kind, ops))
            kind = line.strip().strip("<>").lower()
            ops = {}
            continue
        match = re.match(r"([A-Za-z_0-9]+)\s*=\s*(.*)$", line)
        if match and kind is not None:
            ops[match.group(1).lower()] = match.group(2).strip()
    if kind is not None:
        sections.append((kind, ops))

    control = {}
    global_ops = {}
    master: dict = {}
    group: dict = {}
    regions = []
    seen = set()
    for kind, ops in sections:
        seen.update(ops)
        if kind == "control":
            control.update(ops)
        elif kind == "global":
            global_ops.update(ops)
            master = dict(global_ops)
            group = dict(master)
        elif kind == "master":
            master = dict(global_ops)
            master.update(ops)
            group = dict(master)
        elif kind == "group":
            group = dict(master)
            group.update(ops)
        elif kind == "region":
            region = dict(group)
            region.update(ops)
            regions.append(region)
    return control, regions, seen - SUPPORTED


def number(value: str) -> float:
    try:
        return float(value)
    except ValueError:
        pass
    match = re.fullmatch(r"([A-Ga-g])([#b]?)(-?\d+)", value.strip())
    if not match:
        raise ValueError(f"not a note or number: {value}")
    pitch = NOTE_PITCH[match.group(1).lower()]
    if match.group(2) == "#":
        pitch += 1
    elif match.group(2) == "b":
        pitch -= 1
    return 12 * (int(match.group(3)) + 1) + pitch


def read_var(data: bytes, pos: int) -> tuple[int, int]:
    value = 0
    while True:
        byte = data[pos]
        pos += 1
        value = (value << 7) | (byte & 0x7F)
        if not byte & 0x80:
            return value, pos


def read_midi(path: str) -> list[tuple[float, float, int, int]]:
    """Return (start_s, gate_s, note, velocity) for every note in the file."""
    data = open(path, "rb").read()
    assert data[:4] == b"MThd", path
    header_len = struct.unpack(">I", data[4:8])[0]
    _fmt, track_count, division = struct.unpack(">HHH", data[8:14])
    pos = 8 + header_len
    raw = []
    tempo_events = []
    for _ in range(track_count):
        assert data[pos:pos + 4] == b"MTrk", path
        length = struct.unpack(">I", data[pos + 4:pos + 8])[0]
        body = data[pos + 8:pos + 8 + length]
        pos += 8 + length
        tick = 0
        index = 0
        running = 0
        active = {}
        while index < len(body):
            delta, index = read_var(body, index)
            tick += delta
            status = body[index]
            if status & 0x80:
                index += 1
                running = status
            else:
                status = running
            if status == 0xFF:
                meta = body[index]
                size, index = read_var(body, index + 1)
                payload = body[index:index + size]
                index += size
                if meta == 0x51:
                    tempo_events.append((tick, int.from_bytes(payload, "big")))
                continue
            if status in (0xF0, 0xF7):
                size, index = read_var(body, index)
                index += size
                continue
            kind = status & 0xF0
            if kind in (0xC0, 0xD0):  # program change / channel pressure
                index += 1
                continue
            note = body[index]
            velocity = body[index + 1]
            index += 2
            if kind == 0x90 and velocity > 0:
                active[note] = (tick, velocity)
            elif kind in (0x80, 0x90) and note in active:
                start_tick, on_velocity = active.pop(note)
                raw.append((start_tick, tick, note, on_velocity))
    tempo_events.sort()
    notes = []
    for start_tick, end_tick, note, velocity in raw:
        start = tick_seconds(start_tick, tempo_events, division)
        notes.append((start, tick_seconds(end_tick, tempo_events, division) - start, note, velocity))
    return notes


def tick_seconds(tick: int, tempo_events: list[tuple[int, int]], division: int) -> float:
    seconds = 0.0
    last_tick = 0
    tempo = 500000
    for at, value in tempo_events:
        if at > tick:
            break
        seconds += (at - last_tick) * tempo / (division * 1_000_000)
        last_tick = at
        tempo = value
    return seconds + (tick - last_tick) * tempo / (division * 1_000_000)


def sample_path(region: dict, control: dict, sfz_dir: str) -> str:
    sample = region["sample"].replace("\\", "/")
    default = region.get("default_path", control.get("default_path", "")).replace("\\", "/")
    if os.path.isabs(sample):
        return sample
    return os.path.normpath(os.path.join(sfz_dir, default, sample))


def load_sample(path: str, cache: dict) -> tuple[np.ndarray, int]:
    if path not in cache:
        data, rate = sf.read(path, dtype="float64", always_2d=True)
        if data.shape[1] == 1:
            data = np.repeat(data, 2, axis=1)
        cache[path] = (data[:, :2], rate)
    return cache[path]


def plan(note: int, velocity: int, regions: list[dict]) -> list[dict]:
    matched = []
    for region in regions:
        if region.get("trigger", "attack") != "attack":
            continue
        if "on_locc64" in region or "on_hicc64" in region:
            continue
        key = number(region["key"]) if "key" in region else None
        lokey = number(region["lokey"]) if "lokey" in region else (key if key is not None else 0)
        hikey = number(region["hikey"]) if "hikey" in region else (key if key is not None else 127)
        lovel = number(region["lovel"]) if "lovel" in region else 0
        hivel = number(region["hivel"]) if "hivel" in region else 127
        if not (lokey <= note <= hikey and lovel <= velocity <= hivel):
            continue
        if number(region.get("seq_length", "1")) > 1 and number(region.get("seq_position", "1")) != 1:
            continue
        matched.append(region)
    return matched


def render_note(region: dict, note: int, velocity: int, gate: float,
                control: dict, sfz_dir: str, cache: dict) -> np.ndarray:
    path = sample_path(region, control, sfz_dir)
    data, sample_rate = load_sample(path, cache)
    keycenter = number(region.get("pitch_keycenter", region.get("key", "60")))
    keytrack = number(region.get("pitch_keytrack", "100"))
    tune = number(region.get("tune", "0"))
    semitones = (note - keycenter) * keytrack / 100.0 + tune / 100.0
    ratio = 2.0 ** (semitones / 12.0) * sample_rate / RATE

    offset = int(number(region.get("offset", "0")))
    available = data.shape[0] - offset
    if available <= 1:
        return np.empty((0, 2))
    attack = max(0.0, number(region.get("ampeg_attack", "0.001")))
    release = max(MIN_RELEASE_S, number(region.get("ampeg_release", "0.3")))
    frames = min(int(available / ratio), int(round((gate + release) * RATE)))
    if frames <= 0:
        return np.empty((0, 2))

    position = offset + np.arange(frames) * ratio
    low = np.floor(position).astype(np.int64)
    frac = (position - low)[:, None]
    high = np.minimum(low + 1, data.shape[0] - 1)
    rendered = data[low] * (1.0 - frac) + data[high] * frac

    t = np.arange(frames) / RATE
    env = np.ones(frames)
    if attack > 0.0:
        env *= np.minimum(1.0, t / attack)
    after = t > gate
    env[after] *= np.maximum(0.0, 1.0 - (t[after] - gate) / release)

    veltrack = number(region.get("amp_veltrack", "100"))
    velocity_gain = (velocity / 127.0) ** 2
    gain = velocity_gain ** (veltrack / 100.0) * 10.0 ** (number(region.get("volume", "0")) / 20.0)
    return rendered * env[:, None] * gain


def main() -> None:
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    sfz_path, midi_path, out_path = sys.argv[1:]
    sfz_dir = os.path.dirname(os.path.abspath(sfz_path))
    control, regions, unsupported = parse_sfz(sfz_path)
    if unsupported:
        print(f"warning: ignoring opcodes: {', '.join(sorted(unsupported))}")

    notes = read_midi(midi_path)
    cache: dict = {}
    plans = []
    total = 0
    for start, gate, note, velocity in notes:
        for region in plan(note, velocity, regions):
            rendered = render_note(region, note, velocity, gate, control, sfz_dir, cache)
            begin = int(round(start * RATE))
            plans.append((begin, rendered))
            total = max(total, begin + rendered.shape[0])

    out = np.zeros((total, 2))
    for begin, rendered in plans:
        out[begin:begin + rendered.shape[0]] += rendered
    sf.write(out_path, out.astype(np.float32), RATE, subtype="FLOAT")
    print(f"{len(notes)} notes, {len(plans)} regions rendered, {total / RATE:.3f} s -> {out_path}")


if __name__ == "__main__":
    main()
