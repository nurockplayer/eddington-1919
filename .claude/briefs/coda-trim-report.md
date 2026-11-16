## PR or commit

None. Read-only report against `a51e61cfe921c32d79a7311cb336954666d30118`; no files changed.

The proposal brings all three stretches to **at most eight displayed entries, including the next choice prompt where applicable**. These are **static estimates**, not playthrough measurements. Preserving every run-specific line means the longest judgment route needs substantial merging; fewer advances will not reduce reading time proportionally.

Source abbreviations below expand to these files:

| Code | File |
|---|---|
| J | [scripts/judgment.gd](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/judgment.gd) |
| B | [scripts/content.gd](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/content.gd) |
| C | [scripts/content_coda.gd](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/content_coda.gd) |
| P | [scripts/cambridge/content_epilogue.gd](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/cambridge/content_epilogue.gd) |
| Q | [scripts/cambridge/epilogue_chart.gd](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/cambridge/epilogue_chart.gd) |

Thus `J:156` means `scripts/judgment.gd:156`. Rows list alternatives at their execution position; mutually exclusive alternatives do not accumulate.

### 1. Judgment → island opening → workbook reread

The order is established by `main.gd:1716–1720`, `1118–1134`, and `1499–1517`: grade → homecoming callback → clock callback → opening → automatic reread when already written.

For this table, **verdict** means the selected first telegram response; **selection history** means whichever of J:262/267/269 appears.

