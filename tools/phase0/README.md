# Phase-0 capture (#415)

From the worktree root:

```sh
tools/capture_phase0.py --commit b719020
```

The command submits `job-run -- tachi-run --heavy --host -- …` and prints a
`WAIT` line. The worker uses windowed Godot at fixed 60 fps, always on top,
and captures one revision at a time. It imports an archived revision first;
project import files, shader/runtime output and scratch frames stay on KIOXIA.
No gameplay, visuals, text, user settings or source checkout are changed.
Requires Godot, Python 3.12+, FFmpeg and ImageMagick already on the host.

Output is `/Volumes/KIOXIA/eddington-1919-cache/director/phase0/<full-sha>/run-NNN/`:

- 33 native stills: seven original benchmark views; arrival and totality sky at
  1080p/1440p; NPC at conversation distance, sign approach, roof underside;
  title/settings/pause; HUD/dialogue/plate inspection/results in en/ja/zh-TW/ko
  at the supported maximum text scale (1.2).
- Three full-size 720p 60 fps clips: a ten-second arrival walking loop followed
  by a six-second full turn; native second-contact transition; dialogue open
  and close. All begin 30 frames (0.5 s) before the trigger. Dialogue closes
  at frame 180. Every frame is rendered and saved before encoding; none is
  sampled away. Lossless scratch frames are deleted after encoding.
- `contact-sheet.jpg` navigates labelled stills; full-size PNGs remain.
- `manifest.json` binds source revision, driver/launcher hashes, camera matrices,
  states, seed, locale, resolution, UI scale, event frame/time, renderer, engine,
  commands and artifact hashes. `receipts.json` is the engine-side receipt.
- `execution.json` holds actual JST wall times outside the stable manifest.
  Simulation event seconds are relative to each trigger, with the first clip
  frame at -0.5 s. They are not wall-clock timestamps.

The seven census cameras are `tests/benchmark.gd BOOKMARKS[0:7]` (arrival,
shelter, coelostat, house, totality sky/horizon, darkroom). `look_shots.gd`
contains decoration close-ups rather than those seven; this driver extends it
and reuses its frame, UI hiding and PNG save helpers. Both sources remain intact.
Golden views use benchmark lighting and camera poses, with the same lens.

Every repeat retains a fresh run directory and compares manifests against all
completed runs for that SHA. Only hashes explicitly marked nondeterministic may
differ. Live GPU TIME/particles/temporal history are declared pixel variability;
metadata and engine receipts must match. `capture_id` is revision-based rather
than a wall-clock UUID. Run logs have explicit timing/path nondeterminism.

Coverage lists all scene resources and slice phases/UI states. `captured` means
evidence exists, not visual acceptance. States without evidence remain
`not_reviewed`, including Cambridge/departure/epilogue, rehearsal, coda,
help/log/credits/ending, dialogue choices and the plate viewer's alternate tools.
No coverage claim is inferred from another view or locale.
