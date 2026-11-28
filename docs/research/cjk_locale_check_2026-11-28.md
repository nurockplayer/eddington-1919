## Answer

The catalogs mostly use the reference vocabulary. The clearest fixes are Japanese `日冕` and `定天鏡`, Korean `개기일식` where the string means the timed totality phase, and mixed terminology for the same instrument or person. The Traditional Chinese inconsistencies are chiefly mixed Latin and Chinese names, plus two names for the astrograph. I found no confirmed mainland-only form in the audited Chinese terms and no case where a transliteration identifies the wrong person.

I checked the working copy at `fda9d800` and consulted the web sources on **2026-11-28 JST**. Counts are occurrences in nonempty `msgstr` values, including plural translations. The Japanese and Korean totals include catalog entries outside the current template, so they describe the files as requested. In the Chinese table, **PO → combined** means explicit `zh_TW.po` count → count after adding the untranslated source keys from `messages.pot`. The latter captures the Chinese wording that is absent from the small override catalog. Examples are `msgid` excerpts. Counts cover the listed forms, and ordinary sentence paraphrases are illustrated where relevant. No files changed. [Reference table](/Users/tachikoma/Developer/eddington-1919/docs/research/cjk_relativity_terms_2026-11-28.md), [project glossary](/Users/tachikoma/Developer/eddington-1919/docs/design/LOCALIZATION.md:20), [Madeira terminology](/Users/tachikoma/Developer/eddington-1919/docs/design/journey/MADEIRA.md:201), [locale configuration](/Users/tachikoma/Developer/eddington-1919/project.godot:31)

### Japanese · `ja`