| Source | Speaker | zh-TW opening | Condition | Proposal and reason |
|---|---|---|---|---|
| J:156 | Eddington | 我和你一樣懷著希望。可是一夜、幾張底片 | `confirmed`, evidence `favors_e` | **Keep** — responds to this telegram and evidence. |
| J:158 | Eddington | 「證實」？我們手上的星像撐不起這兩個字 | `confirmed`, other evidence | **Keep** — challenges this overclaim. |
| J:159 | Eddington | 完整的量測要回國後才做得完，比例尺和 | Every `confirmed` response | **Move-to-ending-history** — general measurement context; retain its uncertainty and Sobral qualification. |
| J:163 | Eddington | 「有希望」——是的。它說了我們看到的 | `hopeful`, `favors_e` | **Keep** — acknowledges an appropriate telegram. |
| J:165 | Eddington | 希望什麼呢？我們沒有一張量得出結果的 | `hopeful`, evidence `none` | **Keep** — responds to missing measurements. |
| J:167 | Eddington | 「有希望」？我們量到的數字其實偏向較 | `hopeful`, `favors_half` | **Keep** — preserves evidence disagreement. |
| J:170 | Eddington | 「有希望」可以接受，但它是個寬鬆的詞 | Other `hopeful`; interval holds neither prediction | **Keep** — distinguishes this interval. |
| J:172 | Eddington | 「有希望」可以接受，但它是個寬鬆的詞 | Other `hopeful`; preceding condition false | **Keep** — preserves ambiguity rather than claiming agreement. |
| J:176 | Eddington | 謹慎沒有錯。只是——我們的好底片確實 | `undecided`, `favors_e` | **Keep** — responds to excessive caution. |
| J:178 | Eddington | 說得誠實。雲擋住了大部分星光，我們不 | `undecided`, evidence `none` | **Keep** — acknowledges this outcome. |
| J:180 | Eddington | 對。這幾張偏向較小的偏折，可是片子少 | `undecided`, `favors_half` | **Keep** — preserves the smaller-deflection result. |
| J:183 | Eddington | 對。數字和兩種預測都對不上；在弄清楚 | Other `undecided`; interval holds neither | **Keep** — preserves the neither-prediction case. |
| J:185 | Eddington | 對。誤差範圍同時容得下兩種答案。我們 | Other `undecided`; preceding condition false | **Keep** — preserves the both-predictions case. |
| J:189 | Eddington | 沒有結果？你手上就有星點清楚的底片。 | Telegram `none`; usable and good plates exist | **Keep** — identifies an unmeasured opportunity. |
| J:191 | Eddington | 沒有結果？你手上還有可量的底片，只是 | Telegram `none`; usable plates, no good plate | **Keep** — distinguishes poor plates from no plates. |
| J:193 | Eddington | ……是的。很遺憾，但這是真的。至少我 | Telegram `none`; no usable plates | **Keep** — acknowledges genuine absence. |
| J:195 | Eddington | （你的合併估計：%.2f″ ± %.2f″ | Combined measurement count > 0 | **Merge-with verdict** — keep the player’s exact numbers beside the assessment. |
| J:201 | Eddington | 日冕很美，我也看了一眼。但美不是量測 | Reason `corona` | **Merge-with verdict** — retain feedback on the chosen reason. |
| J:205 | Eddington | 你的理由站在底片上，這很好。 | Valid reason `measured` | **Merge-with verdict** — retain the reason acknowledgment. |
| J:207 | Eddington | 你記得我們只是其中一站。Dyson 會比 | Valid reason `uncertain` | **Merge-with verdict** — retain this choice’s qualification. |
| J:209 | Eddington | 你按星點數判斷，而不是按心情。 | Valid reason `nostars` | **Merge-with verdict** — retain this choice’s acknowledgment. |
| J:211 | Eddington | 你分得出哪些偏差是我們自己帶進去的。 | Valid reason `trailed` | **Merge-with verdict** — retain the instrument diagnosis. |
| J:214 | Eddington | 你說接近 1.75″——可是看看圖上的誤 | Invalid reason `measured` | **Merge-with verdict** — retain the correction. |
| J:216 | Eddington | 可是你的底片上明明有五顆以上的星。 | Invalid reason `nostars` | **Merge-with verdict** — retain the contradiction. |
| J:220 | Eddington | 走速校過了。星像還是拖長，是曝光太久 | Invalid `trailed`; drive checked, mean trail ≥ 0.35 | **Merge-with verdict** — preserve the actual cause. |
| J:221 | Eddington | 走速校過了，星像沒有拖。別把不合期望 | Invalid `trailed`; drive checked, trail < 0.35 | **Merge-with verdict** — preserve the checked-drive distinction. |
| J:224 | Eddington | 還沒有量出任何數字，談不上偏低，也就 | Invalid `trailed`; unchecked drive, evidence `none` | **Merge-with verdict** — retain the missing-measurement correction. |
| J:226 | Eddington | 星像確實拖長了——可是拖長只會把數字 | Invalid `trailed`; unchecked drive, trail ≥ 0.35, evidence not `none` | **Merge-with verdict** — retain direction-of-error feedback. |
| J:228 | Eddington | 你量的這幾張星像沒有拖長——偏差不是 | Invalid `trailed`; unchecked, low trail, `favors_half`/`ambiguous` | **Merge-with verdict** — preserve the observed-image distinction. |
| J:229 | Eddington | 數字沒有偏到需要儀器來解釋。別替不合 | Remaining invalid `trailed` case | **Merge-with verdict** — retain the unsupported-explanation correction. |
| J:231 | Eddington | 你的理由和你寫下的電報不太對得上。 | Other invalid reason | **Merge-with verdict** — keep the reason/telegram mismatch. |
| J:243 | Eddington | 你量之前寫的是：星點不足五顆的不量， | Strict rule; poor-with-good or unusable inclusion | **Keep** — names the player’s rule and violating plates. |
| J:245 | Eddington | 你照著量之前寫下的規則選片。結果合不 | Strict rule; no violations, clean, usable selection | **Keep** — acknowledges adherence. |
| J:247 | Eddington | 只有拖長或起霧的底片可用。你照規則量 | Strict rule, clean, included poor plates | **Merge-with J:245** — one rule assessment, preserving the poor-only qualification. |
| J:249 | Eddington | 『看了數字再決定』——這正是規則要先 | Rule `after` | **Keep** — responds to the chosen rule. |
| J:251 | Eddington | 沒有先寫下的規則，事後就說不清為什麼 | Rule `none` | **Keep** — responds to the missing prior rule. |
| J:255 | Eddington | 第 %s 號底片的星像很清楚，你沒有量 | Omitted good plates | **Keep** — anchor one plate-quality entry with exact plate numbers. |
| J:257 | Eddington | 第 %s 號的星像拖長了或被雲霧蓋住。 | Included poor plates | **Merge-with J:255**, otherwise keep — consolidate plate-quality findings without dropping any. |
| J:259 | Eddington | 第 %s 號上連五顆星都數不到，量不出 | Included unusable plates | **Merge-with J:255/257**, otherwise keep — retain every named unusable plate. |
| J:262 | Eddington | 你寫下的是：第一次的數字不合預期。誠 | Reselected; any history reason `result` | **Keep** — retain the player’s admission and its precedence. |
| J:267 | Eddington | 你改了選片，也寫下了原因：第 %s 號 | Reselected; no result reason, justified correction | **Keep** — retain changed plate numbers and justification. |
| J:269 | Eddington | 你看過數值之後又改了選擇。也許有理由 | Other reselection | **Keep** — retain the unresolved selection history. |
| J:294 | Eddington | 第 %s 號各自量，數字彼此對得上。兩 | Exactly two included, usable, read good plates agree | **Merge-with selection history**, otherwise keep — retain the corroboration callback and numbers. |
| J:296 | Eddington | 第 %s 號各自量，數字彼此對得上。這 | More than two such good plates agree | **Merge-with selection history**, otherwise keep — retain plate numbers and count. |
| J:298 | Eddington | 只有一張好片——一張底片只能提出問題 | Exactly one included, usable, read good plate | **Merge-with selection history**, otherwise keep — retain the single-plate callback. |
| J:302 | Eddington | 那一段晴天其實夠長——拍到一半關上、 | J:298; plan unread and duration ≥ `SPLIT_MIN_S` | **Merge-with J:298** — retain the run-specific missed opportunity. |
| J:304 | Eddington | 你先按星像品質選片，再看數值。這個順 | Non-strict rule, clean, usable selection | **Merge-with preceding selection-history/corroboration entry**, otherwise keep — preserve the acknowledged order of work. |
| B:258 | Eddington | Cottingham。你不用一個人回家了。 | Evidence `favors_e`, clean | **Keep** — the home-alone thread’s outcome. |
| B:260 | Cottingham | ……我本來連行李都收好了。 | Same route | **Keep**, anchor Cottingham’s response — preserve his half. |
| B:262 | Eddington | Cottingham，也許你不用一個人回家。 | Evidence `favors_e`, dirty selection | **Keep** — preserves the conditional outcome. |
| B:263 | Cottingham | 那回去重挑。我陪你。 | Same route | **Keep**, anchor Cottingham’s response — preserve his offer. |
| B:266 | Eddington | Cottingham，你要不要一個人回家，我 | Evidence `ambiguous`/`favors_half` | **Keep** — preserves unresolved evidence. |
| B:267 | Cottingham | 那我等。反正我還有一座鐘要打包。 | Same route | **Keep**, anchor Cottingham’s response — preserve his answer. |
| B:269 | Eddington | 我們一起回家。看見什麼，就說什麼。 | Other evidence, normally `none` | **Keep** — retain the no-measurement outcome. |
| B:293 | Cottingham | 時鐘走得很穩。謝謝你那天替我報秒。 | Drive rate checked | **Merge-with B:260/263/267**, otherwise keep — preserve the player’s clock contribution. |
| B:295 | Cottingham | 發條是滿的，可惜沒來得及對時——長一 | Not checked; drive wound | **Merge-with B:260/263/267**, otherwise keep — preserve the partial preparation. |
| B:296 | Cottingham | 那天我一個人趕著上發條，沒時間對時。 | Neither checked nor wound | **Merge-with B:260/263/267**, otherwise keep — preserve the missed preparation. |
| C:16 | Narration | （Eddington 把電報稿折好，收進外 | Entering coda from departure route | **Keep** — establishes that the telegram leaves and the player remains. |
| C:17 | Narration | （雨早就停了。屋外的蟲聲很響，暗房裡 | Same | **Cut** — atmosphere already supplied by the scene; adds no run-specific information. |
| C:23 | Narration | （你又讀了一遍工作簿最後一頁。字比你 | Workbook already written | **Keep** — anchor the reread. |
| C:25 | 工作簿 | Stored `kit_line`, typically 給 Kit：… | Reread; stored line nonempty | **Merge-with C:23** — preserve the player’s exact written line, explicitly labeled as workbook text. |

