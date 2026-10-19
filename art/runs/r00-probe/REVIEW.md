# r00 · tool probe (2026-10-19)

The first call to GPT image generation through Codex was made before the prompt library existed: a single free-form sentence (see `manifest.jsonl`).

- **Result:** a handsome painted image of a **domed observatory**. There is no evidence of a dome at Príncipe; the instruments were a coelostat feeding a horizontal tube under a shelter (`docs/PROVENANCE.md`).
- **Finding → rule:** unconstrained generators default to the cliché. Every historical negative must be spelled out → `avoid` in `prompts/series/base.toml` ("observatory domes", anachronisms) and BIBLE §8.
- **Timing:** 48 s for one image.
