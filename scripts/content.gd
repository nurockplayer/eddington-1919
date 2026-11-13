extends RefCounted
## Dialogue and examine texts. All dialogue is FICTION (dramatised). Lines that
## rest on the record are noted with HISTORICAL_RECORD in docs/PROVENANCE.md.

const Prompts := preload("res://scripts/prompts.gd")
const Settings := preload("res://scripts/settings.gd")
const E := "Eddington"
const C := "Cottingham"
const YOU := "你"


static func briefing() -> Array:
	return [
		{"s": E, "t": L.t("你來了。雨總算停了——十點多那場雷雨，是我們上島以來最大的一場。")},
		{"s": E, "t": L.t("太陽躲在雲後面，月亮已經吃掉大半。全食只有 [b]302 秒[/b]。")},
		# FICTION: Eddington watches the gap.
		{"s": E, "t": L.t("我從早上就盯著那道雲縫。每次我開始相信它，它就合上。")},
		{"s": E, "t": L.t("我負責換底片，Cottingham 拿遮光板控制曝光。[b]你替我們看雲[/b]：雲變薄就喊「開始」，雲變厚、或全食快結束時喊「停」。")},
		{"s": E, "t": L.t("我已經裝好四個底片匣。暗房裡還有八個——能搬多少就搬多少，放到望遠鏡旁的架子上。")},
		{"s": E, "t": L.t("Cottingham 在定天鏡那裡。早上的濕氣讓時鐘驅動不太聽話，他需要一雙手。")},
		{"s": E, "t": L.t("還有問題嗎？"), "key": "why", "choices": [L.t("明白了。"), L.t("為什麼要拍太陽旁邊的星？")],
			"then": [[], [
				{"s": E, "t": L.t("如果星光經過太陽時會彎曲，太陽旁的星看起來就會被往外推一點點。把今天的底片和一月在牛津拍的同一片星場比較，就能量出推了多少。")},
				{"s": E, "t": L.t("愛因斯坦的理論預測，太陽邊緣的偏折是 1.75 角秒（大約是三公里外，一枚硬幣的寬度）；照另一種算法只有一半，0.87；也可能根本不動。[b]我們是來量的，不是來證明的。[/b]")},
			]]},
	]


static func eddington_prep(plates: int, drive_wound: bool, drive_rate_checked: bool, carried: int) -> Array:
	var handoff := L.tn("（你手上的 %d 張會交給 Cottingham）", carried) % carried if carried > 0 else ""
	var drive := L.t("上了發條並校過走速") if drive_rate_checked else (L.t("上了發條但沒校走速") if drive_wound else L.t("還沒上發條"))
	return [
		{"s": E, "t": L.t("可用底片 %d 張%s。時鐘驅動：%s。") % [plates, handoff, drive]},
		{"s": E, "t": L.t("還有什麼事嗎？"), "key": "prep", "choices": [L.t("開始——就位等待全食。"), L.t("曝光的要領再說一次？"), L.t("先空拍一次，練練喊開始和停？"), L.t("沒事。")],
			"then": [[], [
				{"s": E, "t": L.t("雲薄的時候，幾秒就能留下星像；厚雲下開再久也只是一片霧。換片要四秒左右。")},
				{"s": E, "t": L.t("最要緊的是：[b]第三接觸之前一定要喊停[/b]。陽光一回來，那張底片就毀了。")},
			], [], []]},
	]


static func cottingham_first() -> Array:
	return [
		{"s": C, "t": L.t("啊，你來得正好。這場雨把什麼都弄濕了。")},
		{"s": C, "t": L.t("定天鏡靠這具重錘時鐘轉動，跟著太陽走。發條得上滿，走速還要對著天文鐘校一次——不然曝光一長，星像就拖成短線。")},
		{"s": C, "t": L.t("你先在驅動箱上[b]按一下 %s 開始上發條[/b]，然後到桌上的[b]天文鐘[/b]那裡替我報秒。") % Prompts.key("interact") if Settings.hold_toggle else L.t("你先在驅動箱上[b]按住 %s 上發條[/b]，然後到桌上的[b]天文鐘[/b]那裡替我報秒。") % Prompts.key("interact")},
	]


