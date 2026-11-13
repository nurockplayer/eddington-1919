extends RefCounted
class_name CambridgeContentEpilogue
## Conversion arc move D — October 1919, Cambridge, after the Príncipe coda.
## All dialogue is FICTION unless a line marks a recorded fact; Dyson's letter is a
## RECONSTRUCTION and never quotes a document. See docs/PROVENANCE.md and
## docs/research/arc_factcheck_2026-11-06.md.

const CAST = preload("res://scripts/cambridge/cast.gd")
const Content := preload("res://scripts/content.gd")
const Content1917 := preload("res://scripts/cambridge/content_1917.gd")

const K := CAST.KIT
const A := CAST.MENTOR
const YOU := CAST.YOU

## The notebook answer, kept as source text so a stored copy stays translatable.
const FINAL_REASON_CHOICES := ["我自己的底片", "Sobral 的 4 吋鏡頭", "兩地一起", "水星和光指向同一邊", "我還沒有改變想法"]


static func intro_caption() -> String:
	return L.t("劍橋，1919 年 10 月\n\n（推測重建）")


static func opening() -> Array:
	return [
		{"s": A, "t": L.t("Greenwich 來信了。Dyson 寫的，在桌上。你先看。")},
	]


## Story audit D6: Kit's October reunion. FICTION throughout; the six-week boat is
## HISTORICAL_RECORD (story_factcheck §7). kit_line is the stored "給 Kit：…" workbook line.
static func kit_reunion(kit_first: int, bond_tone: String, sky_promise: int, kit_line: String) -> Array:
	var seq: Array = [
		{"s": K, "t": L.t("你瘦了。")},
		{"s": K, "t": L.t("說吧。你決定好要先跟我說的那一句。")},
	]
	var said := kit_line.trim_prefix(L.t("給 Kit：%s") % "")
	seq.append({"s": YOU, "t": said if said != "" else L.t("……我回來了。")})
	match kit_first:
		0: seq.append({"s": K, "t": L.t("那我要聽。從雲開始講。")})
		1: seq.append({"s": K, "t": L.t("範圍很寬，也是一個答案。你以前不會這樣說。")})
		2: seq.append({"s": K, "t": L.t("那就慢慢告訴我。今天晚上很長。")})
	seq.append({"s": "", "t": L.t("（你把工作簿遞過去。Kit 翻到最後一頁，看了很久。）")})
	seq.append({"s": K, "t": L.t("這是你自己抬頭看到的。好。")})
	if sky_promise == 0:
		seq.append({"s": K, "t": L.t("你要我寫這裡變了什麼。我寫了。")})
	else:
		seq.append({"s": K, "t": L.t("你沒要我寫，我還是記下來了。")})
	seq.append({"s": K, "t": L.t("Trumpington 街的路燈又亮了。那張空桌子，坐了一個什麼都要加糖的一年級生。")})
	seq.append({"s": K, "t": L.t("那顆變星，我量到分鐘了。它一次也沒有遲到。遲到的是我。")})
	seq.append({"s": "", "t": L.t("（桌角有一個沒寄出的信封，寫著你的名字。）")})
	seq.append({"s": K, "t": L.t("那是給你的。船要走六個星期，你會比它先到家。所以我沒寄。")})
	if bond_tone == "close":
		seq.append({"s": K, "t": L.t("……裡面寫了什麼，以後再說。不是今晚。")})
	else:
		seq.append({"s": K, "t": L.t("反正裡面寫的，剛剛都說了。省一張郵票。")})
	return seq


## Story audit D8: three objects on the desk, no ledger. FICTION.
static func tableau(run: Dictionary) -> Array:
	var line := L.t("放著吧。總會有人想看，你是怎麼得到這個數字的。") if ledger_case(run) == "conceded" else L.t("放著吧。總會有人想來爭。")
	return [{"s": A, "t": line}, {"s": K, "t": L.t("走吧，到外面去。你說過要指給我看的。")}]


static func tableau_caption() -> String:
	return L.t("底片。放大鏡。那一頁。")


## Dyson's letter is a RECONSTRUCTION: the numbers are HISTORICAL_RECORD, the wording
## is not a quotation, and the arrival day is not established.
static func letter() -> Array:
	return [
		{"s": L.t("Dyson 的信（推測重建，非原文）"), "t": L.t("Sobral 的底片在 Greenwich 量完了。\n4 吋鏡頭：1.98″ ± 0.12″。\n天體照相儀：約 0.93″；星像模糊，當天的焦距和比例尺可能變了。")},
		{"s": A, "t": L.t("把它們抄到你的圖上。一筆一筆來。")},
	]


