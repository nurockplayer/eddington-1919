# Speaker / portrait coverage

Regenerate: `tachi-run --host -- godot --headless --path . --script res://tools/portrait_coverage.gd`

Acceptance row: **F4**, portrait clause made judgeable; existing gaps remain.

Counts are authored dialogue entry sites (`s` dictionaries), across all conditional and choice branches, not one playthrough. A repeated or data-driven entry template counts once; choices, captions, toasts and text embedded within an entry are not extra lines. Inline entries in `main.gd` are included. The Príncipe workbook in Departure's content file and the May coda belong to Príncipe; October is the separate epilogue.

Default main presentation (engraving; no debug overrides). Paths and names are obtained by playing each entry through `ui.gd` and `dialogue_portrait.gd`, with main's `Style.dress_dialogue`. Names are shown in en / ja / zh-TW / ko order; `(blank)` is an empty name, not an inferred person. `none` records a coverage gap, including unnamed narration.

## Cambridge 1917

| Speaker (source) | Line count | Portrait path | Displayed name (en / ja / zh-TW / ko) |
| --- | ---: | --- | --- |
| (blank) | 4 | none | (blank) / (blank) / (blank) / (blank) |
| 1915 年觀測日誌 | 2 | none | Observing Log, 1915 / 1915年の観測日誌 / 1915 年觀測日誌 / 1915년 관측 일지 |
| Ashby 先生 | 95 | res://assets/portraits/ashby_neutral.jpg | Mr Ashby / アシュビー先生 / Ashby 先生 / 애슈비 선생님 |
| Eddington | 55 | res://assets/portraits/eddington_neutral.jpg | Eddington / エディントン / Eddington / 에딩턴 |
| Kit | 45 | none | Kit / Kit / Kit / Kit |
| Kit的帳簿 | 1 | none | Kit's Ledger / Kitの記録簿 / Kit的帳簿 / Kit의 장부 |
| 你 | 2 | none | You / あなた / 你 / 당신 |
| 你的工作筆記 | 1 | none | Your Working Notes / あなたの作業ノート / 你的工作筆記 / 당신의 작업 공책 |
| 信 | 1 | none | Letter / 手紙 / 信 / 편지 |
| 天文鐘 | 1 | none | Astronomical Clock / 天文時計 / 天文鐘 / 천문시계 |
| 太陽系儀 | 7 | none | The orrery / オーラリー / 太陽系儀 / 오러리 |
| 年鑑・1846 | 1 | none | Almanac · 1846 / 年鑑・1846 / 年鑑・1846 / 연감 · 1846 |
| 年鑑・1910 | 1 | none | Almanac · 1910 / 年鑑・1910 / 年鑑・1910 / 연감 · 1910 |
| 年鑑・水星 | 2 | none | Almanac · Mercury / 年鑑・水星 / 年鑑・水星 / 연감 · 수성 |
| 底片櫃 | 1 | none | Plate Cabinet / 乾板棚 / 底片櫃 / 건판 수납장 |
| 爐火 | 1 | none | Fire / 暖炉 / 爐火 / 난로 |
| 留聲機 | 5 | none | Gramophone / 蓄音機 / 留聲機 / 축음기 |
| 空桌子 | 1 | none | Empty Desk / 空の机 / 空桌子 / 빈 책상 |
| 窗 | 1 | none | Window / 窓 / 窗 / 창 |
| 量測儀 | 1 | none | Measuring Machine / 測微計 / 量測儀 / 측미계 |

## Departure

| Speaker (source) | Line count | Portrait path | Displayed name (en / ja / zh-TW / ko) |
| --- | ---: | --- | --- |
| (blank) | 3 | none | (blank) / (blank) / (blank) / (blank) |
| Ashby 先生 | 17 | none | Mr Ashby / アシュビー先生 / Ashby 先生 / 애슈비 선생님 |
| Kit | 33 | none | Kit / Kit / Kit / Kit |
| 你 | 1 | none | You / あなた / 你 / 당신 |

## Príncipe 1919 (including coda)

| Speaker (source) | Line count | Portrait path | Displayed name (en / ja / zh-TW / ko) |
| --- | ---: | --- | --- |
| (blank) | 14 | none | (blank) / (blank) / (blank) / (blank) |
| 1917 年的筆記 | 1 | none | The 1917 notes / 1917年のノート / 1917 年的筆記 / 1917년의 노트 |
| Cottingham | 8 | res://assets/portraits/cottingham_engraving.jpg | Cottingham / コッティンガム / Cottingham / 코팅엄 |
| Eddington | 43 | res://assets/portraits/eddington_engraving.jpg | Eddington / エディントン / Eddington / 에딩턴 |
| 上一回的曝光 | 1 | none | The last exposure / 前回の露出 / 上一回的曝光 / 지난번 노출 |
| 你 | 19 | none | You / あなた / 你 / 당신 |
| 曝光計畫（筆記，遊戲內重建） | 1 | none | Exposure Plan (notebook, reconstructed in-game) / 露出計画（ノート・ゲーム内再構成） / 曝光計畫（筆記，遊戲內重建） / 노출 계획(노트, 게임 내 재구성) |
| 牛津比對底片 | 2 | none | Oxford comparison plate / オックスフォードの比較用乾板 / 牛津比對底片 / 옥스퍼드 비교용 건판 |

## October epilogue

| Speaker (source) | Line count | Portrait path | Displayed name (en / ja / zh-TW / ko) |
| --- | ---: | --- | --- |
| (blank) | 3 | none | (blank) / (blank) / (blank) / (blank) |
| 1917 年的帳本 | 2 | none | The 1917 ledger / 1917年の記録簿 / 1917 年的帳本 / 1917년의 장부 |
| Ashby 先生 | 33 | none | Mr Ashby / アシュビー先生 / Ashby 先生 / 애슈비 선생님 |
| Dyson 的信（推測重建，非原文） | 1 | none | Dyson's letter (speculative reconstruction, not a quotation) / ダイソン卿の手紙（推測による再構成、原文ではない） / Dyson 的信（推測重建，非原文） / 다이슨의 편지(추측 재구성, 원문 아님) |
| Kit | 11 | none | Kit / Kit / Kit / Kit |
| 你 | 2 | none | You / あなた / 你 / 당신 |
| 太陽系儀 | 3 | none | The orrery / オーラリー / 太陽系儀 / 오러리 |
| 年鑑・水星（1919 年 10 月補記） | 1 | none | Almanac · Mercury (note added October 1919) / 年鑑・水星（1919年10月の追記） / 年鑑・水星（1919 年 10 月補記） / 연감 · 수성(1919년 10월 추기) |
| 筆記本 | 1 | none | The notebook / ノート / 筆記本 / 공책 |

Source fingerprint: `82dd58b880aad789aea4fcb668df39cef6ab26ebb2042c3a4ae937d7cb818fbf`