static func cottingham_after_wind() -> Array:
	return [{"s": C, "t": L.t("發條滿了。現在到天文鐘那裡替我報秒，我來調走速。")}]


static func cottingham_done() -> Array:
	return [{"s": C, "t": L.t("走速對上了。全食時你看雲、我拿遮光板，Eddington 先生換片。三個人剛好。")}]


static func cottingham_stakes() -> Array:
	return [
		# HISTORICAL_RECORD: Eddington's 1938 recollection; RECONSTRUCTION: Cottingham recalls it here.
		{"s": C, "t": L.t("出發前，Dyson 先生跟我說：要是底片上量出愛因斯坦的兩倍，Eddington 會發瘋，你就得自己一個人回家。")},
		# FICTION: laughter, the question and the replies.
		{"s": C, "t": L.t("他是笑著說的。可是他沒說，要是上面什麼都沒有，會怎樣。"), "key": "stakes", "choices": [L.t("那就一起回家，照實說。"), L.t("如果真的什麼都沒有呢？"), L.t("（沒有說話）")],
			"then": [
				[{"s": C, "t": L.t("嗯。照實說。Dyson 先生讀得懂一張空白的底片。")}],
				[{"s": C, "t": L.t("那就帶一箱說『什麼都沒有』的底片回去。那也是答案——只是很貴。")}],
				[{"s": C, "t": L.t("……我也是。先把鐘調好。")}] ]},
	] + cottingham_done()


static func after_totality(exposed: int) -> Array:
	# RECONSTRUCTION: paraphrase of Eddington's 21 June 1919 letter, EDDN/A/4/9.
	var seq: Array = [{"s": E, "t": L.t("我沒看到日食。只看了一眼確定開始了，中途又看一眼雲有多厚。其餘的時間都在換底片。")}]
	if exposed == 0:
		# FICTION.
		seq.append({"s": E, "t": L.t("沒有底片，也是一筆紀錄。把雲寫下來。")})
	else:
		# HISTORICAL_RECORD: 1920 report p. 314, cloud thinned in the last third.
		seq.append({"s": C, "t": L.t("最後那一段，雲變薄了。")})
	# FICTION: protagonist's thought.
	seq.append({"s": YOU, "t": L.t("（你看見了。從頭到尾，你都在看天。）")})
	return seq


static func plan_text() -> Array:
	var lines: Array = [
		{"s": L.t("曝光計畫（筆記，遊戲內重建）"), "t": L.t("· 全食 302 秒。曝光預計 2 到 20 秒不等，換片約 4 秒。\n· 星像需要足夠「清楚的天空」：雲薄時幾秒就夠；厚雲下再久也只是一片霧。\n· 走速未校時，曝光超過約 6 秒星像就會拖長。\n· 天一透光，先拍一張短的就關；換片要四秒。換好了天還亮著，再拍第二張——兩張能互相檢查。第二張是機會，不是保證。\n· [b]第三接觸前務必關上快門。[/b]")},
	]

	var tree := Engine.get_main_loop() as SceneTree
	var story = tree.root.get_node_or_null("Story") if tree else null
	if story and not story.runs.is_empty():
		lines.append({"s": L.t("上一回的曝光"), "t": exposure_summary(story.runs.back())})
	if story and story.prologue_done:
		var names: Array[String] = []
		for card in preload("res://scripts/cambridge/content_1917.gd").plan_cards():
			if card.id in story.plan:
				names.append(card.text)
		lines.append({"s": L.t("1917 年的筆記"), "t": L.t("你在 1917 年參與擬定的原則：%s") % L.t("；").join(names)})
	return lines


static func oxford_text() -> Array:
	return [
		{"s": L.t("牛津比對底片"), "t": L.t("1919 年 1 月，用[b]同一具望遠鏡[/b]在牛津夜空拍下的同一片星場（金牛座畢宿星團一帶）。日食這天，太陽正好在這片星前面。")},
		{"s": L.t("牛津比對底片"), "t": L.t("島上要再過好幾個月才能在夜裡看到這片星，所以比對片必須事先拍好。之後要把日食底片和它疊在一起比較星的位置。")},
	]