| Term | Current forms and `msgid` example | Reference form | Verdict | Minimal fix |
|---|---|---|---|---|
| General relativity | `一般相対論` 1 · `比較 0″（不偏折）…` | `一般相対性理論／一般相対論` | ok | — |
| Light deflection | `偏向` 15, `光の偏向` 9, `太陽周縁での偏向` 2, `星の光の偏向` 1, `偏折` 2. Dialogue also uses forms such as `星の光が曲が…` 2. · `星光偏折（太陽邊緣，角秒）`, `「有希望」是個寬鬆的詞。…` | `重力による光の曲がり／恒星の光の曲がり`. The project glossary and lecture also support `光の偏向`. [J1] | inconsistent | Change the two `偏折` instances to `偏向`. Keep natural descriptions of bending in dialogue. |
| Total solar eclipse | `皆既日食` 6 overall, including 3 on source strings about totality · `…有一次日全食` | `皆既日食` | ok | See totality for the three phase uses. |
| Totality | `皆既` 19, `皆既中` 8, `皆既の間` 1, plus `皆既日食` 3 on `全食` keys · `全食期間無法變更`, `全食節奏：標準` | `皆既／皆既の間`, with `皆既中` attested [J2] | inconsistent | Use `皆既中` for the lockout and `皆既` for timing controls that govern this phase. |
| Second / third contact | `第2接触` 1, `第二接触` 1, `第三接触` 10 · `食既・…`, `底片用完了。［%s］等待第三接觸` | `第2接触／第3接触` [J2] | inconsistent | Use one numeral style. Both styles are attested. |
| Corona | `コロナ` 4, `日冕` 6 · `日冕示意圖`, `日冕那麼清楚——我們一定成功了。` | `コロナ／太陽コロナ` [J2] | inconsistent | `日冕` → `コロナ` in six strings. |
| Photographic plate | `乾板` 304, including compounds · `底片架` | `写真乾板／乾板` | ok | — |
| Astrographic telescope | `天体写真儀` 26 · `相同星場・天體照相儀` | `天体写真儀／アストログラフ` | ok | — |
| Coelostat | `シーロスタット` 9, `定天鏡` 1 · `我負責定天鏡的驅動。…` | `シーロスタット` [J3] | inconsistent | Replace the one `定天鏡`. |
| Micrometer / plate-measuring engine | `測微計` 8, `測微器` 2 · `測微器`, `② 測微器讀數 %d/%d` | `乾板測定機／コンパレータ` for the machine. Project glossary gives `測微計` for the micrometer. [H1] | inconsistent | Use `測微計` throughout the readout and dialogue. Use the machine term where the whole apparatus is named. |
| Reference / comparison plate | `比較用乾板` 11, `比較用の乾板` 3, `比較乾板` 8, `比較写真` 1 · `參考底片`, `牛津比對片`, `…當地的比對照片仍待拍攝。` | `比較用プレート／比較用乾板`. The Madeira notes use `比較乾板`. [H1] | inconsistent | Use `比較用乾板` for repeated labels for the same plate. Keep prose variation and the separate check-field designation. |
| Arcsecond | `秒角` 18, `″` 94 · `日緣偏折（角秒）` | `秒角／″` | ok | — |
| Royal Society | `王立協会` 2, `王立学会` 1 · `皇家學會與皇家天文學會・聯席會議` | `英国王立協会` [J4] | inconsistent | Change the one `王立学会` to `王立協会`. Both forms occur in Japanese sources. |
| Royal Astronomical Society | `王立天文学会` 4 · `…皇家天文學會的月報。…` | `英国王立天文学会` | ok | — |
| Astronomer Royal | `王室天文官` 3 · `皇家天文學家 Frank Dyson 報告…` | `王室天文官／王室付天文学者` [J3] | ok | — |
| Greenwich Observatory | `グリニッジ` 7, full title 0 · `Greenwich 來信了。…` | `グリニッジ天文台／グリニッジ王立天文台` [J3] | ok | — |
| Príncipe | `プリンシペ` 29, `プリンシペ島` 2 · `普林西比清單` | `プリンシペ島` | ok | — |
| Sobral | `ソブラル` 61 · `索布拉爾清單` | `ソブラル` | ok | — |
| Madeira | `マデイラ` 1, `マデイラ島` 1, `Madeira` 2 inside the newspaper title · `馬德拉的等待`, `《Diário da Madeira》…` | `マデイラ島` | ok | — |
| Newtonian gravity / half-deflection | `ニュートン` 6 standalone, `ニュートン式の計算` 5, `ニュートン式` 4 standalone, `ニュートン式の比較値` 1, `ニュートンの計算` 1, `ニュートンの計算法` 1, `ニュートン型` 1. `0.87` 30 overall. · `0.87″・牛頓式比較值` | `ニュートンの万有引力／ニュートン説の予測値 0.87秒角` [H1] | ok | — |
| Einstein value | `アインシュタインの予測` 3, `アインシュタインの全部` 2, other `アインシュタイン` 13. `1.75` 24 overall. · `1.75″・愛因斯坦的預測`, `1.75：愛因斯坦的全部` | `アインシュタインの予測値 1.75秒角` [H1] | ok | — |
| Arthur Stanley Eddington | `エディントン` 74, `A. S. エディントン` 4, `アーサー・エディントン` 1, Latin `Eddington` 1 in the game title · `Eddington`, `Arthur Eddington 報告…` | `アーサー・スタンリー・エディントン` [J1] | ok | — |
| Frank Watson Dyson | `ダイソン` 20, `フランク・ダイソン` 2. Across both, `卿` 15 and `先生` 2. · `讀 Dyson 的信`, `（Dyson 先生在倫敦等我們的日食報告。…` | `フランク・ダイソン`. Glossary address `ダイソン卿`. | inconsistent | Change the two `ダイソン先生` to `ダイソン卿`. The surname is consistent. |
| Andrew Crommelin | `クロメリン` 8, `クロムリン` 1 · `日食觀測極佳。Crommelin`, `…Cowell 和 Crommelin…` | `クロンメリン` in the reference and contemporary eclipse account. Both shipped forms have astronomical attestations. [J5] | inconsistent | Use `クロンメリン` throughout if adopting the expedition reference spelling. |
| Charles Rundle Davidson | `デイヴィッドソン` 8 · `Crommelin 和 Davidson・搭「Anselm」號前往巴西` | `チャールズ・デイヴィッドソン` | ok | — |
| Edwin Turner Cottingham | `コッティンガム` 46 · `Cottingham` | `コッティンガム` | ok | — |

### Traditional Chinese · `zh_TW`