If there are at least two eligible good plates but they disagree, J:294/296 does not appear. An empty plate array returns before J:255 onward.

The proposed live sequence has at most:

1. Verdict + combined estimate + chosen-reason feedback.
2. Rule assessment.
3. Named plate-quality findings.
4. Selection history + corroboration/single-plate reminder.
5. Eddington’s homecoming line.
6. Cottingham’s reply + clock callback.
7. Telegram departure narration.
8. Workbook reread + saved line.

Preserve the original `grade.lines` strings for consumers and ending review; group only their live presentation. This avoids breaking tests that inspect individual grade strings.

**Counts — estimates**

| Route | Current | Proposed | Next input |
|---|---:|---:|---|
| Clean reference route: strict, two agreeing good plates, `hopeful`/`measured`, no reselection, populated reread | 12 | 7 | Loupe interaction |
| Longest conditional combination: `confirmed`, maximum selection findings, populated reread | Up to 18 | Up to 8 | Loupe interaction |

The 18-entry figure is a source-derived upper bound; runtime reachability was not checked. If the workbook was not previously written, the chain stops earlier at the required workbook interaction; its subsequent first-writing dialogue is outside this reread stretch.

### 2. Loupe → first words to Kit

`main.gd:975–976` concatenates `ashby_answer()` and `small_numbers()`. Completion immediately starts `kit_close()` at `1135–1138`.