static func night_intro(n_plates: int) -> Array:
	if n_plates == 0:
		return [{"s": E, "t": L.t("……我們一張也沒有拍。雲和時間都沒有等我們。")}]
	return [
		{"s": E, "t": L.t("接下來的六個晚上，我們每晚沖兩張。")},
		{"s": E, "t": L.t("都在測量桌上了。[b]先按星像好壞挑片，再量[/b]。量完了，再告訴我你怎麼想。")},
	]


## The 1917 "conditions" card: each plate's note also records the drive.
## Without the prologue everyone gets it; after it, only if the card was planned.
static func drive_note(plan: Array, played: bool, rate_checked: bool) -> String:
	if played and not plan.has("conditions"):
		return ""
	if rate_checked:
		return L.t("走速：早上已對著天文鐘校過。")
	return L.t("走速：沒有校過——曝光越久，星像拖得越長。")


## The 1917 plan board remembered in the darkroom; empty without the prologue.
## A core card the player left off was added by Eddington at the bottom.
static func comparison_recall(plan: Array, played: bool) -> String:
	if not played:
		return ""
	if plan.has("comparison"):
		return L.t("（1917 年的計畫板上，這張比對片是你放上去的。）")
	return L.t("（1917 年的計畫板上漏了它，是 Eddington 補在最下面的。）")


static func comparison_errand() -> Array:
	return [
		{"s": E, "t": L.t("等一下——比對片還在箱子裡。1917 年的板上漏了它，是我補上的；今晚由你去拿。")},
		{"s": E, "t": L.t("沒有它，這些星就沒有「原來的位置」可以比。")},
	]


static func comparison_fetched() -> Array:
	return [{"s": "", "t": L.t("（你把牛津那盒比對片抱上測量桌。一月的夜空，同一具望遠鏡。）")}]


static func calibration_recall(plan: Array, played: bool) -> String:
	if not played:
		return ""
	if plan.has("far_stars"):
		return L.t("比例和方向，先用遠處的星校正過——1917 年你寫進了計畫。")
	return L.t("比例和方向，先用遠處的星校正過——那一條是 Eddington 補上的。")


## exam_q1: the 1917 answer to "what would you have handed in without the 14" (-1: none).
static func rules_prompt(planned: bool, exam_q1 := -1, previous_rule := "") -> Array:
	var out: Array = []
	if previous_rule != "":
		out.append({"s": E, "t": L.t("上一回寫的是：%s。這回仍請在量之前決定。") % rule_wording(previous_rule)})
	match exam_q1:
		0:
			out.append({"s": "", "t": L.t("（1917 年 Eddington 問你，沒找到原因會交什麼。你說：交上差異，寫「原因未明」。）")})
		1:
			out.append({"s": "", "t": L.t("（1917 年 Eddington 問你，沒找到原因會交什麼。你說：照最像的那樣對齊，交上去。他說，猜沒有錯，只是要寫明是猜。）")})
	if planned:
		out.append({"s": "", "t": L.t("（你想起 1917 年計畫板上那張卡：量之前，先寫下什麼樣的底片不能用。）")})
	out.append({"s": E, "t": L.t("量之前，先在記錄本上寫一句：哪些底片不納入？"), "key": "rule", "choices": [
		L.t("星點不足五顆的不量；星像拖長或被雲霧蓋住的，不和清楚的平均。"),
		L.t("先全部量，看了數字再決定留哪些。"),
		L.t("不用先寫，看片子的時候自然知道。"),
	]})
	return out


