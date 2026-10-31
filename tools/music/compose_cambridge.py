#!/usr/bin/env python3
"""Write the composed `cambridge_rain` cue as a Standard MIDI File.

The score is data in this file: no dependencies, deterministic output.
60 bpm in 4/4, so one beat is one second and one bar is four seconds.
16 bars = 64 s, a seamless loop (bars 15-16 leave room for release tails).

Rules kept from docs/design/M4_SCORE.md:
- The plate motif A-D-E-F is stated (cello, then violin) and F stays
  unresolved. F-sharp never appears here: it belongs to the coda only.
- D minor colour: Dm -> Gm/D -> C/D -> Am, with silences between.

Usage: python3 tools/music/compose_cambridge.py out.mid
"""
import struct
import sys

PPQ = 480
TEMPO_US = 1_000_000  # 60 bpm
BARS = 16

# Channel per voice. Programs are General MIDI numbers (0-based); the
# renderer may map channels to other instruments.
VOICES = {
    "harmonium": (0, 20),  # Reed Organ
    "cello": (1, 42),
    "viola": (2, 41),
    "violin": (3, 40),
    "piano": (4, 0),
}

NOTE_NAMES = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi_note(name: str) -> int:
    pitch = NOTE_NAMES[name[0]]
    rest = name[1:]
    if rest.startswith("#"):
        pitch += 1
        rest = rest[1:]
    elif rest.startswith("b"):
        pitch -= 1
        rest = rest[1:]
    return 12 * (int(rest) + 1) + pitch


# (voice, bar, beat, beats, note, velocity); bar and beat are 1-based.
SCORE = [
    # Bars 1-2: Dm on the harmonium alone, then rain.
    ("harmonium", 1, 1, 6, "D3", 40),
    ("harmonium", 1, 1, 6, "F3", 38),
    ("harmonium", 1, 1, 6, "A3", 38),
    # Bars 3-5: the cello states the motif over an open D pedal; F hangs.
    ("harmonium", 3, 1, 8, "D3", 30),
    ("harmonium", 3, 1, 8, "A3", 28),
    ("cello", 3, 1, 2, "A2", 50),
    ("cello", 3, 3, 2, "D3", 55),
    ("cello", 4, 1, 2, "E3", 58),
    ("cello", 4, 3, 4, "F3", 52),
    # Bar 6: a few piano drops, like the rain finding a tune.
    ("piano", 6, 1, 1, "D5", 35),
    ("piano", 6, 2.5, 1, "A4", 30),
    ("piano", 6, 4, 2, "F4", 28),
    # Bars 7-8: Gm/D, the violin's B-flat sighs down to A.
    ("harmonium", 7, 1, 8, "G3", 28),
    ("harmonium", 7, 1, 8, "Bb3", 26),
    ("cello", 7, 1, 8, "D3", 45),
    ("viola", 7, 1, 8, "G3", 42),
    ("violin", 7, 1, 3, "Bb4", 46),
    ("violin", 7, 4, 5, "A4", 42),
    # Bars 9-10: C/D, the violin falls G to E.
    ("harmonium", 9, 1, 8, "E3", 26),
    ("harmonium", 9, 1, 8, "G3", 26),
    ("cello", 9, 1, 8, "D3", 44),
    ("viola", 9, 1, 8, "C4", 40),
    ("violin", 9, 1, 4, "G4", 44),
    ("violin", 10, 1, 4, "E4", 40),
    # Bar 11: Am, a rolled piano chord over cello and viola.
    ("cello", 11, 1, 4, "A2", 42),
    ("viola", 11, 1, 4, "E3", 38),
    ("piano", 11, 1, 3, "C4", 30),
    ("piano", 11, 1.15, 3, "E4", 30),
    ("piano", 11, 1.3, 3, "A4", 32),
    # Bars 12-14: the violin repeats the motif an octave up; F5 is left open.
    ("harmonium", 12, 1, 8, "D3", 24),
    ("harmonium", 12, 1, 8, "A3", 24),
    ("cello", 12, 1, 8, "D3", 30),
    ("violin", 12, 1, 2, "A4", 40),
    ("violin", 12, 3, 2, "D5", 44),
    ("violin", 13, 1, 2, "E5", 46),
    ("violin", 13, 3, 4, "F5", 40),
    # Bars 15-16: silence; the rain bed carries the loop seam.
]


def var_len(value: int) -> bytes:
    out = [value & 0x7F]
    value >>= 7
    while value:
        out.append((value & 0x7F) | 0x80)
        value >>= 7
    return bytes(reversed(out))


def tick(bar: int, beat: float) -> int:
    return round(((bar - 1) * 4 + (beat - 1)) * PPQ)


def track(events: list[tuple[int, bytes]]) -> bytes:
    events.sort(key=lambda e: (e[0], e[1][0] & 0xF0 != 0x80))
    body = b""
    now = 0
    for at, data in events:
        body += var_len(at - now) + data
        now = at
    body += var_len(0) + b"\xff\x2f\x00"
    return b"MTrk" + struct.pack(">I", len(body)) + body


def build() -> bytes:
    meta = [
        (0, b"\xff\x51\x03" + TEMPO_US.to_bytes(3, "big")),
        (0, b"\xff\x58\x04\x04\x02\x18\x08"),
        (tick(BARS + 1, 1), b"\xff\x01\x04loop"),
    ]
    tracks = [track(meta)]
    for voice, (channel, program) in VOICES.items():
        events = [
            (0, bytes([0xFF, 0x03, len(voice)]) + voice.encode()),
            (0, bytes([0xC0 | channel, program])),
        ]
        for name, bar, beat, beats, note, velocity in SCORE:
            if name != voice:
                continue
            start = tick(bar, beat)
            end = start + round(beats * PPQ)
            assert end <= tick(BARS + 1, 1), (voice, bar, note)
            events.append((start, bytes([0x90 | channel, midi_note(note), velocity])))
            events.append((end, bytes([0x80 | channel, midi_note(note), 0])))
        tracks.append(track(events))
    header = b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks), PPQ)
    return header + b"".join(tracks)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    assert all(note[4] != "F#4" and "#" not in note[4] for note in SCORE)
    with open(sys.argv[1], "wb") as f:
        f.write(build())
