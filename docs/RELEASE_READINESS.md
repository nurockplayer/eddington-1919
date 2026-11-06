# Steam release readiness (edd-director)

The heartbeat question (Owner 2026-11-03 07:5x JST): **is the game at production release, ready for Steam?** Verdict 2026-11-03 08:0x JST: **no.** Source: a read-only Codex gpt-6-astra audit of `bf7edab` (2026-11-03 07:56 JST), triaged by the director. Update a row when its PR merges; the heartbeat starts the top open row that is not Owner-reserved.

Status: DONE / PARTIAL / MISSING. Owner = needs the Owner's decision, account or money; the director never does these alone.

## A. Director-actionable blockers (in this order)

| # | Item | Status | Evidence | Next action |
|---|---|---|---|---|
| A1 | Human Generator assets cannot ship | DONE (macOS + Windows) | #113 presets exclude `assets/licensed/*`; #121 parses the exported 0.3.0 macOS PCK; [PR #129](https://github.com/nurockplayer/eddington-1919/pull/129): Windows 0.3.0 ZIP + separate PCK check passed 2026-11-04 00:38 JST, notices/OFL present and no `assets/licensed/` or `tests/` paths | repeat for Linux if B2 picks it |
| A2 | Bundled CJK font | DONE | [PR #114](https://github.com/nurockplayer/eddington-1919/pull/114): `scripts/fonts.gd` adds bundled Noto Sans TC Regular after system names; OFL and hashes recorded; `tests/test_fonts.gd` checks every non-ASCII script character | — |
| A3 | Credits screen | DONE | Title and ending menus open the shared scrollable credits; `scripts/credits.gd` supplies version, production, shared historical disclaimer and notices; `tests/test_credits.gd` drives both menus | Owner name pending in B8: change `Credits.AUTHOR` |
| A4 | Licence notices complete and consistent | DONE | Credits expose `Notices.text()`, Godot’s engine licence, all bundled component copyrights and licence texts with BBCode escaping; notice/font export filters from [PR #116](https://github.com/nurockplayer/eddington-1919/pull/116) retained | A11: qualify the exported package and its reachable credits/notices |
| A5 | Settings: per-bus volume, fullscreen/window | DONE (lead windowed check 2026-11-03 09:4x JST: F11 windowed 0 → fullscreen 3 → windowed 0, borderless off) | [PR #115](https://github.com/nurockplayer/eddington-1919/pull/115): pause-menu master/music/SFX sliders + fullscreen button and F11; non-music players use SFX | saved in `user://settings.cfg`; music on/off preserved; headless window calls skipped; `tests/test_settings.gd` |
| A6 | Gamepad + Steam Deck navigation | DONE (phase 1) | Shared Xbox-layout bindings, analog look, dialogue choice focus, title/pause/ending/credits and Cambridge/darkroom panel focus; device-aware text prompts; `tests/test_gamepad.gd` | B10/A11: physical controller and Steam Deck packaged-build playtest; autoplay remains keyboard/mouse |
| A7 | Text size option | DONE | Pause-menu 「文字大小：小／標準／大」 (0.85/1.0/1.2), saved as `ui/text_scale`; theme and explicit 2D text refresh live; 3D labels unchanged | `tests/test_text_size.gd`: save/load, gamepad A, live scale/revert and 1280×720 choices |
| A8 | Placeholder text on the player path | PARTIAL | the only hit is `scripts/ui.gd:771` 「姓名暫定」 (fictional names provisional) → Owner decision B11 | when B11 is decided, drop 「（姓名暫定）」 and add a grep gate test |
| A9 | App icon, version from one place, release export script | DONE | [PR #117](https://github.com/nurockplayer/eddington-1919/pull/117): original `icon.svg`, Godot-rendered macOS PNG, `config/version="0.3.0"` with preset/title checks, `tools/export_release.sh` checks ZIP and PCK contents | A11: run the release export and qualify the packaged app; export intentionally not run for A9 |
| A10 | Every ending reached in tests | DONE | the 1919 endings are reached by autoplay careful/rushed/cherry + prologue honest; tidy/accuse stop at PREP by contract. Their choices only set `Story.bond_tone`/`kit_choice`, which reach 1919 through the same calls the honest route already runs (main.gd ~817/858/952); every tone variant of those lines is checked in test_departure (principe_workbook close/warm) and test_coda (kit_close close/warm/misread) — lead judgement 2026-11-03 14:2x JST | none |
| A11 | Exported-build qualification | PARTIAL | macOS 0.3.0 export + package check pass (#121); exported .app launched 2026-11-03 12:25 JST, 25 s, no crash, empty release log; no screenshot (capture unavailable); 0.4.0 macOS + Windows export + package check pass (2026-11-04 JST); builds on KIOXIA builds/0.4.0; 0.4.1 macOS + Windows + Linux export + package check pass (2026-11-04 JST); builds on KIOXIA builds/0.4.1; 0.4.2 macOS + Windows + Linux export + package check pass (2026-11-05 JST); builds on KIOXIA builds/0.4.2 (supersedes 0.4.1); 0.4.3 macOS + Windows + Linux export + package check pass (2026-11-05 JST); builds on KIOXIA builds/0.4.3 (supersedes 0.4.2); 0.4.4 macOS + Windows + Linux export + package check pass (2026-11-05 JST); builds on KIOXIA builds/0.4.4 (supersedes 0.4.3); 0.4.5 macOS + Windows + Linux export + package check pass (2026-11-06 JST); builds on KIOXIA builds/0.4.5 (supersedes 0.4.4) | a human plays the exported build start → credits → B10 (bots are not in the release pack) |
| A12 | Low-end performance budget | DONE (targets; on-hardware check in A11) | Owner 2026-11-04 00:3x JST: baseline = most common Steam hardware. `docs/SYSTEM_REQUIREMENTS.md` (Steam survey Oct 2026): recommended RTX 4060 / 16 GB / 1080p 標準 60 fps; minimum GTX 1050 Ti–1650 class / 8 GB / 720p 低 30 fps. Dev-Mac benchmark (#127/#128) estimates ≥ 2.5× margin; VRAM ≤ 368 MB | confirm on a Windows machine during the A11 playtest; use the table for the Steam page (B5) |
| A13 | Windows x86_64 preset | DONE | [PR #129](https://github.com/nurockplayer/eddington-1919/pull/129): Windows Desktop x86_64, separate PCK, six-size ICO, platform-specific version checks (45 checks, 0 failures); real 0.3.0 Windows ZIP export + pack check passed 2026-11-04 00:38 JST | A11/B10: human Windows packaged-build playtest; unsigned export, rcedit unset |

| A14 | Linux x86_64 preset (Steam Deck readiness) | DONE | Linux x86_64 preset and 0.4.0 ZIP export + separate PCK check passed with this PR; Linux ZIP now ships `Eddington1919.x86_64` + `Eddington1919.pck` (PR #167) | B2 decides whether Linux/Deck ships; Deck playtest in B10 |

## B. Owner-reserved (decide once; nothing here blocks A)

| # | Decision | Notes |
|---|---|---|
| B1 | Steamworks account, App ID, fee, tax/banking | Valve onboarding |
| B2 | Platforms: macOS / Windows / Linux-Deck | Windows is most of Steam; Deck needs A6 |
| B3 | Languages: zh-TW only, or English too | strings are hard-coded in `.gd`; English = extraction + translation project |
| B4 | Price or free, release date | |
| B5 | Store page: capsules, screenshots, trailer, description | director can draft from in-game stills; draft: docs/store/STORE_PAGE.md (PR #135) |
| B6 | Content survey + AI disclosure | generated portraits (`art/people/LICENSES.md:26`), sampled music |
| B7 | Save/continue: chapter select enough, or checkpoints? | one automatic checkpoint per chapter and a title 繼續 button (#250; lead decision 2026-11-07 JST under the Owner's 2026-11-06 mandate, since quitting otherwise lost the whole run). No slots or mid-chapter saves; the Owner can still change this |
| B8 | Names in credits; territory rights for recorded music | |
| B9 | Steam features: achievements, cloud saves (optional) | GodotSteam not present |
| B10 | Human playtest of the current build | PLAYTEST.md: human playtest still absent |
| B11 | Final names for the fictional characters (you, Kit, Ashby) | title screen says 「姓名暫定」 |

## C. Not blockers
Pause/quit/main menu (DONE, `scripts/ui.gd:741,857`); debug UI (export excludes tests/lookdev; verify in A11).