## Conversion arc move A: the prediction ledger. FICTION prompt. The three values are the
## historical predictions: 0, 0.87″ (Newtonian-style corpuscle result) and 1.75″ (Einstein).
static func bet_prompt(prev: Dictionary) -> Array:
	if not prev.is_empty():
		return [
			{"s": E, "t": L.t("量之前，翻回 1917 年那一頁。你寫的是 %s（%s）。") % [bet_pick_text(prev.pick), bet_sure_text(prev.sure)]},
			{"s": E, "t": L.t("還是不改？"), "key": "bet_keep",
				"choices": [L.t("不改。"), L.t("改：零"), L.t("改：0.87"), L.t("改：1.75"), L.t("改：說不準")]},
		]
	return [
		{"s": E, "t": L.t("量之前，先在記錄本上寫下：你猜會看到哪一個？"), "key": "bet",
			"choices": [L.t("零：光不會被拉彎"), L.t("0.87：照牛頓的算法，只有一半"), L.t("1.75：愛因斯坦的全部"), L.t("說不準，寫不出來")]},
		{"s": E, "t": L.t("有多確定？"), "key": "bet_sure",
			"choices": [L.t("很確定"), L.t("有點把握"), L.t("只是猜")], "then": [[], [], []]},
	]


static func bet_pick_text(pick: int) -> String:
	return [L.t("零"), "0.87", "1.75", L.t("說不準")][pick] if pick >= 0 and pick <= 3 else L.t("沒有寫")


static func bet_sure_text(sure: int) -> String:
	return [L.t("很確定"), L.t("有點把握"), L.t("只是猜")][sure] if sure >= 0 and sure <= 2 else L.t("沒有寫")


## Conversion arc move A: the player's bet set against the 2σ range. bounds comes from
## Judgment.interval_bounds(sim). States containment only — no winner language.
static func bet_vs_plates(pick: int, bounds: Dictionary) -> String:
	if pick < 0 or pick > 3:
		return ""
	var names := [L.t("零"), "0.87", "1.75"]
	var held: Array[String] = []
	var lost: Array[String] = []
	for i in 3:
		var value: float = [0.0, 0.87, 1.75][i]
		if bounds.lo <= value and value <= bounds.hi:
			held.append(names[i])
		else:
			lost.append(names[i])
	var clause := L.t("三個都容不下——先懷疑儀器。")
	if not held.is_empty():
		clause = L.t("容得下 %s，容不下 %s。") % [_bet_join(held), _bet_join(lost)] if not lost.is_empty() else L.t("三個都在裡面。")
	if pick == 3:
		return L.t("你寫的是「說不準」。現在，你的底片能說準一點了嗎？%s") % clause
	var own := L.t("容得下它") if names[pick] in held else L.t("容不下它")
	return L.t("你押的是 %s。你的底片——兩倍誤差之內——%s。%s") % [names[pick], own, clause]


static func _bet_join(names: Array) -> String:
	if names.size() <= 1:
		return str(names[0]) if not names.is_empty() else ""
	if names.size() == 2:
		return L.t("%s 和 %s") % [names[0], names[1]]
	return L.t("%s、%s 和 %s") % [names[0], names[1], names[2]]


static func interval_prompt(interval: String) -> Array:
	return [{"s": E, "t": L.t("先看你的數字：%s。圖上的粗線是你的數字加減一個誤差，兩端延伸的細線是兩倍誤差。細線範圍裡，容得下哪一個預測？") % interval, "key": "interval", "choices": [L.t("兩個都容得下（0.87″ 和 1.75″）"), L.t("只容得下 1.75″"), L.t("只容得下 0.87″"), L.t("兩個都不在裡面")]}]


static func interval_feedback(answer: int, truth: int) -> String:
	if answer == truth:
		return L.t("對，範圍就是這樣讀的。")
	var contains := [L.t("範圍同時容得下 0.87″ 和 1.75″"), L.t("範圍只容得下 1.75″"), L.t("範圍只容得下 0.87″"), L.t("0.87″ 和 1.75″ 都不在範圍裡")]
	return L.t("再看一次：%s。\n看圖上的細線：兩條預測線，哪一條落在細線裡面？") % contains[truth]


static func judgment_prompt(telegrams: Array, reasons: Array) -> Array:
	return [
		{"s": E, "t": L.t("我們得發電報給倫敦的 Dyson。只有幾個字的空間——你會寫什麼？"), "key": "telegram", "choices": telegrams},
		{"s": E, "t": L.t("根據什麼？"), "key": "reason", "choices": reasons},
	]


