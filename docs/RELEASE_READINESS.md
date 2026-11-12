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
| A8 | Placeholder text on the player path | DONE | [PR #253](https://github.com/nurockplayer/eddington-1919/pull/253): `scripts/credits.gd` drops 「（姓名暫定）」 from `Credits.DISCLAIMER` (the title screen and credits both show it), `tests/test_credits.gd` fails if `暫定` returns there, and `docs/store/STORE_PAGE.md` no longer calls the names provisional | none |
| A9 | App icon, version from one place, release export script | DONE | [PR #117](https://github.com/nurockplayer/eddington-1919/pull/117): original `icon.svg`, Godot-rendered macOS PNG, `config/version="0.3.0"` with preset/title checks, `tools/export_release.sh` checks ZIP and PCK contents | A11: run the release export and qualify the packaged app; export intentionally not run for A9 |
| A10 | Every ending reached in tests | DONE | the 1919 endings are reached by autoplay careful/rushed/cherry + prologue honest; tidy/accuse stop at PREP by contract. Their choices only set `Story.bond_tone`/`kit_choice`, which reach 1919 through the same calls the honest route already runs (main.gd ~817/858/952); every tone variant of those lines is checked in test_departure (principe_workbook close/warm) and test_coda (kit_close close/warm/misread) — lead judgement 2026-11-03 14:2x JST | none |
| A11 | Exported-build qualification | PARTIAL | macOS 0.3.0 export + package check pass (#121); exported .app launched 2026-11-03 12:25 JST, 25 s, no crash, empty release log; no screenshot (capture unavailable); 0.4.0 macOS + Windows export + package check pass (2026-11-04 JST); builds on KIOXIA builds/0.4.0; 0.4.1 macOS + Windows + Linux export + package check pass (2026-11-04 JST); builds on KIOXIA builds/0.4.1; 0.4.2 macOS + Windows + Linux export + package check pass (2026-11-05 JST); builds on KIOXIA builds/0.4.2 (supersedes 0.4.1); 0.4.3 macOS + Windows + Linux export + package check pass (2026-11-05 JST); builds on KIOXIA builds/0.4.3 (supersedes 0.4.2); 0.4.4 macOS + Windows + Linux export + package check pass (2026-11-05 JST); builds on KIOXIA builds/0.4.4 (supersedes 0.4.3); 0.4.5 macOS + Windows + Linux export + package check pass (2026-11-06 JST); builds on KIOXIA builds/0.4.5 (supersedes 0.4.4); [PR #255](https://github.com/nurockplayer/eddington-1919/pull/255) CI starts the exported package on Windows, macOS and Linux on software renderers (run 42326917643, 2026-11-07 11:03 JST: all jobs green, macOS 0 `ERROR:` lines). This shows launch only, not GPU behaviour or frame rate; 0.4.6 macOS + Windows + Linux export + package check pass (2026-11-09 JST); builds on KIOXIA builds/0.4.6 (supersedes 0.4.5); 0.4.7 macOS + Windows + Linux export + package check pass (2026-11-12 JST); builds on KIOXIA builds/0.4.7 (supersedes 0.4.6) | a human plays the exported build start → credits → B10 (bots are not in the release pack) |
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
| B5 | Store page: capsules, screenshots, trailer, description | PARTIAL (2026-11-12 JST); everything is in `docs/store/STORE_PAGE.md`. Drafted: short description, About and features in zh-TW, English, Japanese and Korean (sections 2–4). Staged for upload on KIOXIA `eddington/store-b5/upload/`: nine screenshots in four languages (#303, section 8) and the two-frame blink GIF for About in four languages (section 8); the plate screenshots and the GIF were reshot after the limb fix (#305) on 2026-11-12 JST. Drafted on KIOXIA 2026-11-12 JST: capsule set d2 from the 3840x2160 key-art frame (`store-b5/capsules-d2/`, section 8) and a 38.8 s rough cut of the trailer in English (Steam's base version), Japanese, Korean and zh-TW (`store-b5/trailer/careful_<language>_d3.mp4`, section 9). Open: the Owner accepts the title lettering, the key art and the trailer (nobody has heard its sound yet; asked in the dot thread 2026-11-12 10:5x JST); the upload itself needs the App ID (B1) |
| B6 | Content survey + AI disclosure | generated portraits (`art/people/LICENSES.md:26`), sampled music |
| B7 | Save/continue: chapter select enough, or checkpoints? | one automatic checkpoint per chapter and a title 繼續 button (#250; lead decision 2026-11-07 JST under the Owner's 2026-11-06 mandate, since quitting otherwise lost the whole run). No slots or mid-chapter saves; the Owner can still change this |
| B8 | Names in credits; territory rights for recorded music | |
| B9 | Steam features: achievements, cloud saves (optional) | GodotSteam not present |
| B10 | Human playtest of the current build | PLAYTEST.md: human playtest still absent |
| B11 | Final names for the fictional characters (you, Kit, Ashby) | decided: see section D; 「姓名暫定」 removed by #253 |

## D. Release plan (edd-lead, 2026-11-07 08:5x JST)

From two oracle-ego rounds plus a read of the Steamworks pages. The Owner's own calls are marked. Steam facts: US$100 per product, not refundable, recouped after US$1,000 revenue; paperwork 15–30 days; 21 days from fee to release; Coming Soon at least 2 weeks; store and build review 3–5 business days, plan 7; 5 screenshots at 1920x1080 minimum; a trailer is required for release (Trailers page, read 2026-11-12 JST; the 2026-11-07 note "no trailer requirement found" was a miss). Asset sizes and rules: `docs/store/STORE_PAGE.md` sections 8 and 9. Depots, Auto-Cloud settings, the notarization rule and the dated waits: `docs/store/STEAM_DEPOTS.md`.

| B row | Decision | Who |
|---|---|---|
| B1 | Steam Direct and paperwork: asked 2026-11-07 08:34 JST | Owner to do |
| B2 | Windows, macOS, Linux native depots. No Deck claim. The 2026-11-07 plan for macOS (check a real Steam install with `xattr` on the .app and a launch on a clean user, pay Apple only if that fails) is on hold. **Open since 2026-11-12 JST:** Valve's platforms page requires new macOS apps to be notarized, which needs the paid Apple Developer Program; options and the lead's recommendation in `docs/store/STEAM_DEPOTS.md` section 5. Until the Owner answers, the store page does not list macOS and no un-notarized macOS build goes to build review | lead; the Apple fee is the Owner's call |
| B3 | **zh-TW, English, Japanese, Korean, all at launch** | Owner 2026-11-07 |
| B4 | Rule: Coming Soon up 28 days or more, no launch in the Winter Sale, first Tuesday from 2027-01-12 that qualifies. US$2.99–3.99, picked after a measured playtime. State the length on the store page | proposal; Owner sets at publish |
| B5 | Capsules: in-game render plus typeset title, no generated art. Trailer 35–50 s from real capture with `--write-movie`; Steam requires one for release. Status: row B5 in section B | lead |
| B6 | Declare pre-generated AI content: portraits, story text, dialogue, localization, and music and sound (written as code, rendered from CC0 samples). Nothing live-generated. Text in `docs/store/STORE_PAGE.md` section 7 | Owner attests |
| B7 | Decided, see row B7 above | lead |
| B8 | **Gramophone recording stays** (Owner 2026-11-07). Credits: `nurockplayer` unless the Owner says otherwise. Steam's legal name is separate | Owner, lead |
| B9 | No achievements. Steam Auto-Cloud on `checkpoint.save` only, no SDK; settings in `docs/store/STEAM_DEPOTS.md` section 4 | lead |
| B10 | One blind newcomer session on any platform. Asked of the Owner 2026-11-07 08:34 JST; then Steam Playtest once an App ID exists. Not a gate for engineering work | Owner, then Playtest |
| B11 | Kit and Ashby keep their names; 「姓名暫定」 removed. The Owner can still change this | lead |

**Windows:** Owner 2026-11-07: if Mac and Linux are fine, Windows performance is not a concern. So CI checks that it launches; no performance proof is sought. Vulkan first, D3D12 fallback, no OpenGL fallback, no console wrapper. Shader baker stays off: Godot #122014 reports wrong baked shaders when a Mac host exports for Windows (reported by oracle, not reproduced here).

**Not adopted from oracle:** blind Windows session as a gate on everything; removing the gramophone; a separate alt-tab or high-DPI task (`canvas_items` stretch and Godot's capture handling already cover them; hand-check in a window).

**Work order:** release config → packaged-launch CI on Windows, macOS, Linux → i18n foundation (`L.t`, locale pick, JP and KR fonts) → wrap strings, extraction and gates → translate after Monday's text look, en then ja and ko → store assets, depot scripts once an App ID exists.

## C. Not blockers
Pause/quit/main menu (DONE, `scripts/ui.gd:741,857`); debug UI (export excludes tests/lookdev; verify in A11).
