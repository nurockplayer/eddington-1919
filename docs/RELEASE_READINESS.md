# Steam release readiness (edd-director)

The heartbeat question (Owner 2026-11-03 07:5x JST): **is the game at production release, ready for Steam?** Verdict 2026-11-03 08:0x JST: **no.** Source: a read-only Codex gpt-6-astra audit of `bf7edab` (2026-11-03 07:56 JST), triaged by the director. Update a row when its PR merges; the heartbeat starts the top open row that is not Owner-reserved.

Status: DONE / PARTIAL / MISSING. Owner = needs the Owner's decision, account or money; the director never does these alone.

## A. Director-actionable blockers (in this order)

| # | Item | Status | Evidence | Next action |
|---|---|---|---|---|
| A1 | Human Generator assets cannot ship | PARTIAL | #113: export presets exclude `assets/licensed/*`; regression test checks each preset (oracle major: config only, not the package) | in A11, list the exported pck and assert no `assets/licensed/` or `tests/` file |
| A2 | Bundled CJK font | DONE | [PR #114](https://github.com/nurockplayer/eddington-1919/pull/114): `scripts/fonts.gd` adds bundled Noto Sans TC Regular after system names; OFL and hashes recorded; `tests/test_fonts.gd` checks every non-ASCII script character | — |
| A3 | Credits screen | MISSING | `scripts/ui.gd:792` ending menu has no credits | credits from `docs/PROVENANCE.md`, `docs/audio/SOURCES.md`, `art/people/LICENSES.md`, Godot notice |
| A4 | Licence notices complete and consistent | PARTIAL | `THIRD_PARTY_NOTICES.md` and the font licence are included in the export; `scripts/notices.gd` supplies the notice and Godot licence text for A3 | PR number pending; A3 must expose the notice and Godot’s bundled third-party copyright and licence information |
| A5 | Settings: per-bus volume, fullscreen/window | PARTIAL | `scripts/ui.gd:879` music on/off only | master/music/SFX sliders + fullscreen toggle, saved in `user://settings.cfg` |
| A6 | Gamepad + Steam Deck navigation | MISSING | `scripts/main.gd:205` keyboard/mouse actions only | joypad bindings for move/interact/dialogue/menus; UI focus navigation |
| A7 | Text size option | PARTIAL | fixed font sizes (`theme_res.default_font_size = 21`) | small/normal/large scale on the theme |
| A8 | Placeholder text on the player path | PARTIAL | `scripts/ui.gd:771` 「姓名暫定」 | resolve each placeholder; grep gate in a test |
| A9 | App icon, version from one place, release export script | PARTIAL | no icon; `short_version="0.1.0"` | icon (from existing art), `tools/export_release.sh` |
| A10 | Every ending reached in tests | PARTIAL | e2e `tidy`/`accuse` stop at PREP | extend routes to their endings |
| A11 | Exported-build qualification | PARTIAL | last export is v0.2 (`d3bb69d`) | export current main, play start → credits per platform, keep runtime/exit logs clean |
| A12 | Low-end performance budget | PARTIAL | `art/validation/perf-r04` M2 Pro only | set minimum spec + FPS target, measure (heavy job) |
| A13 | Windows x86_64 preset | MISSING | only a macOS preset | add preset + test (if the Owner picks Windows, B2) |

## B. Owner-reserved (decide once; nothing here blocks A)

| # | Decision | Notes |
|---|---|---|
| B1 | Steamworks account, App ID, fee, tax/banking | Valve onboarding |
| B2 | Platforms: macOS / Windows / Linux-Deck | Windows is most of Steam; Deck needs A6 |
| B3 | Languages: zh-TW only, or English too | strings are hard-coded in `.gd`; English = extraction + translation project |
| B4 | Price or free, release date | |
| B5 | Store page: capsules, screenshots, trailer, description | director can draft from in-game stills |
| B6 | Content survey + AI disclosure | generated portraits (`art/people/LICENSES.md:26`), sampled music |
| B7 | Save/continue: chapter select enough, or checkpoints? | today: two start chapters, story state in memory |
| B8 | Names in credits; territory rights for recorded music | |
| B9 | Steam features: achievements, cloud saves (optional) | GodotSteam not present |
| B10 | Human playtest of the current build | PLAYTEST.md: human playtest still absent |

## C. Not blockers
Pause/quit/main menu (DONE, `scripts/ui.gd:741,857`); debug UI (export excludes tests/lookdev; verify in A11).