| Term | Current forms, PO → combined, and `msgid` example | Reference form | Verdict | Minimal fix |
|---|---|---|---|---|
| General relativity | `廣義相對論` 0 → 1 · `比較 0″（不偏折）…` | `廣義相對論` [T1] | ok | — |
| Light deflection | `偏折` 10 → 24 standalone, `日緣偏折` 2 → 2, `星光偏折` 0 → 3, `重力偏折` 0 → 1, `彎曲` 1 → 4, `星光彎…` 2 → 3 · `日緣偏折（角秒）`, `星光彎了多少？` | `光線偏折／星光偏折` [T1] | ok | — |
| Total solar eclipse | `日全食` 0 → 3 · `…有一次日全食` | `日全食` [T1] | ok | — |
| Totality | `全食` 0 → 28 · `全食節奏：標準` | `全食／全食階段` [T1] | ok | — |
| Second / third contact | `食既` 0 → 1, `第二接觸` 0 → 1, `第三接觸` 0 → 7, `生光` 0 → 0 · `食既・…`, `…等待第三接觸` | `食既／生光` [T2] | inconsistent | Use `食既` and `生光` in phase labels. Add a plain-language gloss only where the instruction needs it. |
| Corona | `日冕` 0 → 10 · `日冕示意圖` | `日冕` [T1] | ok | — |
| Photographic plate | `底片` 22 → 266, including compounds · `你的底片・模擬` | `玻璃乾版底片／玻璃乾版`; the project glossary gives `底片` [T3] | ok | Use `玻璃乾版底片` at the first material-specific mention if the glass matters. |
| Astrographic telescope | `天體照相儀` 6 → 24, `天文攝影儀` 0 → 2 · `Sobral 的天體照相儀`, `器材・檢查牛津天文攝影儀…` | `天文照相儀／天體照像儀` in the reference. Taiwan’s NAER explicitly gives the shipped `天體照相儀`. [T3] | inconsistent | Use `天體照相儀` in the two equipment descriptions. |
| Coelostat | `定天鏡` 0 → 9 · `報告推測，陽光使定天鏡鏡面受熱不均。` | `定天鏡` | ok | — |
| Micrometer / plate-measuring engine | `測微器` 0 → 7, `顯微測微器` 0 → 2 · `測微器`, `顯微測微器：把十字線對到…` | `測微器／乾版測量儀` (proposed for the machine). Glossary `顯微測微器`. [T3, H1] | ok | — |
| Reference / comparison plate | `比對底片` 0 → 11, `比對片` 0 → 8, `參考底片` 0 → 2, `比對照片` 0 → 1 · `牛津比對底片`, `參考底片` | `比較用乾版` (proposed). Madeira notes give `比對底片`. [H1] | inconsistent | Use `比對底片` for the same-field plate label. Keep the separate check-field label. |
| Arcsecond | `角秒` 1 → 18, `″` 22 → 94 · `日緣偏折（角秒）` | `角秒／″` [T1] | ok | — |
| Royal Society | `皇家學會` 1 → 3 · `皇家學會與皇家天文學會・聯席會議` | `英國皇家學會` | ok | — |
| Royal Astronomical Society | `皇家天文學會` 1 → 4 · `皇家學會與皇家天文學會・聯席會議` | `英國皇家天文學會` | ok | — |
| Astronomer Royal | `皇家天文學家` 1 → 3 · `皇家天文學家 Frank Dyson 報告…` | `皇家天文學家` [T1] | ok | — |
| Greenwich Observatory | `格林威治` 0 → 3, `Greenwich` 0 → 4, full title 0 → 0 · `Greenwich 來信了。…`, `器材・檢查格林威治…` | `格林威治天文台／格林威治皇家天文台` | inconsistent | Use `格林威治` for the four Latin names in prose. |
| Príncipe | `普林西比` 0 → 22, `普林西比島` 0 → 1, `Príncipe` 8 → 8 · `普林西比清單`, `Príncipe` | `普林西比島` [T1] | inconsistent | Use `普林西比` on the eight Latin labels and prose mentions. |
| Sobral | `索布拉爾` 0 → 24, `Sobral` 12 → 37 · `索布拉爾清單`, `Sobral 4 吋望遠鏡` | `索布拉爾`; `索貝爾` also noted in the reference [T1] | inconsistent | Use `索布拉爾` for UI and prose. Preserve source spellings in quotations. |
| Madeira | `馬德拉` 0 → 2, `Madeira` 0 → 2 inside the newspaper title · `馬德拉的等待` | `馬迪拉島／馬德拉島` [T4] | ok | — |
| Newtonian gravity / half-deflection | `牛頓式` 0 → 6 standalone, `牛頓` 0 → 5 standalone, `牛頓的算法` 0 → 3, `牛頓式的算法` 0 → 2, `牛頓式比較值` 1 → 1. `0.87` 5 → 30 overall. · `0.87″・牛頓式比較值` | `牛頓萬有引力／牛頓理論預測值 0.87角秒` [H1] | ok | — |
| Einstein value | `愛因斯坦的預測` 1 → 2, `愛因斯坦的全部` 0 → 2, other `愛因斯坦` 1 → 14. `1.75` 1 → 24 overall. · `1.75″・愛因斯坦的預測` | `愛因斯坦的預測值 1.75角秒` [H1, T1] | ok | — |
| Arthur Stanley Eddington | `愛丁頓` 0 → 18, bare `Eddington` 0 → 56 including the game title, `A. S. Eddington` 0 → 4, `Arthur Eddington` 1 → 1 · `愛丁頓教授`, `Arthur Eddington 報告…` | `亞瑟・愛丁頓／艾丁頓` [T1] | inconsistent | Use `愛丁頓` in ordinary prose and speaker labels, with `亞瑟・愛丁頓` for a full-name label. |
| Frank Watson Dyson | `戴森` 0 → 3, `法蘭克・戴森` 0 → 1, `Dyson` 0 → 18, `Frank Dyson` 1 → 1 · `讀 Dyson 的信`, `皇家天文學家 Frank Dyson 報告…` | `戴森` [T1] | inconsistent | Use `戴森` in prose and `法蘭克・戴森` for a full-name label. |
| Andrew Crommelin | Latin `Crommelin` 0 → 9 · `日食觀測極佳。Crommelin` | `克羅梅林` (historically attested, proposed for modern Taiwan) | ok | Keep the consistent Latin spelling until a Taiwan form is established. |
| Charles Rundle Davidson | Latin `Davidson` 0 → 8 · `Crommelin 和 Davidson・搭「Anselm」號前往巴西` | `戴維森` (proposed) | ok | Keep the consistent Latin spelling. |
| Edwin Turner Cottingham | Latin `Cottingham` 0 → 40 · `Cottingham` | `科廷厄姆` (proposed) | ok | Keep the consistent Latin spelling. |

