# Style audition portraits: picks

Judged by the art director (edd-art) on 2026-11-16 17:5x JST from `sheet.jpg` and `sheet-small.jpg` (204 px, the size the dialogue shows).

- `eddington_poster`: **v1** → `assets/portraits/eddington_poster.jpg`. The shadow side of the face is one hard indigo shape; v2 keeps more likeness but its shadow breaks into small pieces.
- `eddington_engraving`: **v1** → `assets/portraits/eddington_engraving.jpg`. Its ruled background repeats the ruled sky of the engraving look; the lines hold at 204 px.

Both are redrawings of `assets/portraits/eddington_neutral.jpg` (an AI-generated reconstruction, not a historical photograph). Prompts, tool and hashes: `manifest.jsonl`. Used only by `--style=poster` and `--style=engraving` (scripts/styles/); the game without `--style` does not load them.
