# Music round 2 — a gramophone in the Cambridge room (Game Director spec, 2026-10-31)

Status: director's proposal (like the #37 loops), easy to remove. Decision context: [D014](../DECISIONS.md).

## Intent

The measuring room in October 1917 is quiet, rainy and waiting. One real record from the period lets the war be felt without a single line about the front. The player chooses to play it: it is never forced on them. It shares the room's theme of waiting for something that has not come yet.

## The recording (rights cleared 2026-10-31, oracle run `edd-gramophone-rights`)

- "Keep the Home-Fires Burning (Till the Boys Come Home)": Frederick J. Wheeler, baritone, with orchestra conducted by Walter B. Rogers. Victor 17881, matrix B-16626 take 3, recorded 1915-10-08 in Camden, NJ, first issued December 1915.
- Source: Library of Congress National Jukebox item 15093, https://data.labs.loc.gov/jukebox/audio/jukebox-15093_1.mp3 (published MD5 `d0df2e6378e5f61fea5a16ea59676a0b`).
- Rights: the sound recording is US public domain (published before 1923); music by Ivor Novello (d. 1951) and words by Lena Guilbert Ford (d. 1918) are UK/EU public domain since 2022; UK/EU recording rights have expired. Not CC0: record it in `docs/audio/SOURCES.md` under its own "Historical recording" section.
- A US Victor disc in Cambridge in 1917 assumes private import. The examine text says it came by post from an American colleague. No real person is named.
- Rejected: Peerless Quartet "Auld Lang Syne" (recorded 1918, issued 1921: after the scene).

## The asset

- `assets/audio/gramophone_home_fires_1915.ogg`: the transfer trimmed to one verse and the chorus (about 60–80 s), with a 0.3 s fade-in, a 2 s fade-out and a short needle-drop of the record's own surface noise. Mono, peak ≤ 0.5, `oggenc -q 4`. Nothing else is processed: the acoustic-era sound is the point.
- The trim times and commands live in `tools/music/prepare_gramophone.sh`, which downloads into the KIOXIA cache, checks the MD5, trims and encodes. The output SHA-256 is recorded in SOURCES.md.

## The prop and the interaction

- **Prop.** On a new small side table (about 0.5 × 0.7 × 0.5 m) against the east wall, between the shelf at z −1.35 and the fireplace at z +1.35; start at (3.95, 0, −0.25). A hornless table-top cabinet machine: a dark wood box about 0.42 × 0.20 × 0.42 m, a green-felt turntable, a brass tone arm, and a disc with a dark label. Build it procedurally in `star_decor.gd`, in the same style as the orrery, and give it its own `w.hotspot(..., "gramophone", "查看留聲機")` in `room_builder.gd` next to the orrery's. Place it on a wall-side surface clear of every existing hotspot and of the player's paths. The lead checks the spot in a windowed look.
- **Playing.**
  - Examining it shows the text below. On the last line the record starts: an `AudioStreamPlayer3D` at the prop on the **Master** bus. It is diegetic, so the music toggle does not mute it. Volume about −16 dB, unit size so it is clearly in the room, not in the ear.
  - While it plays the turntable spins at 78 rpm visually, and `cambridge_rain` ducks to silence over 1.5 s (`score.set_layer_db`) and returns over 3 s once the record ends.
  - Examining it again while it plays lifts the needle: the record stops, the score returns, and one short line shows.
  - After it ends it can be played again; the text is short the second time.
  - Leaving Cambridge (the montage) stops it with a 0.8 s fade.
- **No gameplay effect.** No clue, no flag the story reads, no bot dependence. The bots never examine it, so their cue logs are unchanged.

## Text (zh-Hant; fact-checked by Sonnet 2026-10-31, fixes applied)

```
"gramophone" (first time):
  {"s": "留聲機", "t": "一台桌上型留聲機。唱盤旁放著一張蟲膠唱片，黑色標籤上印著金字，是美國 Victor 公司的。\n信封還夾在一旁——一位美國同行隨信寄來的，說「給雨天的劍橋」。"}
  {"s": "留聲機", "t": "〈Keep the Home-Fires Burning〉。開戰頭幾個月寫的歌，到現在英國還有很多人在唱：把家裡的爐火燒著，等孩子們回家。"}
  {"s": "留聲機", "t": "[color=#b8ad98]你放下唱針。[/color]"}
"gramophone_again": {"s": "留聲機", "t": "[color=#b8ad98]你又放了一次。[/color]"}
"gramophone_stop":  {"s": "留聲機", "t": "[color=#b8ad98]你抬起唱針。房間裡又只剩下雨聲。[/color]"}
```

Fact check (Sonnet, 2026-10-31):
- Table-top hornless machines existed by 1917, and Victor and Gramophone Co. discs are both lateral-cut, so a Victor disc plays on a British machine. Do not name the machine's make.
- The disc is shellac. Victor 17881 has a black "batwing" label with gold print (1914–26).
- The song was first published 1914-10-08 as "'Till the Boys Come Home" and retitled "Keep the Home-Fires Burning" in 1915. It was widely recorded and sung in Britain through 1917. The lyricist, Ford, was American.
- Transatlantic post ran through 1917. Name no ship and no person.
- 「唱針」/「放下唱針」/「抬起唱針」 are natural for a steel-needle 78. "78 rpm" is nominal.

## Tests

- New `tests/test_gramophone.gd` drives the real flow through the director (examine `gramophone` → `_dialogue_done` → playback state), not helper-only checks:
  - The first examine starts playback, and `cambridge_rain` gets a `layer` entry at −80 dB with fade 1.5.
  - A second examine while playing stops it, and the score returns with fade 3.
  - After it finishes it can play again.
  - Leaving the scene stops it.
- Headless has no audio playback. As in `score_player.gd`, keep a `playing` state and a log the test can read.
- Revert check: with the hotspot removed, the room builds and the existing suites pass. The prologue bot routes stay unchanged (honest autoplay reaches ENDING; cue checks clean).
