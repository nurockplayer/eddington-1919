extends RefCounted
## Dialogue and examine texts. All dialogue is FICTION (dramatised). Lines that
## rest on the record are noted with HISTORICAL_RECORD in docs/PROVENANCE.md.

const E := "Eddington"
const C := "Cottingham"
const YOU := "你"


static func briefing() -> Array:
	return [
		{"s": E, "t": "你來了。雨總算停了——十點多那場雷雨，是我們上島以來最大的一場。"},
		{"s": E, "t": "太陽躲在雲後面，月亮已經吃掉大半。全食只有 [b]302 秒[/b]。"},
		{"s": E, "t": "我負責換底片，Cottingham 拿遮光板控制曝光。[b]你替我們看雲[/b]：雲變薄就喊「開始」，雲變厚、或全食快結束時喊「停」。"},
		{"s": E, "t": "我已經裝好四個底片匣。暗房裡還有八個——能搬多少就搬多少，放到望遠鏡旁的架子上。"},
		{"s": E, "t": "Cottingham 在定天鏡那裡。早上的濕氣讓時鐘驅動不太聽話，他需要一雙手。"},
		{"s": E, "t": "還有問題嗎？", "key": "why", "choices": ["明白了。", "為什麼要拍太陽旁邊的星？"],
			"then": [[], [
				{"s": E, "t": "如果星光經過太陽時會彎曲，太陽旁的星看起來就會被往外推一點點。把今天的底片和一月在牛津拍的同一片星場比較，就能量出推了多少。"},
				{"s": E, "t": "愛因斯坦的理論預測，太陽邊緣的偏折是 1.75 角秒；照另一種算法只有一半，0.87；也可能根本不動。[b]我們是來量的，不是來證明的。[/b]"},
			]]},
	]


static func eddington_prep() -> Array:
	return [
		{"s": E, "t": "還有什麼事嗎？", "key": "prep", "choices": ["我準備好了——就位等待全食。", "曝光的要領再說一次？", "沒事。"],
			"then": [[], [
				{"s": E, "t": "雲薄的時候，幾秒就能留下星像；厚雲下開再久也只是一片霧。換片要四秒左右。"},
				{"s": E, "t": "最要緊的是：[b]第三接觸之前一定要喊停[/b]。陽光一回來，那張底片就毀了。"},
			], []]},
	]


static func cottingham_first() -> Array:
	return [
		{"s": C, "t": "啊，你來得正好。這場雨把什麼都弄濕了。"},
		{"s": C, "t": "定天鏡靠這具重錘時鐘轉動，跟著太陽走。發條得上滿，走速還要對著天文鐘校一次——不然曝光一長，星像就拖成短線。"},
		{"s": C, "t": "你先在驅動箱上[b]按住 E 上發條[/b]，然後到桌上的[b]天文鐘[/b]那裡替我報秒。"},
	]


static func cottingham_after_wind() -> Array:
	return [{"s": C, "t": "發條滿了。現在到天文鐘那裡替我報秒，我來調走速。"}]


static func cottingham_done() -> Array:
	return [{"s": C, "t": "走速對上了。全食時你看雲、我拿遮光板，Eddington 先生換片。三個人剛好。"}]


static func plan_text() -> Array:
	var lines: Array = [
		{"s": "曝光計畫（筆記，遊戲內重建）", "t": "· 全食 302 秒。曝光預計 2 到 20 秒不等，換片約 4 秒。\n· 星像需要足夠「清楚的天空」：雲薄時幾秒就夠；厚雲下再久也只是一片霧。\n· 走速未校時，曝光超過約 6 秒星像就會拖長。\n· 晴窗有十四秒以上時，拆成兩張短片勝過一張長片——兩張能互相檢查。換片要四秒；窗更短就一張拍到底。\n· [b]第三接觸前務必關上快門。[/b]"},
	]

	var tree := Engine.get_main_loop() as SceneTree
	var story = tree.root.get_node_or_null("Story") if tree else null
	if story and story.prologue_done:
		var names: Array[String] = []
		for card in preload("res://scripts/cambridge/content_1917.gd").plan_cards():
			if card.id in story.plan:
				names.append(card.text)
		lines.append({"s": "1917 年的筆記", "t": "你在 1917 年參與擬定的原則：" + "；".join(names)})
	return lines


static func oxford_text() -> Array:
	return [
		{"s": "牛津比對底片", "t": "1919 年 1 月，用[b]同一具望遠鏡[/b]在牛津夜空拍下的同一片星場（金牛座畢宿星團一帶）。日食這天，太陽正好在這片星前面。"},
		{"s": "牛津比對底片", "t": "島上要再過好幾個月才能在夜裡看到這片星，所以比對片必須事先拍好。之後要把日食底片和它疊在一起比較星的位置。"},
	]


static func night_intro(n_plates: int) -> Array:
	if n_plates == 0:
		return [{"s": E, "t": "……我們一張也沒有拍。雲和時間都沒有等我們。"}]
	return [
		{"s": E, "t": "接下來的六個晚上，我們每晚沖兩張。"},
		{"s": E, "t": "都在測量桌上了。[b]先按星像好壞挑片，再量[/b]。量完了，再告訴我你怎麼想。"},
	]


