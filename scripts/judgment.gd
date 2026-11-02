extends RefCounted
## Grades the player's cable to England against the evidence they actually
## produced, and builds Eddington's response. Dialogue is FICTION (dramatised);
## it aims to keep the real people's documented caution and must not put later
## certainty into their mouths.

const TELEGRAMS := [
	{"id": "confirmed", "text": "ECLIPSE SPLENDID. EINSTEIN CONFIRMED."},
	{"id": "hopeful", "text": "THROUGH CLOUD. HOPEFUL."},
	{"id": "undecided", "text": "THROUGH CLOUD. STARS FEW. RESULT UNDECIDED."},
	{"id": "none", "text": "CLOUD. NO RESULTS."},
]

const REASONS := [
	{"id": "measured", "text": "量得的偏折較接近 1.75″，而且有足夠星點的底片支持。"},
	{"id": "uncertain", "text": "底片少、誤差大；需要 Sobral 的結果與回國後的完整量測。"},
	{"id": "corona", "text": "日冕那麼清楚——我們一定成功了。"},
	{"id": "nostars", "text": "雲太厚，底片上沒有足夠的星點可以量。"},
	{"id": "trailed", "text": "星像拖長了——走速沒校過。數值偏低，可能是儀器，不是星。"},
]

## How well each telegram fits each evidence class: 2 best, 1 defensible, 0 wrong.
const FIT := {
	"none": {"confirmed": 0, "hopeful": 0, "undecided": 1, "none": 2},
	"favors_e": {"confirmed": 0, "hopeful": 2, "undecided": 1, "none": 0},
	"ambiguous": {"confirmed": 0, "hopeful": 1, "undecided": 2, "none": 0},
	"favors_half": {"confirmed": 0, "hopeful": 1, "undecided": 2, "none": 0},
}

## A single plate at least this long could have been two usable plates.
const SPLIT_MIN_S := 14.0

const REASON_FIT := {
	"none": ["nostars", "uncertain"],
	"favors_e": ["measured", "uncertain"],
	"ambiguous": ["uncertain"],
	"favors_half": ["uncertain"],
}


static func interval_truth(sim) -> int:
	var c: Dictionary = sim.combined()
	if c.n == 0:
		return -1
	var contains_e: bool = absf(c.value - sim.EINSTEIN) <= 2 * c.sigma
	var contains_half: bool = absf(c.value - sim.HALF) <= 2 * c.sigma
	if contains_e and contains_half:
		return 0
	if contains_e:
		return 1
	if contains_half:
		return 2
	return 3


static func reasons_for(sim) -> Array:
	var reasons := REASONS.duplicate(true)
	var c: Dictionary = sim.combined()
	if c.n > 0:
		reasons[0].text = "量得 %.2f″ ± %.2f″（%d 張）：兩倍誤差之內容得下 1.75″，也排除了 0.87″。" % [c.value, c.sigma, c.n]
		reasons[1].text = "量得 %.2f″ ± %.2f″，誤差還太大；需要 Sobral 的結果與回國後的完整量測。" % [c.value, c.sigma]
		var trail_sum := 0.0
		for p in sim.included_usable():
			trail_sum += p.trail
		reasons[4].text = "星像平均拖長 %.2f——走速沒校過。數值偏低，可能是儀器，不是星。" % (trail_sum / c.n)
	return reasons


static func trailed_case(sim) -> bool:
	if sim.drive_rate_checked or sim.evidence_class() not in ["favors_half", "ambiguous"]:
		return false
	# Trailing biases the fit low; a value at or above 1.75″ is not that bias.
	if sim.combined().value >= sim.EINSTEIN:
		return false
	return _mean_trail(sim) >= 0.35


static func _mean_trail(sim) -> float:
	var plates: Array = sim.included_usable()
	if plates.is_empty():
		return 0.0
	var trail_sum := 0.0
	for p in plates:
		trail_sum += p.get("trail", 0.0)
	return trail_sum / plates.size()