## Story audit D4: Cottingham's payoff of Dyson's "go home alone" (cottingham_stakes). Undated on purpose.
static func go_home_alone(evidence: String, clean: bool) -> Array:
	match evidence:
		"favors_e":
			if clean:
				# RECONSTRUCTION: Eddington's line as later retold (Douglas 1956); wording and day UNVERIFIED.
				return [{"s": E, "t": L.t("Cottingham。你不用一個人回家了。")},
					# FICTION.
					{"s": C, "t": L.t("……我本來連行李都收好了。")}]
			# FICTION: the same line, held back by a selection that is not clean.
			return [{"s": E, "t": L.t("Cottingham，也許你不用一個人回家。可是這一疊底片，我們挑得還不夠乾淨。")},
				{"s": C, "t": L.t("那回去重挑。我陪你。")}]
		"ambiguous", "favors_half":
			# FICTION.
			return [{"s": E, "t": L.t("Cottingham，你要不要一個人回家，我還說不準。")},
				{"s": C, "t": L.t("那我等。反正我還有一座鐘要打包。")}]
	# FICTION: nothing measured.
	return [{"s": E, "t": L.t("我們一起回家。看見什麼，就說什麼。")}]


## Story audit D5: the player may ask whether Eddington decided before sailing. pick: the bet
## (0 zero, 1 0.87, 2 1.75, 3 說不準). Admits hope, points to what he did about it. FICTION.
static func press_eddington(pick: int) -> Array:
	var reply: String = L.t("那你比我誠實。電報照底片寫。")
	if pick == 2:
		reply = L.t("那我們是兩個懷著希望的人，中間只有一套底片。電報照底片寫，不照我們寫。")
	elif pick == 0 or pick == 1:
		reply = L.t("那今晚我們之中，有一個人會失望。底片不在乎是誰。")
	return [{"s": E, "t": L.t("電報之前，你還有話要說？"), "key": "press",
		"choices": [L.t("你在出發前，就認定是 1.75 了，對不對？"), L.t("（什麼都不說）")],
		"then": [
			[{"s": E, "t": L.t("是。我希望是。")},
			# FICTION; basis: the rule is written before measuring (rules_prompt), and the Sobral party was Greenwich staff (Crommelin, Davidson).
			{"s": E, "t": L.t("所以規則要在你量之前寫好。所以 Sobral 那一地的底片，不經過我的手。")},
			{"s": E, "t": L.t("換你了。你在本子上押的是什麼？")},
			{"s": E, "t": reply}],
			[]]}]


static func cottingham_coda(sim) -> String:
	if sim.drive_rate_checked:
		return L.t("時鐘走得很穩。謝謝你那天替我報秒。")
	if sim.drive_wound:
		return L.t("發條是滿的，可惜沒來得及對時——長一點的曝光，星像都有點拖。")
	return L.t("那天我一個人趕著上發條，沒時間對時。下次我們先把這件事做完。")


# --- M5 totality (Director-owned; docs/design/M5_TOTALITY.md). FICTION. Hindsight and
# facts only: no line may tell the player *when* to expose.

## Cottingham's read of the exposure that just closed. band: clear|mixed|cloud|brief.
static func totality_read(band: String) -> String:
	match band:
		"clear":
			return L.t("Cottingham：「這幾秒雲很薄，我看得見日冕的邊。」")
		"mixed":
			return L.t("Cottingham：「一半在雲裡，一半透了光。」")
		"cloud":
			return L.t("Cottingham：「整段幾乎都在雲後面。」")
		"brief":
			return L.t("Cottingham：「太短了，大概什麼都沒留下。」")
	return ""


## The same read, as the night plate viewer shows it.
static func totality_read_night(band: String) -> String:
	match band:
		"clear":
			return L.t("拍攝時：Cottingham 說雲很薄，看得見日冕。")
		"mixed":
			return L.t("拍攝時：Cottingham 說一半在雲裡。")
		"cloud":
			return L.t("拍攝時：Cottingham 說幾乎整段都在雲後。")
		"brief":
			return L.t("拍攝時：曝光太短。")
	return ""


