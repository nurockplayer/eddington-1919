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
]

## How well each telegram fits each evidence class: 2 best, 1 defensible, 0 wrong.
const FIT := {
	"none": {"confirmed": 0, "hopeful": 0, "undecided": 1, "none": 2},
	"favors_e": {"confirmed": 0, "hopeful": 2, "undecided": 1, "none": 0},
	"ambiguous": {"confirmed": 0, "hopeful": 1, "undecided": 2, "none": 0},
	"favors_half": {"confirmed": 0, "hopeful": 1, "undecided": 2, "none": 0},
}

const REASON_FIT := {
	"none": ["nostars", "uncertain"],
	"favors_e": ["measured", "uncertain"],
	"ambiguous": ["uncertain"],
	"favors_half": ["uncertain"],
}


static func grade(sim, telegram_id: String, reason_id: String) -> Dictionary:
	var ev: String = sim.evidence_class()
	var fit: int = FIT[ev][telegram_id]
	var any_usable: bool = sim.plates.any(func(p): return p.usable)
	var any_good: bool = sim.plates.any(func(p): return p.usable and p.quality == "good")
	var reason_ok: bool = reason_id in REASON_FIT[ev]
	if reason_id == "nostars" and any_usable:
		reason_ok = false  # the stars are there, just not measured
	if ev == "none" and telegram_id == "none" and any_usable:
		fit = 0  # usable plates exist, they just weren't measured
	var sel: Dictionary = sim.selection_report()
	var clean: bool = sel.omitted_good.is_empty() and sel.included_poor.is_empty() and sel.included_unusable.is_empty() and not sel.reselected
	var lines: Array[String] = []
	lines.append_array(_telegram_lines(ev, telegram_id, any_usable, any_good, sim))
	lines.append(_reason_line(ev, reason_id, reason_ok))
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


static func _reason_line(ev: String, reason_id: String, ok: bool) -> String:
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
	match reason_id:
		"measured":
			return "你說接近 1.75″——可是看看圖上的誤差，它沒有你說的那麼肯定。"
		"nostars":
			return "可是你的底片上明明有五顆以上的星。"
		_:
			return "你的理由和你寫下的電報不太對得上。"


static func _selection_lines(sel: Dictionary, clean: bool, sim) -> Array[String]:
	var out: Array[String] = []
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
	if clean and sim.included_usable().size() > 0:
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