static func grade(sim, telegram_id: String, reason_id: String) -> Dictionary:
	var ev: String = sim.evidence_class()
	var fit: int = FIT[ev][telegram_id]
	var any_usable: bool = sim.plates.any(func(p): return p.usable)
	var any_good: bool = sim.plates.any(func(p): return p.usable and p.quality == "good")
	var reason_ok: bool = reason_id in REASON_FIT[ev]
	if reason_id == "trailed":
		reason_ok = trailed_case(sim)
	if reason_id == "nostars" and any_usable:
		reason_ok = false  # the stars are there, just not measured
	if ev == "none" and telegram_id == "none" and any_usable:
		fit = 0  # usable plates exist, they just weren't measured
	var sel: Dictionary = sim.selection_report()
	var clean: bool = sel.omitted_good.is_empty() and sel.included_poor.is_empty() and sel.included_unusable.is_empty() and not sel.reselected
	var lines: Array[String] = []
	lines.append_array(_telegram_lines(ev, telegram_id, any_usable, any_good, sim))
	lines.append(_reason_line(ev, reason_id, reason_ok, sim))
	lines.append_array(_selection_lines(sel, clean, sim))
	var title := _title(ev, telegram_id, fit, reason_ok, clean, any_usable)
	return {
		"evidence": ev, "fit": fit, "reason_ok": reason_ok, "clean": clean,
		"score": fit + (1 if reason_ok else 0) + (1 if clean else 0),
		"lines": lines, "title": title,
	}


static func _telegram_lines(ev: String, t: String, any_usable: bool, any_good: bool, sim) -> Array[String]:
	var c: Dictionary = sim.combined()
	var out: Array[String] = []
	match t:
		"confirmed":
			if ev == "favors_e":
				out.append("我和你一樣懷著希望。可是一夜、幾張底片、在帳篷裡量的數字——這還不是證明。")
			else:
				out.append("「證實」？我們手上的星像撐不起這兩個字。")
			out.append("完整的量測要回國後才做得完，比例尺和校驗片都還得一張張比；Sobral 的結果我們也還不知道。電報發出去就收不回來了。")
		"hopeful":
			match ev:
				"favors_e":
					out.append("「有希望」——是的。它說了我們看到的，也沒有說得比看到的更多。")
				"none":
					out.append("希望什麼呢？我們沒有一張量得出結果的底片。這兩個字會讓倫敦誤會。")
				"favors_half":
					out.append("「有希望」？我們量到的數字其實偏向較小的偏折。這個詞會讓人以為我們看到了別的東西。")
				_:
					out.append("「有希望」可以接受，但它是個寬鬆的詞。我們的數字其實還在兩種預測之間搖擺。")
		"undecided":
			match ev:
				"favors_e":
					out.append("謹慎沒有錯。只是——我們的好底片確實指向較大的偏折，不必把它說得比實際更弱。")
				"none":
					out.append("說得誠實。雲擋住了大部分星光，我們不假裝。")
				"favors_half":
					out.append("對。這幾張偏向較小的偏折，可是片子少、誤差大，還不能說什麼。我們照實說。")
				_:
					out.append("對。誤差範圍同時容得下兩種答案。我們照實說。")
		"none":
			if any_usable:
				if any_good:
					out.append("沒有結果？你手上就有星點清楚的底片。雲很厚，但不是什麼都沒留下。")
				else:
					out.append("沒有結果？你手上還有可量的底片，只是星像拖長或被雲霧蓋住；不是什麼都沒留下。")
			else:
				out.append("……是的。很遺憾，但這是真的。至少我們沒有讓雲替我們說謊。")
	if c.n > 0:
		out.append("（你的合併估計：%.2f″ ± %.2f″，%d 張底片。）" % [c.value, c.sigma, c.n])
	return out


static func _reason_line(ev: String, reason_id: String, ok: bool, sim) -> String:
	if reason_id == "corona":
		return "日冕很美，我也看了一眼。但美不是量測——量測在底片上。"
	if ok:
		match reason_id:
			"measured":
				return "你的理由站在底片上，這很好。"
			"uncertain":
				return "你記得我們只是其中一站。Dyson 會比較兩地的結果。"
			"nostars":
				return "你按星點數判斷，而不是按心情。"
			"trailed":
				return "你分得出哪些偏差是我們自己帶進去的。Cottingham 會記得這句。"
	match reason_id:
		"measured":
			return "你說接近 1.75″——可是看看圖上的誤差，它沒有你說的那麼肯定。"
		"nostars":
			return "可是你的底片上明明有五顆以上的星。"
		"trailed":
			if sim.drive_rate_checked:
				if _mean_trail(sim) >= 0.35:
					return "走速校過了。星像還是拖長，是曝光太久，不是走速沒校。"
				return "走速校過了，星像沒有拖。別把不合期望的數字推給儀器。"
			# Unchecked drive: say what the measured plates actually show.
			if ev == "none":
				return "還沒有量出任何數字，談不上偏低，也就輪不到儀器來解釋。"
			if _mean_trail(sim) >= 0.35:
				return "星像確實拖長了——可是拖長只會把數字拉低，這個結果並沒有偏低。"
			if ev in ["favors_half", "ambiguous"]:
				return "你量的這幾張星像沒有拖長——偏差不是走速帶進來的。別替不合期望的結果先找好理由。"
			return "數字沒有偏到需要儀器來解釋。別替不合期望的結果先找好理由。"
		_:
			return "你的理由和你寫下的電報不太對得上。"