static func weight() -> Array:
	return [
		{"s": A, "t": L.t("天體照相儀那組，你怎麼算？"), "key": "astro_weight",
			"choices": [L.t("照樣算，一樣重"), L.t("先放一邊，但寫明原因（星像糊、比例尺可能變了）"),
				L.t("整組丟掉，不用提"), L.t("還不能決定，先重量一次")]},
	]


static func weight_reply(choice: int) -> Array:
	match choice:
		0:
			return [{"s": A, "t": L.t("一樣重，平均下來約 1.46″。可是這兩組自己就差了一倍，平均只是把分歧藏起來。再說，一架比例尺可能變了的鏡頭，憑什麼和沒變的一樣重？")}]
		1:
			return [{"s": A, "t": L.t("好。寫明白：星像糊，比例尺可能變了——讓後人可以不同意。Greenwich 那邊也是這麼做的。")}]
		2:
			return [{"s": A, "t": L.t("不行。不提，就是替讀的人決定他不必知道。丟不丟是一回事，藏起來是另一回事。")}]
		3:
			return [{"s": A, "t": L.t("可以。Greenwich 也還在比校驗片。只是十一月不會等你——到時候要有一句話交代。")}]
	return []


## The 1917 page, then Ashby's answer to what this run's evidence did to it.
static func ledger(run: Dictionary, bet_1917: Dictionary, bet_now: Dictionary) -> Array:
	var seq: Array = []
	if not bet_1917.is_empty():
		var page := L.t("Ashby 先生寫的：0.87。\n你寫的：%s（%s）。") % [
			Content.bet_pick_text(int(bet_1917.get("pick", -1))),
			Content.bet_sure_text(int(bet_1917.get("sure", -1)))]
		if int(bet_now.get("pick", -1)) != int(bet_1917.get("pick", -1)):
			page += L.t("\n1919 年你改成：%s。") % Content.bet_pick_text(int(bet_now.get("pick", -1)))
		seq.append({"s": L.t("1917 年的帳本"), "t": page})
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
			return L.t("我寫的是 0.87。你的底片和 Sobral 的小鏡頭，都容不下它。……在這件事上，我錯了。")
		"own_low":
			return L.t("你的底片站在我的 0.87 這邊。我不會假裝沒看見。可是 Sobral 的小鏡頭不站——兩地不一致，總得有一邊要解釋。")
		"inconclusive":
			return L.t("你的底片還分不出來。Sobral 的可以。一地分得出，一地還不能——所以我還不想只聽一邊，也不能假裝沒聽見。")
	return L.t("你沒有帶回數值，我也不替你猜。Sobral 的小鏡頭有，而它容不下 0.87。只靠一個地方、一套儀器，我還不想寫下結論。")


## suspect_text: the player's 1917 suspect, or "" if they left none.
## mercury_mark: the player's 1917 orrery note on Mercury (0 or 1), or -1 for none.
static func orrery_talk(suspect_text: String, mercury_mark := -1) -> Array:
	var seq: Array = []
	# HISTORICAL_RECORD (factcheck claim 3 and Ashby's line below): Einstein's 1915 result; 43″ is the residual. FICTION: the player's note.
	seq.append({"s": L.t("年鑑・水星（1919 年 10 月補記）"), "t": L.t("照愛因斯坦 1915 年的算法，水星的近日點每一百年要多走約 43 角秒——正好是年鑑上算完其他行星之後，剩下的那一點。"),
		"key": "mercury_1919", "choices": [L.t("對得上"), L.t("對不上")],
		"then": [[], [{"s": L.t("太陽系儀"), "t": L.t("再看一眼：年鑑上剩下的是 43 角秒，他算出來的也是。")}]]})
	if mercury_mark == 0 or mercury_mark == 1:
		seq.append({"s": L.t("太陽系儀"), "t": L.t("[color=#b8ad98]兩年前你在這一行旁邊寫的是：%s。[/color]") % [L.t("對得上"), L.t("對不上")][mercury_mark]})
	if suspect_text != "":
		seq.append({"s": L.t("太陽系儀"), "t": L.t("你在 1917 年最懷疑的是：%s。") % suspect_text})
	seq.append_array([
		{"s": A, "t": L.t("1915 年 11 月，愛因斯坦說他的理論算得出水星那 43 角秒。消息傳到劍橋時，我想：先知道答案再去算，誰都算得對。")},
		# HISTORICAL_RECORD: Vulcan, Seeliger, Hall (factcheck claim 12). FICTION: Ashby's judgement.
		{"s": A, "t": L.t("我們找過的那些說法——看不見的行星、太陽旁的物質、改一點引力的規則——都只為了水星，沒有一個能讓星光彎得像愛因斯坦說的那麼多。")},
		{"s": A, "t": L.t("可是光彎多少，是在任何人量之前就寫下的。")},
		{"s": A, "t": L.t("一個是事後的解釋，一個是事先的下注——現在指著同一邊。"),
			"key": "click", "choices": [L.t("水星也不再是例外了"), L.t("同一個想法，說中兩件不相干的事"), L.t("還要更多證據")]},
	])
	return seq


