# Steam release readiness (edd-director)

The heartbeat question (Owner 2026-11-03 07:5x JST): **is the game at production release, ready for Steam?** Verdict 2026-11-03 08:0x JST: **no.** Source: a read-only Codex gpt-6-astra audit of `bf7edab` (2026-11-03 07:56 JST), triaged by the director. Update a row when its PR merges; the heartbeat starts the top open row that is not Owner-reserved.

Status: DONE / PARTIAL / MISSING. Owner = needs the Owner's decision, account or money; the director never does these alone.

## A. Director-actionable blockers (in this order)

| # | Item | Status | Evidence | Next action |
|---|---|---|---|---|
| A1 | Human Generator assets cannot ship | DONE (macOS) | #113 presets exclude `assets/licensed/*`; #121 `tools/export_release.sh` parses the exported 0.3.0 macOS PCK and fails on any `assets/licensed/` or `tests/` path — passed 2026-11-03 12:1x JST | repeat for the Windows/Linux packages once B2 picks platforms (A13) |
| A2 | Bundled CJK font | DONE | [PR #114](https://github.com/nurockplayer/eddington-1919/pull/114): `scripts/fonts.gd` adds bundled Noto Sans TC Regular after system names; OFL and hashes recorded; `tests/test_fonts.gd` checks every non-ASCII script character | — |
| A3 | Credits screen | DONE | Title and ending menus open the shared scrollable credits; `scripts/credits.gd` supplies version, production, shared historical disclaimer and notices; `tests/test_credits.gd` drives both menus | Owner name pending in B8: change `Credits.AUTHOR` |
| A4 | Licence notices complete and consistent | DONE | Credits expose `Notices.text()`, Godot’s engine licence, all bundled component copyrights and licence texts with BBCode escaping; notice/font export filters from [PR #116](https://github.com/nurockplayer/eddington-1919/pull/116) retained | A11: qualify the exported package and its reachable credits/notices |
| A5 | Settings: per-bus volume, fullscreen/window | DONE (lead windowed check 2026-11-03 09:4x JST: F11 windowed 0 → fullscreen 3 → windowed 0, borderless off) | [PR #115](https://github.com/nurockplayer/eddington-1919/pull/115): pause-menu master/music/SFX sliders + fullscreen button and F11; non-music players use SFX | saved in `user://settings.cfg`; music on/off preserved; headless window calls skipped; `tests/test_settings.gd` |
| A6 | Gamepad + Steam Deck navigation | DONE (phase 1) | Shared Xbox-layout bindings, analog look, dialogue choice focus, title/pause/ending/credits and Cambridge/darkroom panel focus; device-aware text prompts; `tests/test_gamepad.gd` | B10/A11: physical controller and Steam Deck packaged-build playtest; autoplay remains keyboard/mouse |
| A7 | Text size option | DONE | Pause-menu 「文字大小：小／標準／大」 (0.85/1.0/1.2), saved as `ui/text_scale`; theme and explicit 2D text refresh live; 3D labels unchanged | `tests/test_text_size.gd`: save/load, gamepad A, live scale/revert and 1280×720 choices |
| A8 | Placeholder text on the player path | PARTIAL | the only hit is `scripts/ui.gd:771` 「姓名暫定」 (fictional names provisional) → Owner decision B11 | when B11 is decided, drop 「（姓名暫定）」 and add a grep gate test |
| A9 | App icon, version from one place, release export script | DONE | [PR #117](https://github.com/nurockplayer/eddington-1919/pull/117): original `icon.svg`, Godot-rendered macOS PNG, `config/version="0.3.0"` with preset/title checks, `tools/export_release.sh` checks ZIP and PCK contents | A11: run the release export and qualify the packaged app; export intentionally not run for A9 |
| A10 | Every ending reached in tests | PARTIAL | the 1919 endings are reached by autoplay careful/rushed/cherry + prologue honest; `tidy`/`accuse` stop at PREP by contract (their prologue differences are checked at PREP); coda variants covered in test_coda | low priority: extend tidy/accuse to ENDING only if their bond/slip choices change a later line |
| A11 | Exported-build qualification | PARTIAL | macOS 0.3.0 export from main + package check pass (#121, 2026-11-03 12:1x JST); exported .app launched windowed 2026-11-03 12:25 JST, ran 25 s with no crash and an empty release log (no errors/warnings); screenshot unavailable, start → credits not yet played | export current main, play start → credits per platform, keep runtime/exit logs clean |
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
| B11 | Final names for the fictional characters (you, Kit, Ashby) | title screen says 「姓名暫定」 |

## C. Not blockers
Pause/quit/main menu (DONE, `scripts/ui.gd:741,857`); debug UI (export excludes tests/lookdev; verify in A11).
