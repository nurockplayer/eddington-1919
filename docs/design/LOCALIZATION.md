# Localization (edd-lead, 2026-11-07 JST)

zh-TW is the source and the msgid. English, Japanese and Korean ship at launch (Owner 2026-11-07). The terms and register below come from oracle-ego (2026-11-07 09:09 JST), adjusted by the lead against the game's own props and the existing English store text. Translators follow this file. A term marked (check) has not been confirmed against a dictionary: flag a better one rather than guessing.

## Code rules

- `L.t("…")` for every player-facing string. A `const` cannot call a function, so translate it where it is used.
- **Whole sentences, not fragments.** A sentence built from parts gets rewritten as one msgid with placeholders. Example: the hold-interaction instruction used to be a fragment with a trailing-space contract; each site now picks a whole sentence on `Settings.hold_toggle`.
- `%` formats stay in the msgid, typed and ordered. A literal `%` in a formatted string is `%%`. Use a named `.format()` only when a translator must reorder and `%1$s` style is not available.
- Counts that need a plural in English go through a plural wrapper (`L.tn`). Chinese has no plural, so the source gives no signal: grep `%d 張` and similar.
- A zh string needing two different translations gets a context (`L.tc(s, ctx)`), added only when a collision is found.
- Speaker constants (`CAST.KIT`, `CAST.MENTOR`, …) stay as they are and act as ids, translated at display. Text formatted with one uses `% L.t(A)`.
- Root auto-translate stays off, so an unwrapped string shows up as a failure instead of being translated quietly.
- Do not count characters against any language. The telegram is a choice, not typed text, so it has no limit to port.

## Gates

No unwrapped CJK literal outside an allowlist; every msgid present in en, ja, ko; same `%` placeholders in the same order and balanced BBCode per entry; every character of each `.po` covered by that locale's font; a bot route under `EDD_LOCALE=en` fails on visible CJK; `test_layout_bounds` in all four locales. The existing suites stay locked to zh_TW.

## Glossary

| zh-TW | English | 日本語 | 한국어 |
|---|---|---|---|
| 光線偏折 | deflection of light; "the bending of light" in speech | 光の湾曲（formal 重力による光の偏向） | 빛의 휘어짐（formal 중력에 의한 빛의 편향） |
| 水星近日點進動 | the precession of Mercury's perihelion | 水星の近日点移動 | 수성의 근일점 이동 |
| 角秒 | arcsecond, ″ | 秒角 | 초각 |
| 等效原理 | the equivalence principle | 等価原理 | 등가 원리 |
| 日全食 | total eclipse | 皆既日食 | 개기일식 |
| 底片 | plate | 乾板 | 건판 |
| 看片台 | light box | 乾板観察台 (check) | 건판 관찰대 (check) |
| 顯微測微器 | micrometer | 測微計 | 측미계 (check) |
| 定天鏡 | coelostat | シーロスタット | 코엘로스타트 (check) |
| 遮光板 | shutter (matches the store text) | 遮光板 | 차광판 |
| 時鐘驅動 | clock drive | 時計駆動 | 시계 구동 장치 |
| 比較星 | comparison star | 比較星 | 비교성 |
| 參考星 | reference star | 基準星 | 기준성 |
| 機率誤差 | probable error | 確率誤差 | 확률 오차 |
| 兩倍誤差 | twice the error (a probable error doubled is not 2σ) | 誤差の2倍 | 오차의 2배 |
| 帳本 | ledger | 帳簿 | 장부 |
| 閃爍比對 | blink comparison | ブリンク比較 | 블링크 비교 |
| 太陽系儀 | orrery | オーラリー | 오러리 (태양계 모형) |

**Forms of address.** Dyson is ダイソン卿 in Japanese and 다이슨 경 in Korean. Dyson is `Sir Frank` or `Dyson`, never `Mr Dyson` (knighted 1915); Eddington is `Professor Eddington` or `Eddington`, never `Mr Eddington`; Ashby is `Mr Ashby`.

**Never confuse:** Mercury's perihelion (43″ per century) and the deflection of light (1.75″) are different effects. A wrong word here keeps the number right and loses the argument, and a back-translation can miss it. Probable error is about 0.6745σ, not 2σ. Keep "predicted", "measured" and "apparent displacement" distinct.

## Register

The source avoids gendered pronouns for the player and Kit; keep that in every language. The cast is British, 1917–1919.

- **English:** restrained British English (en_GB spelling), no mock-Victorian. "Mr Ashby", "Professor Eddington". Avoid pronouns for Kit and the player; singular "they" when unavoidable. Keep the dry jokes dry.
- **日本語:** readable 丁寧語, not period pastiche. アシュビー先生, エディントン教授. Drop subjects where natural. Kit and the player use 私 or no pronoun, never 僕 or 俺; no gendered sentence endings. Eddington follows the same 丁寧語; his lines were swept in #280.
- **한국어:** 해요체 in conversation; 하십시오체 when addressing Eddington formally. 애슈비 선생님, 에딩턴 교수님. No 그／그녀 and no gendered kinship titles for Kit or the player. Eddington follows the same 해요체; his lines were swept in #280.

## Titles

| | Title screen | Steam |
|---|---|---|
| zh-TW | 雲層之後 · Eddington 1919 | The store name stays `Eddington 1919` in every language, so one name is searchable; localized names are added only if Steamworks allows them without splitting it. |
| en | Beyond the Clouds | Eddington 1919: Beyond the Clouds |
| ja | Eddington 1919：雲の向こう | |
| ko | Eddington 1919: 구름 너머 | |

## Not adopted from oracle

Symbolic speaker ids (the zh constant already works as an id, and the leak gate catches a miss); a GDScript-aware parser (a small tokenizer that handles strings and comments is enough); a pseudo-locale run (real English arrives soon and tests the real text).
