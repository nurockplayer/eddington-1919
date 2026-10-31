#!/usr/bin/env python3
"""Offline port of the harmonium reed voice in scripts/audio/score.gd.

The harmonium is not sampled: this renders the MIDI notes of
`cambridge_harmonium.mid` with the same additive reed table, envelope and
bellows movement the game synthesises at run time.

Usage: uv run --with numpy python tools/music/reed.py <in.mid> <out.wav>
Writes a mono 48 kHz 32-bit float WAV.
"""
import struct
import sys

import numpy as np

RATE = 48000
TABLE_SIZE = 4096
CUTOFF_HZ = 700.0
ATTACK_S = 0.72   # _add_chord / _add_reed call sites in score.gd
RELEASE_S = 1.2
MIN_SECONDS = 64.0


def read_var(data: bytes, pos: int) -> tuple[int, int]:
    value = 0
    while True:
        byte = data[pos]
        pos += 1
        value = (value << 7) | (byte & 0x7F)
        if not byte & 0x80:
            return value, pos


def read_midi(path: str) -> list[tuple[float, float, int]]:
    """Return (start_s, gate_s, midi_note) for every note, plus tempo changes."""
    data = open(path, "rb").read()
    assert data[:4] == b"MThd", path
    header_len = struct.unpack(">I", data[4:8])[0]
    _fmt, track_count, division = struct.unpack(">HHH", data[8:14])
    pos = 8 + header_len
    default_tempo = 500000
    tempo = default_tempo
    seconds_at = {}  # tick -> seconds, rebuilt while walking the first track
    tempo_events = []
    raw_notes = []  # (tick, note, on/off)
    for _ in range(track_count):
        assert data[pos:pos + 4] == b"MTrk", path
        length = struct.unpack(">I", data[pos + 4:pos + 8])[0]
        body = data[pos + 8:pos + 8 + length]
        pos += 8 + length
        tick = 0
        i = 0
        running = 0
        active = {}
        while i < len(body):
            delta, i = read_var(body, i)
            tick += delta
            status = body[i]
            if status & 0x80:
                i += 1
                running = status
            else:
                status = running
            kind = status & 0xF0
            if status == 0xFF:
                meta = body[i]
                size, i = read_var(body, i + 1)
                payload = body[i:i + size]
                i += size
                if meta == 0x51:
                    tempo = int.from_bytes(payload, "big")
                    tempo_events.append((tick, tempo))
                continue
            if status in (0xF0, 0xF7):
                size, i = read_var(body, i)
                i += size
                continue
            if kind in (0xC0, 0xD0):  # program change / channel pressure
                i += 1
                continue
            note = body[i]
            velocity = body[i + 1]
            i += 2
            if kind == 0x90 and velocity > 0:
                active[note] = tick
            elif kind in (0x80, 0x90):
                if note in active:
                    raw_notes.append((active.pop(note), tick, note))
    tempo_events.sort()
    notes = []
    for start_tick, end_tick, note in raw_notes:
        notes.append((tick_seconds(start_tick, tempo_events, division),
                      tick_seconds(end_tick, tempo_events, division)
                      - tick_seconds(start_tick, tempo_events, division), note))
    return notes, seconds_at


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
    seconds += (tick - last_tick) * tempo / (division * 1_000_000)
    return seconds


def note_hz(note: int) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def reed_table(frequency: float) -> np.ndarray:
    """_reed_table from score.gd: seven partials, soft three-pole low-pass."""
    phase = 2.0 * np.pi * np.arange(TABLE_SIZE) / TABLE_SIZE
    value = np.zeros(TABLE_SIZE)
    normalization = 0.0
    for partial in range(1, 8):
        lp = 1.0 / np.sqrt(1.0 + (frequency * partial / CUTOFF_HZ) ** 6.0)
        weight = (1.15 if partial == 2 else 1.0) * lp / partial
        value += np.sin(phase * partial) * weight
        normalization += abs(weight)
    return value / max(normalization, 1.0)


def s_curve(value: np.ndarray) -> np.ndarray:
    x = np.clip(value, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)


def envelope(t: np.ndarray, gate: float, attack: float, release: float) -> np.ndarray:
    env = s_curve(t / attack) if attack > 0.0 else np.ones_like(t)
    after = t > gate
    x = np.clip((t - gate) / release, 0.0, 1.0)
    env = np.where(after, env * (1.0 - s_curve(x)), env)
    return np.where((t < 0.0) | (t >= gate + release), 0.0, env)


def add_reed(out: np.ndarray, start: float, gate: float, note: int, attack: float, release: float) -> None:
    """_add_reed from score.gd, including the +/-1.5 dB 0.15 Hz bellows."""
    frequency = note_hz(note)
    table = reed_table(frequency)
    begin = max(0, int(np.floor(start * RATE)))
    end = min(out.size, int(np.ceil((start + gate + release) * RATE)))
    if end <= begin:
        return
    abs_index = np.arange(begin, end)
    t = abs_index / RATE - start
    env = envelope(t, gate, attack, release)
    phase_step = frequency * TABLE_SIZE / RATE
    phase = np.mod(np.arange(end - begin) * phase_step, TABLE_SIZE)
    idx = phase.astype(np.int64) & (TABLE_SIZE - 1)
    frac = phase - np.floor(phase)
    sample = table[idx] * (1.0 - frac) + table[(idx + 1) & (TABLE_SIZE - 1)] * frac
    bellows = 10.0 ** ((1.5 * np.sin(2.0 * np.pi * 0.15 * abs_index / RATE)) / 20.0)
    out[begin:end] += sample * env * bellows


def write_wav(path: str, samples: np.ndarray) -> None:
    data = samples.astype("<f4").tobytes()
    header = b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVE"
    header += b"fmt " + struct.pack("<IHHIIHH", 16, 3, 1, RATE, RATE * 4, 4, 32)
    header += b"data" + struct.pack("<I", len(data))
    with open(path, "wb") as f:
        f.write(header)
        f.write(data)


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    notes, _ = read_midi(sys.argv[1])
    total_s = max(MIN_SECONDS, max(start + gate + RELEASE_S for start, gate, _ in notes))
    out = np.zeros(int(np.ceil(total_s * RATE)))
    for start, gate, note in notes:
        add_reed(out, start, gate, note, ATTACK_S, RELEASE_S)
    write_wav(sys.argv[2], out)


if __name__ == "__main__":
    main()