## An exposure has run 20 s, the longest of the real programme.
static func totality_long(rate_checked: bool) -> String:
	if rate_checked:
		return L.t("Cottingham：「二十秒了。」")
	return L.t("Cottingham：「二十秒了——驅動沒對過時，再久星像會拖長。」")


static func totality_last_plate() -> String:
	return L.t("Eddington：「最後一張了。」")


## Late in totality, plates unused and nothing taken for a while. Facts only.
static func totality_plates_left(n: int) -> String:
	return L.tn("Eddington：「還有 %d 張底片。」", n) % n


## No exposure in the first 45 s: say where to look, never when.
static func totality_first_nudge() -> String:
	return L.t("Eddington：「看太陽周圍那一小片，不是整片天。那裡變薄了就喊。」")


static func replay_opening(trial: int, same_sky: bool) -> Array:
	return [
		{"s": "", "t": L.t("本子翻到新的一頁：第 %d 次試驗。上一回的記錄留在旁邊。") % trial},
		{"s": E, "t": L.t("%s這回，你想改哪一步？先記住自己的打算。") % (L.t("同一片雲。") if same_sky else L.t("天空換了；差異也可能來自雲況。"))},
		{"s": E, "t": L.t("到了晚上，把兩回的做法和數字並排看看。")},
	]


static func rule_wording(id: String) -> String:
	var i := ["strict", "after", "none"].find(id)
	return rules_prompt(false)[-1].choices[i] if i >= 0 else L.t("未寫規則")


static func exposure_summary(run: Dictionary) -> String:
	var times: Array[String] = []
	var selected: Array[String] = []
	var usable := 0
	for p in run.exposures:
		times.append("%.0f/%.0f" % [p.start, p.duration])
		if p.included:
			selected.append(str(p.number))
		if p.usable:
			usable += 1
	return L.t("起/曝（約秒）：%s；選片：%s；可用 %d 張") % [",".join(times) if not times.is_empty() else L.t("無"), ",".join(selected) if not selected.is_empty() else L.t("無"), usable]


static func run_value(run: Dictionary) -> String:
	var c: Dictionary = run.combined
	return L.tn("%.2f″ ± %.2f″（量 %d 張）", c.n) % [c.value, c.sigma, c.n] if c.n > 0 else L.t("沒有量出數值。")


static func run_comparison(previous: Dictionary, current: Dictionary) -> String:
	var precision := ""
	if previous.combined.n > 0 and current.combined.n > 0:
		var old_sigma := ("%.2f" % previous.combined.sigma).to_float()
		var new_sigma := ("%.2f" % current.combined.sigma).to_float()
		if new_sigma < old_sigma:
			precision = L.t("這回的誤差較小；仍要看選片與儀器。")
		elif new_sigma == old_sigma:
			precision = L.t("誤差與上回相同；量值照實並列。")
		else:
			precision = L.t("這回的誤差較大；把不確定也記下來。")
	var old_rule := rule_wording(previous.rule_id)
	var new_rule := rule_wording(current.rule_id)
	var rule := L.t("選片規則：『%s』→『%s』。") % [old_rule, new_rule]
	if previous.rule_id != current.rule_id:
		rule = L.t("選片規則改了：『%s』→『%s』。兩回依據不同。") % [old_rule, new_rule]
	var reason := L.t("電報的理由%s：『%s』→『%s』。") % [L.t("改了") if previous.reason_id != current.reason_id else "", previous.reason_text, current.reason_text]
	var rows: Array[String] = [
		exposure_summary(previous) + " → " + exposure_summary(current),
		L.t("上回：%s → 這回：%s %s") % [run_value(previous), run_value(current), precision],
		rule,
		reason,
	]
	return L.t("[b]本子上的兩次試驗｜上回 → 這回[/b]\n[font_size=%d]%s[/font_size]") % [preload("res://scripts/settings.gd").fs(15), "\n".join(rows)]