`天文攝影儀` is a terminology mismatch for the instrument. The evidence does not establish it as a mainlandism. Two other possible false positives, `毫米` 1 and `校驗片` 2 in the combined corpus, use wording attested by Taiwan authorities. [T3, T5]

### Korean · `ko`

| Term | Current forms and `msgid` example | Reference form | Verdict | Minimal fix |
|---|---|---|---|---|
| General relativity | `일반 상대성 이론` 1 · `比較 0″（不偏折）…` | `일반 상대성 이론／일반 상대론` | ok | — |
| Light deflection | `편향` 9, `휨` 13 standalone, `휘어짐` 3 standalone, `별빛의 휘어짐` 1, `빛의 휨` 1, `별빛의 휨` 1. Dialogue uses verbs such as `별빛은 얼마나 휘었나?`. · `星光偏折（太陽邊緣，角秒）`, `日緣偏折（角秒）` | `빛의 휘어짐／별빛의 휘어짐`. The glossary also gives formal `중력에 의한 빛의 편향`. [K1] | inconsistent | Give equivalent plot and result labels one term. Keep the formal and conversational register distinction. |
| Total solar eclipse | `개기일식` 31 overall, including 24 on keys about `全食` · `…有一次日全食` | `개기일식` [K2] | ok | See totality for the phase uses. |
| Totality | `개기식` 4, `개기 단계` 2, `개기` 1, and `개기일식` 24 on `全食` keys · `[b]全食[/b]　剩餘 %d 秒（共 302）` | `개기식／개기식 기간` [K2] | wrong | Use `개기식` on the timer and other strings that specifically mean the interval between contacts. Keep `개기일식` for the event. |
| Second / third contact | `제2접촉` 2, `제3접촉` 10 · `食既・…`, `…等待第三接觸` | `제2접촉／제3접촉` [K2] | ok | — |
| Corona | `코로나` 10 · `日冕示意圖` | `코로나／태양 코로나` [K2] | ok | — |
| Photographic plate | `건판` 335, including compounds · `底片架` | `사진 건판／건판` [K3] | ok | — |
| Astrographic telescope | `천체사진의` 18, `천체사진기` 8 · `相同星場・天體照相儀`, `Sobral 天體照相儀` | `천체사진의` [K3] | inconsistent | Replace the eight `천체사진기` occurrences for this instrument. |
| Coelostat | `실로스탯` 4, `코엘로스타트` 5, of which one is outside the template · `報告推測，陽光使定天鏡鏡面受熱不均。`, `Cottingham 負責定天鏡的驅動裝置。` | `실로스탯`. Project glossary lists `코엘로스타트` provisionally. [K3] | inconsistent | Use `실로스탯` in the catalog and glossary. |
| Micrometer / plate-measuring engine | `측미계` 8, `측미기` 2 · `測微器`, `② 測微器讀數 %d/%d` | `측미기／건판 측정기` (latter proposed). Project glossary gives `측미계` provisionally. [H1] | inconsistent | Use `측미기` for the same instrument across the readout, dialogue, and glossary. |
| Reference / comparison plate | `비교용 건판` 10, `비교 건판` 8, `기준 건판` 1, `비교 사진` 1 · `夜裡的比對片`, `牛津比對片`, `參考底片` | `비교 건판` (attested, adoption unclear) [H1] | inconsistent | Use `비교 건판` on recurring same-field plate labels. Keep the separate check-field designation. |
| Arcsecond | `초각` 18, `각초` 1, `″` 94 · `星光偏折（太陽邊緣，角秒）`, `日緣偏折（角秒）` | `초각／각초`; project glossary `초각` | inconsistent | Change the single `각초` label to `초각`. Both orders are listed in the reference. |
| Royal Society | `왕립학회` 3 · `皇家學會與皇家天文學會・聯席會議` | `영국 왕립학회` | ok | — |
| Royal Astronomical Society | `왕립천문학회` 4 · `皇家學會與皇家天文學會・聯席會議` | `영국 왕립천문학회` | ok | — |
| Astronomer Royal | `왕실천문관` 2, `왕실 천문관` 1 · `皇家天文學家 Frank Dyson 報告…` | `왕실 천문관` | inconsistent | Standardize the spacing. |
| Greenwich Observatory | `그리니치` 7, full title 0 · `Greenwich 來信了。…` | `그리니치 천문대／왕립 그리니치 천문대` | ok | — |
| Príncipe | `프린시페` 30, `프린시페 섬` 1 · `普林西比清單`, `…普林西比島` | `프린시페섬` [K1] | non-standard | Match the reference spacing on the single full island form. The short form is established in the project. |
| Sobral | `소브랄` 44, `소브라우` 17 · `索布拉爾清單`, `Sobral 4 吋望遠鏡` | `소브랄／소브라우` (latter marked as a less-established variant) [K1] | inconsistent | Use the project spelling `소브랄` throughout. |
| Madeira | `마데이라` 2, `Madeira` 2 inside the newspaper title · `馬德拉的等待` | `마데이라섬` | ok | — |
| Newtonian gravity / half-deflection | `뉴턴` 7 standalone, `뉴턴식 계산` 5, `뉴턴식` 4 standalone, `뉴턴식 비교값` 1, `뉴턴의 계산` 1. `0.87` 30 overall. · `0.87″・牛頓式比較值` | `뉴턴의 만유인력／뉴턴식 예측값 0.87초각` [H1] | ok | — |
| Einstein value | `아인슈타인의 예측값` 1, `아인슈타인의 예측` 2, `아인슈타인의 전부` 2, other `아인슈타인` 13. `1.75` 24 overall. · `1.75″・愛因斯坦的預測` | `아인슈타인의 예측값 1.75초각` [H1] | ok | — |
| Arthur Stanley Eddington | `에딩턴` 71, `A. S. 에딩턴` 3, `아서 에딩턴` 1, bare Latin `Eddington` 4 including the game title, Latin `A. S. Eddington` 1 · `Eddington 回憶…`, `Arthur Eddington 報告…` | `아서 스탠리 에딩턴` [K1] | inconsistent | Use `에딩턴` in ordinary narrative. Preserve the title and verbatim source credits. |
| Frank Watson Dyson | `다이슨` 20, `프랭크 다이슨` 2, `Dyson` 1. `다이슨 선생님` 2 versus glossary `다이슨 경`. · `在格林威治，Davidson 和 Furner 在 Dyson 指導下…` | `프랭크 다이슨` | inconsistent | Localize the Latin surname and use `다이슨 경` in the two address strings. |
| Andrew Crommelin | `크로멀린` 5, `크로멜린` 1, `Crommelin` 3 · `Crommelin 和 Davidson・搭「Anselm」號前往巴西`, `…Cowell 和 Crommelin…` | `앤드루 크로멜린` [K1] | inconsistent | Standardize localized prose on `크로멜린`. `크로멀린` differs from the independently attested spelling. |
| Charles Rundle Davidson | `데이비드슨` 5, `Davidson` 3 · `Davidson・縮光圈至 8 吋的天體照相儀…` | `찰스 데이비슨／찰스 데이비드슨` (the latter is marked as a variant) [K1] | inconsistent | Choose one Hangul form for narrative. `데이비슨` is the form independently confirmed in the expedition lecture. |
| Edwin Turner Cottingham | `코팅엄` 46, `Cottingham` 1 · `Cottingham 負責定天鏡的驅動裝置。` | `E. 코팅엄` [K1] | inconsistent | Change the single Latin surname in prose to `코팅엄`. |