Here, **mentor-memory entry** combines C:36, C:37 and C:40 when present, preserving their order and parenthetical staging.

| Source | Speaker | zh-TW opening | Condition | Proposal and reason |
|---|---|---|---|---|
| C:36 | 你 | （他在 1917 年那頁寫的是 0.87。 | Ashby’s recorded bet exists | **Keep** — retain the 1917 wager callback. |
| C:37 | Narration | （你拿起 %s的放大鏡。） | Always | **Merge-with C:36**, otherwise anchor mentor-memory entry — retain the object action without another advance. |
| C:40 | 你 | （那天晚上你問他，是不是早就認定了。 | Player pressed Eddington | **Merge-with mentor-memory entry** — preserve the player’s challenge and answer. |
| C:42 | 你 | （放大鏡底下有星點——是你沒有拿去量 | No measurement; usable plates exist | **Keep** — anchor this outcome. |
| C:43 | 你 | （雲很厚，可是不是什麼都沒留下。回去 | Same | **Merge-with C:42** — preserve the unfinished work. |
| C:45 | 你 | （放大鏡底下沒有可以量的東西——只有 | No measurement or usable plate | **Keep** — anchor genuine failure to obtain usable evidence. |
| C:46 | 你 | （可是你把雲記下來了。他說過：無論看 | Same | **Merge-with C:45** — retain Ashby’s charge. |
| C:48 | 你 | （底片、數字、電報——每一步都寫在紙 | Measured; fit 2 and clean | **Keep** — anchor this successful record. |
| C:49 | 你 | （他不會因為這樣就相信。可是他會一頁 | Same | **Merge-with C:48** — retain Ashby’s independent response. |
| C:51 | 你 | （選片那一頁還有一行說不清楚：為什麼 | Measured; fit 2, not clean | **Keep** — anchor the unresolved selection. |
| C:52 | 你 | （回去以後把它寫清楚——在他問之前。 | Same | **Merge-with C:51** — retain the correction commitment. |
| C:54 | 你 | （電報寫得太小心，或是太寬鬆——你自 | Measured; fit 1 | **Keep** — anchor this defensible but imperfect telegram. |
| C:55 | 你 | （他會在旁邊畫一個問號。問號不丟人。 | Same | **Merge-with C:54** — retain the question-mark callback. |
| C:57 | 你 | （電報已經發出去了，收不回來。） | Measured; remaining fit, normally 0 | **Keep** — anchor the mistaken telegram. |
| C:58 | 你 | （你想起他說的：要被一張乾淨的底片說 | Same | **Merge-with C:57** — retain Ashby’s clean-plate challenge. |
| C:59 | 你 | （這一次，你差一點就成了那個好故事。 | Same | **Merge-with C:57** — retain the personal consequence. |
| C:68 | 你 | （14 號底片上那一點極淡的白。兩年了 | Residual clue found | **Keep** — sole callback here to that discovery. |
| C:69 | 你 | （Eddington 那個關緊的箱子。從裡 | Always | **Keep** — anchor the closed-box thread’s callback. |
| C:71 | 你 | （今晚量出來的，也只是幾個很小的數字 | Measured anything | **Merge-with C:69** — connect the thought experiment to this run without claiming proof. |
| C:73 | 你 | （今晚什麼也沒量到。沒有數字，也是一 | Measured nothing | **Merge-with C:69** — retain this run’s absence of numbers. |
| C:81 | 你 | （工作簿後面還有很多空白頁。回去的路 | Always | **Cut** — general transition repeats the return-home framing. |
| C:85 | 你 | （小時候那張星圖。畫錯，跟說謊，不是 | Childhood-chart answer 0; overclaimed | **Keep** — retain the player’s chart answer and overclaim. |
| C:87 | 你 | （小時候那張星圖。畫錯，跟說謊，不是 | Answer 0; not overclaimed, misread | **Keep** — distinguish misreading from overclaiming. |
| C:89 | 你 | （小時候那張星圖。畫錯，跟說謊，不是 | Answer 0; neither preceding condition | **Keep** — retain the truthful variant. |
| C:91 | 你 | （那天晚上 Kit 問起那張星圖，你沒有 | Childhood-chart answer 2 | **Keep** — retain the player’s earlier silence. |
| C:93 | 你 | （有些話，也許可以等到見了面再說。） | Bond `close` | **Keep** — preserve the relationship state. |
| C:94 | 你 | （也許。） | Bond `close` | **Merge-with C:93** — preserve the hesitation without another advance. |
| C:96 | 你 | （Kit 一定會先問天空，再問底片。） | Bond other than `close` | **Keep** — retain Kit’s anticipated priorities. |
| C:99 | 你 | （出發前我要 Kit 告訴我，劍橋這段時 | Sky promise 0 | **Keep** — preserve the selected promise immediately before the choice. |
| C:101 | 你 | （我跟 Kit 說過，全食那五分鐘我會在 | Sky promise 1 | **Keep** — preserve the other promise immediately before the choice. |
| C:106 | 你 | （見到 Kit，第一句話要說什麼？） | Always | **Keep**, including key `kit_first` — this is the next meaningful input. |