## The 1917 "conditions" card: each plate's note also records the drive.
## Without the prologue everyone gets it; after it, only if the card was planned.
static func drive_note(plan: Array, played: bool, rate_checked: bool) -> String:
	if played and not plan.has("conditions"):
		return ""
	if rate_checked:
		return "走速：早上已對著天文鐘校過。"
	return "走速：沒有校過——曝光越久，星像拖得越長。"


## The 1917 plan board remembered in the darkroom; empty without the prologue.
## A core card the player left off was added by Eddington at the bottom.
static func comparison_recall(plan: Array, played: bool) -> String:
	if not played:
		return ""
	if plan.has("comparison"):
		return "（1917 年的計畫板上，這張比對片是你放上去的。）"
	return "（1917 年的計畫板上漏了它，是 Eddington 補在最下面的。）"


static func calibration_recall(plan: Array, played: bool) -> String:
	if not played:
		return ""
	if plan.has("far_stars"):
		return "比例和方向，先用遠處的星校正過——1917 年你寫進了計畫。"
	return "比例和方向，先用遠處的星校正過——那一條是 Eddington 補上的。"


## exam_q1: the 1917 answer to "what would you have handed in without the 14" (-1: none).
static func rules_prompt(planned: bool, exam_q1 := -1) -> Array:
	var out: Array = []
	match exam_q1:
		0:
			out.append({"s": "", "t": "（1917 年 Eddington 問你，沒找到原因會交什麼。你說：交上差異，寫「原因未明」。）"})
		1:
			out.append({"s": "", "t": "（1917 年 Eddington 問你，沒找到原因會交什麼。你說：照最像的那樣對齊，交上去。他說，猜沒有錯，只是要寫明是猜。）"})
	if planned:
		out.append({"s": "", "t": "（你想起 1917 年計畫板上那張卡：量之前，先寫下什麼樣的底片不能用。）"})
	out.append({"s": E, "t": "量之前，先在記錄本上寫一句：哪些底片不納入？", "key": "rule", "choices": [
		"星點不足五顆的不量；星像拖長或被雲霧蓋住的，不和清楚的平均。",
		"先全部量，看了數字再決定留哪些。",
		"不用先寫，看片子的時候自然知道。",
	]})
	return out


static func judgment_prompt(telegrams: Array, reasons: Array) -> Array:
	return [
		{"s": E, "t": "我們得發電報給倫敦的 Dyson。只有幾個字的空間——你會寫什麼？", "key": "telegram", "choices": telegrams},
		{"s": E, "t": "根據什麼？", "key": "reason", "choices": reasons},
	]


static func cottingham_coda(sim) -> String:
	if sim.drive_rate_checked:
		return "時鐘走得很穩。謝謝你那天替我報秒。"
	if sim.drive_wound:
		return "發條是滿的，可惜沒來得及對時——長一點的曝光，星像都有點拖。"
	return "那天我一個人趕著上發條，沒時間對時。下次我們先把這件事做完。"


# --- M5 totality (Director-owned; docs/design/M5_TOTALITY.md). FICTION. Hindsight and
# facts only: no line may tell the player *when* to expose.

## Cottingham's read of the exposure that just closed. band: clear|mixed|cloud|brief.
static func totality_read(band: String) -> String:
	match band:
		"clear":
			return "Cottingham：「這幾秒雲很薄，我看得見日冕的邊。」"
		"mixed":
			return "Cottingham：「一半在雲裡，一半透了光。」"
		"cloud":
			return "Cottingham：「整段幾乎都在雲後面。」"
		"brief":
			return "Cottingham：「太短了，大概什麼都沒留下。」"
	return ""


## The same read, as the night plate viewer shows it.
static func totality_read_night(band: String) -> String:
	match band:
		"clear":
			return "拍攝時：Cottingham 說雲很薄，看得見日冕。"
		"mixed":
			return "拍攝時：Cottingham 說一半在雲裡。"
		"cloud":
			return "拍攝時：Cottingham 說幾乎整段都在雲後。"
		"brief":
			return "拍攝時：曝光太短。"
	return ""


## An exposure has run 20 s, the longest of the real programme.
static func totality_long(rate_checked: bool) -> String:
	if rate_checked:
		return "Cottingham：「二十秒了。」"
	return "Cottingham：「二十秒了——驅動沒對過時，再久星像會拖長。」"


static func totality_last_plate() -> String:
	return "Eddington：「最後一張了。」"


## Late in totality, plates unused and nothing taken for a while. Facts only.
static func totality_plates_left(n: int) -> String:
	return "Eddington：「還有 %d 張底片。」" % n


## No exposure in the first 45 s: say where to look, never when.
static func totality_first_nudge() -> String:
	return "Eddington：「看太陽周圍那一小片，不是整片天。那裡變薄了就喊。」"