static func _selection_lines(sel: Dictionary, clean: bool, sim) -> Array[String]:
	var out: Array[String] = []
	var rule: String = sim.get("rule_id") if sim.get("rule_id") != null else ""
	match rule:
		"strict":
			# The rule bars plates under five stars, and poor plates only beside a clear one.
			var with_good: bool = sim.plates.any(func(p): return p.included and p.quality == "good")
			var violations: Array = (sel.included_poor if with_good else []) + sel.included_unusable
			if not violations.is_empty():
				out.append("你量之前寫的是：星點不足五顆的不量，拖長或起霧的不和好片平均。第 %s 號違反了你自己寫下的規則。" % _nums(violations))
			elif clean and sim.included_usable().size() > 0:
				out.append("你照著量之前寫下的規則選片。結果合不合期望，都沒有人能說你是看了數字才挑的。")
		"after":
			out.append("『看了數字再決定』——這正是規則要先寫的原因。數字一出來，人人都想留下自己喜歡的那幾張。")
		"none":
			out.append("沒有先寫下的規則，事後就說不清為什麼留這張、丟那張。")
	if sim.plates.is_empty():
		return out
	if not sel.omitted_good.is_empty():
		out.append("第 %s 號底片的星像很清楚，你沒有量它。若它的數字不合我們的期望，那更應該量。" % _nums(sel.omitted_good))
	if not sel.included_poor.is_empty():
		out.append("第 %s 號的星像拖長了或被雲霧蓋住。和好片一起平均，會把誤差帶進結論。" % _nums(sel.included_poor))
	if not sel.included_unusable.is_empty():
		out.append("第 %s 號上連五顆星都數不到，量不出任何東西。選片要看星像，不是看張數。" % _nums(sel.included_unusable))
	if sel.reselected:
		out.append("你看過數值之後又改了選擇。也許有理由——但必須寫下：排除了哪一張、為什麼、在看到結果之前還是之後。")
	var good: Array = sim.plates.filter(func(p): return p.included and p.quality == "good")
	if good.size() >= 2:
		# The good plates' own weighted mean: poor plates must not decide whether
		# good ones agree. Each plate is held to its own 2σ, so more agreeing
		# plates (a smaller combined σ) cannot turn agreement into disagreement.
		var wsum := 0.0
		var vsum := 0.0
		for p in good:
			var w: float = 1.0 / (p.sigma * p.sigma)
			wsum += w
			vsum += w * p.value
		var mean := vsum / wsum
		if good.all(func(p): return absf(p.value - mean) <= 2.0 * p.sigma):
			var count := "兩張" if good.size() == 2 else "這 %d 張" % good.size()
			out.append("第 %s 號各自量，數字彼此對得上。%s互相印證，比一張長片更難被說成巧合。" % [_nums(good.map(func(p): return p.number)), count])
	elif good.size() == 1:
		out.append("只有一張好片——一張底片只能提出問題，還不能回答。")
		# Two usable plates need ~4.5 s of clear sky each plus the 4 s change, so
		# only a long single plate (≥ 14 s) could have been split.
		if not sim.read_plan and good[0].get("duration", 0.0) >= SPLIT_MIN_S:
			out.append("曝光計畫上寫著：晴窗有十四秒以上時，拆成兩張短片勝過一張長片。")
	if rule != "strict" and clean and sim.included_usable().size() > 0:
		out.append("你先按星像品質選片，再看數值。這個順序比任何一個數字都重要。")
	return out


static func _nums(arr: Array) -> String:
	return "、".join(arr.map(func(n): return str(n)))


static func _title(ev: String, t: String, fit: int, reason_ok: bool, clean: bool, any_usable: bool) -> String:
	if t == "confirmed":
		return "過早的宣告"
	if t == "none" and any_usable:
		return "被丟下的星光"
	if fit == 2 and reason_ok and clean:
		match t:
			"hopeful":
				return "雲層之後的希望"
			"undecided":
				return "誠實的不確定"
			"none":
				return "雲沒有讓步"
	if fit >= 1:
		return "不完整的判斷"
	return "與證據相左"