C:85/87/89 are ordered alternatives with overclaim taking precedence. Chart answers other than 0 or 2 add no chart callback; sky promises outside 0/1 add no promise line.

After the target input, C:117/119/121 supplies the chosen reply and C:110 supplies lamp-out narration. Those remain unchanged and are excluded from the pre-input count.

**Counts — estimates**

| Route | Current before choice | Proposed before choice | Proposed including choice prompt |
|---|---:|---:|---:|
| Clean reference: Ashby bet, no press/residual, fit 2 clean, chart answer 0, warm bond, valid promise | 10 | 6 | **7** |
| Longest: bet + press + residual, fit 0, chart callback, close bond, valid promise | 14 | 7 | **8** |

### 3. October reunion → first Sobral interpretation

Actual order: `kit_reunion()` → `opening()` (`epilogue_director.gd:95`) → player opens the letter → `letter()` → chart. Opening the letter is an object interaction; the first evidence interpretation arrives after three prescribed chart-copy clicks.

The reunion has 12 dialogue entries when `kit_first` is valid, regardless of close/warm bond.

| Source | Speaker | zh-TW opening | Condition | Proposal and reason |
|---|---|---|---|---|
| P:34 | Kit | 你瘦了。 | Always | **Keep** — anchor Kit’s greeting. |
| P:35 | Kit | 說吧。你決定好要先跟我說的那一句。 | Always | **Merge-with P:34** — retain Kit inviting the player’s saved answer. |
| P:38 | 你 | Stored workbook reply; otherwise ……我回來了。 | Always; strips translated 給 Kit： prefix | **Keep** — the player’s own line must remain distinct. |
| P:40 | Kit | 那我要聽。從雲開始講。 | `kit_first == 0` | **Keep** — anchor Kit’s response to the sky answer. |
| P:41 | Kit | 範圍很寬，也是一個答案。你以前不會這 | `kit_first == 1` | **Keep** — anchor Kit noticing the player’s changed certainty. |
| P:42 | Kit | 那就慢慢告訴我。今天晚上很長。 | `kit_first == 2` | **Keep** — anchor Kit’s invitation to explain. |
| P:43 | Narration | （你把工作簿遞過去。Kit 翻到最後一 | Always | **Merge-with P:40/41/42**, otherwise P:44 — preserve the intervening action as parenthetical staging. |
| P:44 | Kit | 這是你自己抬頭看到的。好。 | Always | **Merge-with P:40/41/42**, otherwise keep — preserve Kit reading and acknowledging the workbook. |
| P:46 | Kit | 你要我寫這裡變了什麼。我寫了。 | Sky promise 0 | **Keep** — anchor Kit fulfilling the player’s request. |
| P:48 | Kit | 你沒要我寫，我還是記下來了。 | Other sky promise | **Keep** — anchor Kit’s independent initiative. |
| P:49 | Kit | Trumpington 街的路燈又亮了。那 | Always | **Merge-with P:46/48** — keep Kit’s account of life at home. |
| P:50 | Kit | 那顆變星，我量到分鐘了。它一次也沒有 | Always | **Merge-with P:46/48** — keep Kit’s own observing work and humor. |
| P:51 | Narration | （桌角有一個沒寄出的信封，寫著你的名 | Always | **Merge-with P:52**, before its speech — retain the envelope’s introduction. |
| P:52 | Kit | 那是給你的。船要走六個星期，你會比它 | Always | **Keep** — anchor Kit’s unsent-letter explanation. |
| P:54 | Kit | ……裡面寫了什麼，以後再說。不是今晚 | Bond `close` | **Merge-with P:52** — preserve Kit choosing when to disclose it. |
| P:56 | Kit | 反正裡面寫的，剛剛都說了。省一張郵票 | Other bond | **Merge-with P:52** — preserve Kit’s warm-route answer. |
| P:26 | Ashby 先生 | Greenwich 來信了。Dyson 寫的，在 | After the reunion | **Keep** — directs the next object interaction. |
| P:74 | Dyson 的信（推測重建，非原文） | Sobral 的底片在 Greenwich 量完 | Player opens letter | **Keep** — supplies both instrument results and the astrograph caveat needed for interpretation. |
| P:75 | Ashby 先生 | 把它們抄到你的圖上。一筆一筆來。 | After letter result | **Cut** — the chart’s copying buttons already provide this instruction. |

