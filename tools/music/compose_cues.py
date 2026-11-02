#!/usr/bin/env python3
"""Write the one-shot cues `departure_motif` and `coda_resolution` as MIDI.

Same conventions as compose_cambridge.py (60 bpm, 4/4, one beat = 1 s) and
the same writer. These cues do not loop: the renderer keeps the release
tails after the last note instead of folding them.

- departure_motif: the cello states A-D-E-F once over an open harmonium
  fifth; F stays open. About 9 s of notes.
- coda_resolution: the violin answers A-D-E-F#, and the whole group lands
  on D major at the F#. This is the only cue where F# may sound.

Usage: python3 tools/music/compose_cues.py <outdir>
       writes <cue>_<voice>.mid for every voice the cue uses.
"""
import sys

import compose_cambridge as cc

DEPARTURE_BARS = 3
DEPARTURE = [
    ("harmonium", 1, 1, 8, "D3", 28),
    ("harmonium", 1, 1, 8, "A3", 26),
    ("cello", 1, 1, 2, "A2", 48),
    ("cello", 1, 3, 2, "D3", 52),
    ("cello", 2, 1, 2, "E3", 55),
    ("cello", 2, 3, 3, "F3", 46),
]

CODA_BARS = 4
CODA = [
    # Bars 1-2: the answer, over an open fifth that could still go either way.
    ("harmonium", 1, 1, 6, "D3", 26),
    ("harmonium", 1, 1, 6, "A3", 26),
    ("cello", 1, 1, 13, "D3", 40),
    ("violin", 1, 1, 2, "A4", 42),
    ("violin", 1, 3, 2, "D5", 46),
    ("violin", 2, 1, 2, "E5", 50),
    # Bar 2 beat 3: F# arrives and everyone settles on D major, held 7 s.
    ("violin", 2, 3, 7, "F#5", 46),
    ("viola", 2, 3, 7, "A3", 40),
    ("harmonium", 2, 3, 7, "D3", 30),
    ("harmonium", 2, 3, 7, "A3", 28),
    ("harmonium", 2, 3, 7, "D4", 28),
    ("harmonium", 2, 3, 7, "F#4", 30),
    # A last, quiet colour on the piano once the chord has bloomed.
    ("piano", 3, 2, 5, "D5", 26),
    ("piano", 3, 2.12, 5, "F#5", 24),
    ("piano", 3, 2.24, 5, "A5", 24),
]

CUES = {
    "departure_motif": (DEPARTURE, DEPARTURE_BARS),
    "coda_resolution": (CODA, CODA_BARS),
}


def main(outdir: str) -> None:
    assert all("#" not in note[4] for note in DEPARTURE)
    for cue, (score, bars) in CUES.items():
        for voice in sorted({part[0] for part in score}):
            with open(f"{outdir}/{cue}_{voice}.mid", "wb") as f:
                f.write(cc.build(voice, score, bars))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
