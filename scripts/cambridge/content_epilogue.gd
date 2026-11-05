extends RefCounted
class_name CambridgeContentEpilogue
## Conversion arc move D — October 1919, Cambridge, after the Príncipe coda.
## All dialogue is FICTION unless a line marks a recorded fact; Dyson's letter is a
## RECONSTRUCTION and never quotes a document. See docs/PROVENANCE.md and
## docs/research/arc_factcheck_2026-11-06.md.

const CAST = preload("res://scripts/cambridge/cast.gd")
const Content := preload("res://scripts/content.gd")
const Content1917 := preload("res://scripts/cambridge/content_1917.gd")

const A := CAST.MENTOR
const YOU := CAST.YOU


static func intro_caption() -> String:
	return "劍橋，1919 年 10 月\n\n（推測重建）"


static func opening() -> Array:
	return [
		{"s": A, "t": "Greenwich 來信了。Dyson 寫的，在桌上。你先看。"},
	]


## Dyson's letter is a RECONSTRUCTION: the numbers are HISTORICAL_RECORD, the wording
## is not a quotation, and the arrival day is not established.
static func letter() -> Array:
	return [
		{"s": "Dyson 的信（推測重建，非原文）", "t": "Sobral 的底片在 Greenwich 量完了。\n4 吋鏡頭：1.98″ ± 0.12″。\n天體照相儀：約 0.93″；星像模糊，當天的焦距和比例尺可能變了。"},
		{"s": A, "t": "把它們抄到你的圖上。一筆一筆來。"},
	]


static func weight() -> Array:
	return [
		{"s": A, "t": "天體照相儀那組，你怎麼算？", "key": "astro_weight",
			"choices": ["照樣算，一樣重", "先放一邊，但寫明原因（星像糊、比例尺可能變了）",
				"整組丟掉，不用提", "還不能決定，先重量一次"]},
	]


static func weight_reply(choice: int) -> Array:
	match choice:
		0:
			return [{"s": A, "t": "一樣重，平均下來約 1.46″——兩個預測都搆不上。可是一架比例尺可能變了的鏡頭，憑什麼和沒變的一樣重？"}]
		1:
			return [{"s": A, "t": "好。寫明白：星像糊，比例尺可能變了——讓後人可以不同意。Greenwich 那邊也是這麼做的。"}]
		2:
			return [{"s": A, "t": "不行。不提，就是替讀的人決定他不必知道。丟不丟是一回事，藏起來是另一回事。"}]
		3:
			return [{"s": A, "t": "可以。Greenwich 也還在比校驗片。只是十一月不會等你——到時候要有一句話交代。"}]
	return []


## The 1917 page, then Ashby's answer to what this run's evidence did to it.
static func ledger(run: Dictionary, bet_1917: Dictionary, bet_now: Dictionary) -> Array:
	var seq: Array = []
	if not bet_1917.is_empty():
		var page := "Ashby 先生寫的：0.87。\n你寫的：%s（%s）。" % [
			Content.bet_pick_text(int(bet_1917.get("pick", -1))),
			Content.bet_sure_text(int(bet_1917.get("sure", -1)))]
		if int(bet_now.get("pick", -1)) != int(bet_1917.get("pick", -1)):
			page += "\n1919 年你改成：%s。" % Content.bet_pick_text(int(bet_now.get("pick", -1)))
		seq.append({"s": "1917 年的帳本", "t": page})
	seq.append({"s": A, "t": _case_line(run)})
	return seq


## "conceded" / "own_low" / "inconclusive" / "no_value"; static so tests can read it.
static func ledger_case(run: Dictionary) -> String:
	var c: Dictionary = run.get("combined", {})
	var b: Dictionary = run.get("bounds", {})
	if int(c.get("n", 0)) > 0:
		if bool(run.get("clean", false)) and float(b.get("lo", 0.0)) > 0.87:
			return "conceded"
		if float(b.get("hi", 99.0)) < 1.75 and float(b.get("lo", 99.0)) <= 0.87:
			return "own_low"
		return "inconclusive"
	return "no_value"


static func _case_line(run: Dictionary) -> String:
	match ledger_case(run):
		"conceded":
			return "我寫的是 0.87。你的底片和 Sobral 的小鏡頭，都容不下它。……在這件事上，我錯了。"
		"own_low":
			return "你的底片站在我的 0.87 這邊。我不會假裝沒看見。可是 Sobral 的小鏡頭不站——兩地不一致，總得有一邊要解釋。"
		"inconclusive":
			return "你的底片還分不出來。Sobral 的可以。兩個地方、兩套儀器——這比我希望的更難反駁。"
	return "你沒有帶回數值，我也不替你猜。Sobral 的小鏡頭有，而它容不下 0.87。只靠一個地方、一套儀器，我還不想寫下結論。"


## suspect_text: the player's 1917 suspect, or "" if they left none.
static func orrery_talk(suspect_text: String) -> Array:
	var seq: Array = []
	if suspect_text != "":
		seq.append({"s": "太陽系儀", "t": "你在 1917 年最懷疑的是：%s。" % suspect_text})
	seq.append_array([
		{"s": A, "t": "1915 年 11 月，愛因斯坦說他的理論算得出水星那 43 角秒。我那時想：先知道答案再去算，誰都算得對。"},
		{"s": A, "t": "可是光彎多少，是在任何人量之前就寫下的。"},
		{"s": A, "t": "一個是事後的解釋，一個是事先的下注——現在指著同一邊。",
			"key": "click", "choices": ["水星也不再是例外了", "同一個想法，說中兩件不相干的事", "還要更多證據"]},
	])
	return seq


static func click_reply(choice: int) -> Array:
	match choice:
		0:
			return [{"s": A, "t": "是啊。年鑑上那一行，可以闔上了。"}]
		1:
			return [{"s": A, "t": "嗯。這種事，不常有。"}]
		2:
			return [{"s": A, "t": "應該的。下一次日食，還會有人去量。"}]
	return []


static func final_reason() -> Array:
	return [
		{"s": "筆記本", "t": "在筆記本最後寫一句：哪一個證據最讓你改變想法？",
			"key": "final_reason",
			"choices": ["我自己的底片", "Sobral 的 4 吋鏡頭", "兩地一起", "水星和光指向同一邊", "我還沒有改變想法"]},
	]


static func final_reply(choice: int) -> Array:
	if choice == 4:
		return [{"s": A, "t": "那就寫下來。沒有改變，也是一筆紀錄。"}]
	return []


static func close() -> Array:
	return [{"s": A, "t": "11 月 6 日，倫敦開會。"}]


## The 1917 suspect text for a stored index; "" if the player left none.
static func suspect_text(index: int) -> String:
	var choices: Array = Content1917.orrery_suspect_entry().choices
	return str(choices[index]) if index >= 0 and index < choices.size() else ""