That yields five reunion entries, one Ashby opening entry, and one letter entry: **seven before the chart question**.

These chart states are controls rather than additional dialogue entries:

| Source | Speaker/type | zh-TW text | Condition | Proposal and reason |
|---|---|---|---|---|
| Q:151 | Button | 抄上 Sobral 4 吋 | Step 0 | **Keep** — retain the existing instrument-by-instrument reveal. |
| Q:151 | Button | 抄上 Sobral 天體照相儀 | Step 1 | **Keep** — retain the separate weak-instrument reveal. |
| Q:151 | Button | 抄好了 | Step 2 | **Keep** — preserve the current transition into interpretation. |
| Q:145 | Question | Sobral 4 吋那一點：細線（兩倍誤差） | Step 3; answer not yet selected | **Keep** — the first meaningful Sobral interpretation. |

The player’s own chart row remains conditional on measurement count; the no-value note remains when appropriate (`Q:119–129`). No chart numbers, uncertainty notes, or recorded answers change.

**Counts — estimates**

| Route | Current before interpretation | Proposed before interpretation | Proposed including question |
|---|---:|---:|---:|
| Clean reference, valid `kit_first` | 15 | 7 | **8** |
| Longest, valid `kit_first`; either bond variant | 15 | 7 | **8** |

Three prescribed copying clicks remain in both counts. A missing `kit_first` removes one current reunion response; it does not create a longer route.