static func click_reply(choice: int) -> Array:
	match choice:
		0:
			return [{"s": A, "t": L.t("是啊。年鑑上那一行，可以闔上了。")}]
		1:
			return [{"s": A, "t": L.t("嗯。這種事，不常有。")}]
		2:
			return [{"s": A, "t": L.t("應該的。下一次日食，還會有人去量。")}]
	return []


## FICTION: the player's own revision goes in the ledger; Ashby only witnesses it.
static func october_bet() -> Array:
	return [{"s": L.t("1917 年的帳本"), "t": L.t("帳本翻到新的一行，Ashby 先生把筆推過來。\n1919 年 10 月，你寫："),
		"key": "bet_oct", "choices": [L.t("零"), "0.87", "1.75", L.t("說不準")]}]


## FICTION. The pick is never corrected; Ashby only notices whether this page differs
## from the one the player wrote before measuring.
static func october_bet_reply(pick: int, bet_now: Dictionary) -> Array:
	if bet_now.is_empty():
		return [{"s": A, "t": L.t("寫下來，比記在心裡好。")}]
	if pick != int(bet_now.get("pick", -1)):
		return [{"s": A, "t": L.t("改了。寫下來，比記在心裡好。")}]
	return [{"s": A, "t": L.t("沒改。那也寫下來——連日期一起。")}]


static func final_reason() -> Array:
	return [
		{"s": L.t("筆記本"), "t": L.t("在筆記本最後寫一句：哪一個證據最讓你改變想法？"),
			"key": "final_reason",
			"choices": FINAL_REASON_CHOICES.map(func(c): return L.t(c)),
			"sources": FINAL_REASON_CHOICES},
	]


## FICTION. The answer is the player's and is never corrected; Ashby only says what
## their own run can and cannot carry. Bet pick 2 is 1.75 in mentor_dyson's ledger.
static func final_reply(choice: int, run := {}, bet_1917 := {}, bet_now := {}) -> Array:
	if choice == 4:
		# FICTION: the ledger and the notebook disagree; both pages stay.
		if run.has("bet_oct") and int(run.bet_oct) != int(bet_now.get("pick", -1)) and not bet_now.is_empty():
			return [{"s": A, "t": L.t("帳上你改了，這裡寫沒有。兩句都留著，讓後人來問你。")}]
		return [{"s": A, "t": L.t("那就寫下來。沒有改變，也是一筆紀錄。")}]
	if choice < 0:
		return []
	if choice == 0:
		match ledger_case(run):
			"own_low":
				return [{"s": A, "t": L.t("你的底片站在我這邊。你要是憑它們改了想法，改的方向，和 Sobral 的小鏡頭相反。寫清楚，別讓後人替你猜。")}]
			"inconclusive":
				return [{"s": A, "t": L.t("你的底片還分不出 0.87 和 1.75，剛才我們都看見了。讓你改變想法的，也許不是那個數字，是你親手量過它。那就照這樣寫。")}]
			"no_value":
				return [{"s": A, "t": L.t("你沒有帶回數值。你要寫底片，就寫明白：改變你的是拍它們的那幾分鐘，不是數字。")}]
	if int(bet_1917.get("pick", -1)) == 2:
		if run.has("bet_oct") and int(run.bet_oct) != 2:
			return [{"s": A, "t": L.t("你在 1917 年寫了 1.75，今天這一行不是。寫清楚，是什麼讓你改的。")}]
		if int(bet_now.get("pick", -1)) != 2:
			return [{"s": A, "t": L.t("你在 1917 年寫了 1.75，量之前又改了。所以你改變想法，不只這一次。")}]
		return [{"s": A, "t": L.t("你在 1917 年就寫了 1.75。那你改變的不是數字——是你憑什麼相信它。")}]
	return [{"s": A, "t": L.t("那就這麼寫。")}]


static func close() -> Array:
	return [{"s": A, "t": L.t("11 月 6 日，倫敦開會。")}]


## The 1917 suspect text for a stored index; "" if the player left none.
static func suspect_text(index: int) -> String:
	var choices: Array = Content1917.orrery_suspect_entry().choices
	return str(choices[index]) if index >= 0 and index < choices.size() else ""