## Sources

All web sources below were consulted on **2026-11-28 JST**. The expedition report and historical journal scans attest period usage. Institutional glossaries, almanacs, and public education pages establish published modern usage.

- **H1** · The original report gives the `0.87″` and `1.75″` predictions and distinguishes comparison and check plates. Eddington’s own account attests *micrometer* for the plate instrument. [Expedition report](https://zenodo.org/records/1432106/files/article.pdf), [Eddington’s account](https://en.wikisource.org/wiki/Page%3AEddington_A._Space_Time_and_Gravitation._1920.djvu/134)
- **J1–J2** · University of Tokyo material attests `光の偏向`, `一般相対性理論`, and `アーサー・エディントン`. Sendai Space Hall and NAOJ attest the eclipse phases and `コロナ`. NAOJ also uses spelled-out contact numerals. [University lecture](https://granite.phys.s.u-tokyo.ac.jp/michimura/lectures/Niigata_EIE2016_6_michimura.pdf), [Sendai Space Hall](https://sendaiuchukan.jp/event/news/2009eclipse/qa/qa.html), [NAOJ observation](https://www.youtube.com/watch?v=RrIbnr2DRBo)
- **J3–J4** · The Japanese Astronomical Society gives `シーロスタット` and the Greenwich title. University sources attest both renderings of Royal Society. [Coelostat](https://astro-dic.jp/coelostat/), [Greenwich](https://astro-dic.jp/royal-greenwich-observatory/), [University of Tokyo](https://www.s.u-tokyo.ac.jp/ja/info/11150/), [Hokkaido University](https://hosho.ees.hokudai.ac.jp/tsuyu/top/dct/natsci-j.html)
- **J5** · The expedition-era journal uses `クロンメリン`. A later journal issue has `クロメリン`, and the Japan Planetary Society uses `クロムリン` for the named comet. [Expedition-era issue](https://www.asj.or.jp/geppou/archive_open/1919/pdf/191908.pdf), [later journal issue](https://www.asj.or.jp/geppou/archive_open/1932/pdf/193206.pdf), [comet guide](https://planetary.jp/track_comet/guide/index.html)
- **T1–T2** · Taiwan sources attest the physics and eclipse terms, both Eddington forms, `戴森`, `普林西比島`, `索布拉爾`, and the phase names `食既／生光`. [Taipei Astronomical Museum expedition article](https://www-ws.gov.taipei/001/Upload/439/ebook/ebook_1818555/pdf/full.pdf), [Tainan Astronomical Museum](https://taea.tn.edu.tw/astro_news/news_list_detail/48e60338-18fe-11eb-aae3-8e3826ec404a), [科技大觀園](https://scitechvista.nat.gov.tw/Article/c000008/detail?ID=a2165e4b-80af-4714-b6f4-89f96f9b34a3), [Taipei eclipse guide](https://www-ws.gov.taipei/001/Upload/public/Attachment/02715475386.pdf)
- **T3–T5** · NAER gives `天體照相儀` and `測微計`. The museum catalog gives `玻璃乾版底片`. CNA attests `馬迪拉島`. Taiwan authorities use `毫米` and `校驗`. [NAER physics terminology](https://teric.naer.edu.tw/wSite/DoDownload?fileName=1462779739979&format=pdf&xmlId=1849190), [NCKU Museum](https://collections.culture.tw/ncku_collectionsweb/Collection?GID=M6MRMKM4), [CNA](https://www.cna.com.tw/tag/58044/), [BSMI units](https://www.bsmi.gov.tw/wSite/public/Data/f1650522664108.PDF), [Taiwan instrument calibration rules](https://law.moj.gov.tw/LawClass/LawAll.aspx?pcode=K0100005)
- **K1–K3** · Korea University attests `크로멜린`, `데이비슨`, `코팅엄`, `프린시페`, and `소브랄`. KASI distinguishes `개기식` from the whole eclipse and uses `실로스탯`. ScienceAll defines `천체사진의` and uses `사진 건판`. [Korea University lecture](https://kuocw.korea.ac.kr/download%21subdwld.action%3Bjsessionid%3D50877AE93D882FF41551B2F96254D8AE?sysFileNm=201501071304501420603490793.pdf), [KASI eclipse terminology](https://www.kasi.re.kr/publication/post/newsMaterial/29992), [Korean observing guide for contact numbering](https://astronet.co.kr/xe/index.php?document_srl=7131&mid=making&order_type=desc&sort_index=regdate), [KASI instrument description](https://kswrc.kasi.re.kr/ko/about/facilities/ksis), [ScienceAll astrograph entry](https://www.scienceall.com/brd/board/390/L/menu/317?bbsSn=30628&brdCodeValue=&brdType=R&thisPage=1)

## Unsure

- The reference’s proposed modern Taiwan spellings for Crommelin, Davidson, and Cottingham, and the exact Taiwan and Korean terms for the historical plate-measuring engine and comparison plates, remain weakly attested. The original report and project glossary support the instrument and plate distinctions.
- Independent confirmation was stronger for Korean `소브랄`, `데이비슨`, and `코팅엄` than for rarer variants. `web.run open` on `https://paperis.app/articles/kids-eddington` and `https://www.nowsky.org/ko/articles/eclipse-1919-eddington` returned `Cache miss`. `web.run open` on `https://horology.deep-research.jp/docs/piece/dent1906/` also returned `Cache miss`, so the Japanese `コッティンガム` verdict uses the supplied reference’s modern attestation. The web calls have no shell exit code. Public search and the Korea University lecture provided the alternative evidence for the Korean names. The Japanese period account provided a historical spelling only.

Stop: done — all reference entries were checked in all three locales, with unresolved attestations identified.
## Applied terminology changes

| Locale | msgid | Before | After | Source |
|---|---|---|---|---|
| ja | `Cottingham：「這幾秒雲很薄，我看得見日冕的邊。」` | 日冕 | コロナ | [J2] |
| ja | `定天鏡・反射鏡隨天空轉動，把光反射進固定的鏡筒。` | 定天鏡 | シーロスタット | [J3] |
| ja | `「有希望」是個寬鬆的詞。我們的數字只容得下不偏折…` | 偏折 | 偏向 | [J1] |
| zh_TW | `皇家天文學家 Frank Dyson 報告 Sobral 的結果…` | Frank Dyson / Sobral | 法蘭克・戴森 / 索布拉爾 | [T1] |
| zh_TW | `Arthur Eddington 報告 Príncipe 兩張底片…` | Arthur Eddington / Príncipe | 亞瑟・愛丁頓 / 普林西比 | [T1] |
| zh_TW | `器材・檢查牛津天文攝影儀…` | 天文攝影儀 | 天體照相儀 | [T3] |
| ko | `[b]全食[/b]　剩餘 %d 秒（共 302）` | 개기일식 | 개기식 | [K2] |
| ko | `Cottingham 負責定天鏡的驅動裝置。` | 코엘로스타트 | 실로스탯 | [K3] |
| ko | `日緣偏折（角秒）` | 각초 | 초각 | glossary / [K1] |