### Key references and tests requiring updates

Targeted searches covered the relevant keys, callback functions, text fragments, and structural assertions in `tests/`.

**Do not remove or rename:**

- `kit_first` at C:106. `main.gd:1140–1142` reads it, stores it, and writes its reply into the workbook; the October reunion reads the stored state. Tests/bots locating it include `test_coda.gd:323,359,400`, `autoplay_bot.gd:258,663`, and `prologue_bot.gd:434`.
- Existing purposes `reaction`, `coda_opening`, `coda_workbook`, `coda_loupe`, and `coda_kit`. Preserve the automatic reread and completion flow.
- `sobral_read`, stored by `epilogue_director.gd:180`; retain the chart question and answer recording.
- Upstream `telegram`, `reason`, and `press`, and downstream `astro_weight`. The proposal does not change their choices or keys.

**Three existing structural expectations would need updating:**

| Test | Required change |
|---|---|
| `tests/test_night_story.gd:58` | Replace the assumption that live grade-entry count equals `grade.lines.size()`; retain the assertion that the homecoming payoff follows grading and Cottingham closes the reaction. Account for his merged response. |
| `tests/test_prediction_ledger.gd:276–277` | Replace “Ashby bet adds exactly one entry” with preservation of its conditional text inside the merged mentor-memory entry. |
| `tests/test_epilogue.gd:71` | The player’s saved reply moves from `seq[2]` to `seq[1]` after merging Kit’s two opening lines; retain exact speaker/text checks. |

Keep raw `grade.lines` intact so `test_sim.gd`’s exact membership checks—including corroboration and the long-single-plate reminder—remain valid. Preserve the exact promise entry immediately before `kit_first` for `test_coda.gd:326–327`; the proposed merges leave that entry separate.

The inspected text checks for Kit’s bond, chart recollection, envelope variants, the closed box, residual discovery, and lamp-out remain meaningful without changing their expected content. The chart-step expectations in `test_epilogue.gd:290–320,454–460` remain unchanged.

## Tests

Command: **none**, as specified by the brief.  
Result: **Not run — read-only proposal; no Godot, tests, builds, or web research.**

## Assumptions

- “Keep” preserves all run-specific text, values, conditions, and relationship responses in the compulsory sequence; merging does not discard those facts.
- Merges preserve original order and mark embedded narration or workbook quotations explicitly.
- A meaningful input chooses an interpretation/response or interacts with the coda object; routine advances and the chart’s prescribed copying clicks do not qualify as interpretation.
- Counts exclude captions, persistent chart labels, and post-choice replies. Choice-inclusive totals are shown separately.
- `docs/map/INDEX.md` and `docs/map/symbols.tsv` were absent. Reads followed the named files and narrow call/key dependencies.
- The specific read-only instruction overrides generic commit, push, and PR instructions.

## Follow-ups

If implemented, update the three structural test expectations above and check the longest merged judgment pages for readability. The current proposal meets the entry-count target through compression; it does not establish a corresponding reduction in elapsed reading time.

## Blocked

none

cx-exec review: no open PR for this branch; skipped
