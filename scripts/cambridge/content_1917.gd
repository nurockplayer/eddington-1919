extends RefCounted
class_name CambridgeContent1917
## Cambridge 1917 prologue — all dialogue and examine text.
## Written by the Game Director (Opus 5.5) as a PROPOSAL within the Owner-approved structure
## (Notion Narrative Bible §§3B–3J, 3O). Names are placeholders (scripts/cambridge/cast.gd);
## no gendered pronouns for the protagonist or Kit. Every line is FICTION (dramatised) unless
## the montage marks it HISTORICAL; see docs/PROVENANCE.md.

const CAST = preload("res://scripts/cambridge/cast.gd")

const K := CAST.KIT
const A := CAST.MENTOR
const E := CAST.EDDINGTON
const YOU := CAST.YOU


static func intro_caption() -> String:
	return "劍橋天文台・1917 年 10 月\n（重建場景）"


static func opening() -> Array:
	return [
		{"s": K, "t": "你的茶。最後一點糖我放進去了——別問我從哪裡弄來的。"},
		{"s": K, "t": "%s九點前要 14 號星場的抄錄圖。說是「核對一下就好」。" % A},
		{"s": K, "t": "「核對一下就好。」這句話我已經聽了三年。"},
		{"s": K, "t": "底片已經擺在看片台上，抄錄圖也在旁邊。我這邊還有四十張變星底片要量——你負責星星，我負責……也是星星。",
			"key": "open", "choices": ["「那你的糖呢？」", "「四十張？今晚？」", "（點點頭，走向看片台）"],
			"then": [
				[{"s": K, "t": "我喝不慣甜的。"}, {"s": K, "t": "……好吧，喝得慣。快去。"}],
				[{"s": K, "t": "今晚十張，明晚十張。等戰爭結束，大概就量完了。"}],
				[],
			]},
	]


static func kit_guess() -> Array:
	return [
		{"s": K, "t": "讓我看看。"},
		{"s": K, "t": "……一顆都對不上？這不是差一點，是完全不像。"},
		{"s": K, "t": "會不會根本不是同一片天？拿錯了底片，或是記錯了日子。架上有那年的觀測日誌，查一下編號。"},
		{"s": K, "t": "我不是說抄錄的人亂畫。那是個來幫忙的學生，1915 年春天就從軍去了。那年走的人，都走得很急。"},
	]


## Progress-keyed help from Kit. state: clues (log, label_mirrored, arrow_tilted, residual)
## plus aligned, residual_found, kit_checked, report_done, viewer_opens.
static func kit_talk(state: Dictionary) -> Array:
	if state.get("report_done", false):
		return [{"s": K, "t": "交上去了？……比我想的快。先生看紙的時候，眉毛會先動。你等著看。"}]
	if state.get("viewer_opens", 0) == 0:
		return [{"s": K, "t": "看片台在桌子中間。把抄錄圖疊到底片上，就知道對不對得上。"}]
	if not state.get("log", false) and not state.get("aligned", false):
		return [{"s": K, "t": "我還是覺得先查日誌，就在架子上。要是連編號都不一樣，我們就不用傷腦筋了。"}]
	if not state.get("label_mirrored", false) and not state.get("aligned", false):
		return [
			{"s": K, "t": "日誌說是同一張？那就怪了。"},
			{"s": K, "t": "你仔細看過抄錄圖角落那個「14」嗎？我總覺得那兩個數字……有點彆扭。"},
		]
	if not state.get("aligned", false):
		return [
			{"s": K, "t": "字是反的——那整張圖大概也是反的。把描圖紙翻過來試試。"},
			{"s": K, "t": "翻過來以後，要是那些差異箭頭都朝同一個方向繞，就是整張紙被輕輕轉了一下。"},
		]
	if not state.get("arrow_tilted", false):
		return [{"s": K, "t": "轉一點就對上了。可是為什麼要轉？底片的藥膜面上應該有鉛筆記號，告訴我們北邊在哪裡。"}]
	if not state.get("residual", false):
		return [{"s": K, "t": "還剩一個點沒著落。點它一下，用放大鏡看看底片上那個位置。"}]
	return [{"s": K, "t": "去寫吧，筆記本在桌上。我在量我的變星——它一個月會暗下去一次，我想知道它是不是每次都一樣準時。"}]


## Played by the director the first time the player talks to Kit after aligning the copy.
static func kit_double_check() -> Array:
	return [
		{"s": K, "t": "對上了？先別告訴我怎麼對的。讓我從頭自己對一次——兩個人各自對出同一個結果，比一個人對兩次可靠。"},
		{"s": K, "t": "……"},
		{"s": K, "t": "翻面，再轉三度多一點。我也是這樣。"},
		{"s": K, "t": "多出來那一點，我也找不到對應的星。底片上那裡只有一點點白——可能是很暗的星，也可能只是藥膜的瑕疵。"},
		{"s": K, "t": "一張底片判斷不了。要另一張同一片天的底片才知道。"},
		{"s": K, "t": "記得寫上是兩個人各自對的。不是為了我——是為了下一個看這張紙的人。"},
	]


static func examine(id: String) -> Array:
	match id:
		"logbook":
			return [
				{"s": "1915 年觀測日誌", "t": "「3 月 9 日。14 號底片，御夫座一帶，曝光 20 分鐘，天清。」"},
				{"s": "1915 年觀測日誌", "t": "同一行的邊上有鉛筆字：「已抄錄，見星圖櫃。」筆跡和抄錄圖上的一樣。\n[color=#b8ad98]——是同一張底片、同一片天。[/color]"},
			]
		"empty_desk":
			return [{"s": "空桌子", "t": "這張桌子空著，椅子推得整整齊齊。戰爭開始以後，天文台少了好幾個人。"}]
		"letter":
			return [{"s": "信", "t": "一封從倫敦寄來的公事信：「本坊目前全力承接軍需光學件，貴台委託之鏡片恐須延至明年。」\n信紙邊上有人用鉛筆寫了一個字：「又」。"}]
		"window":
			return [{"s": "窗", "t": "雨打在玻璃上。簾子拉下了一半——戰時有燈火的規定，天黑以後，燈光不能明晃晃地透出窗外。"}]
		"measuring_machine":
			return [{"s": "量測儀", "t": "把底片夾上去，轉動螺旋，一次讀一顆星的位置。讀數比肉眼能分辨的細得多。\n今晚用不到它——今晚只需要看片台和眼睛。"}]
		"fire":
			return [{"s": "爐火", "t": "爐火很小。煤也得省著用。"}]
		"clock":
			return [{"s": "天文鐘", "t": "這個房間裡最準的東西。它從不爭辯，只是一秒一秒地走。"}]
		"cabinet":
			return [{"s": "底片櫃", "t": "淺淺的抽屜，一格一張底片。每一張都有編號、日期和墨水寫的備註。\n這裡沒有一張底片被丟掉過。"}]
		"kit_ledger":
			return [{"s": "%s的帳簿" % K, "t": "同一顆變星，一行一行的亮度估計，字跡工整得近乎固執。\n最新一頁的角落，畫著一個很小的問號。"}]
		"orrery":
			# Issue #37 loop 1 (proposal). HISTORICAL_RECORD: Neptune found 1846 from Le Verrier's
			# prediction; Mercury's unexplained perihelion advance about 43″/century (Le Verrier 1859,
			# Newcomb 1882/1895); intra-Mercurial planet searches never confirmed.
			return [
				{"s": "太陽系儀", "t": "黃銅做的小太陽系，發條帶著水星、金星、地球和火星各走各的路。\n照牛頓的引力算，行星兩百多年來幾乎都準時到場——海王星甚至是先在紙上算出來，才在望遠鏡裡找到的。"},
				{"s": "太陽系儀", "t": "只有水星不太聽話。把其他行星的拉扯全都算進去，它的近日點每一百年還多往前挪了大約 43 角秒——差不多是一百多公尺外一枚硬幣的寬度。\n有人照海王星的先例，去找一顆更靠近太陽的行星，始終沒有確認找到。也有人懷疑是別的地方出了錯。"},
				{"s": "太陽系儀", "t": "這台小機器的軌道是齒輪定死的，演不出那 43 角秒。\n[color=#b8ad98]——最可靠的算法，也留著一個對不上的小數字。[/color]"},
			]
		"notebook_before":
			return [{"s": "你的工作筆記", "t": "等核對完，就在這裡寫下結果。"}]
	return []


static func viewer_feedback(id: String) -> String:
	match id:
		"first_view":
			return "抄錄圖畫在描圖紙上。拖動它疊到底片上，看看星點能不能重合。"
		"unflipped_mismatch":
			return "疊上去……一顆都對不上。"
		"label_mirrored":
			return "抄錄圖角落的「14」是反的，像在鏡子裡看到的。那個編號是用鉛筆寫在底片藥膜面上的——抄錄的人，是隔著玻璃那一面描的嗎？"
		"arrow_tilted":
			return "藥膜面上有一支鉛筆畫的北向箭頭——和玻璃邊緣不平行，斜了三度左右。抄錄圖上的北，卻是貼著紙邊畫的。"
		"first_flip":
			return "翻過來了。大部分的點靠近了，可是差異箭頭全都朝同一個方向繞。"
		"aligned":
			return "十七個點重合了。還有一個沒對上。"
		"residual":
			return "放大鏡下，底片上那個位置只有一點極淡的白。可能是一顆很暗的星，也可能是藥膜上的瑕疵——光憑這一張，分不出來。"
	return ""


static func viewer_hint(state: Dictionary) -> String:
	if not state.get("aligned", false):
		if state.get("label_mirrored", false):
			return "字是反的。如果整張描圖紙也是反的呢？試試［翻面］，再用［⟲］［⟳］或 Q／E 慢慢轉。"
		return "看看抄錄圖角落的編號，再看看底片上用鉛筆寫的那個。"
	if not state.get("arrow_tilted", false):
		return "為什麼要轉？底片上鉛筆畫的北向箭頭，和玻璃邊緣平行嗎？"
	if not state.get("residual", false):
		return "還有一個點沒對上。點它一下。"
	return "核對完了。關上看片台，到筆記本上寫下結果。"


## Report sheet rows: {id, text, needs?(row), options:[{id, text, needs?}]}.
## The residual row is hidden until the residual is found and then records "not_found".
## kit_credited is a single checkbox option "credited".
static func report_rows() -> Array:
	return [
		{"id": "cause", "text": "差異的原因", "options": [
			{"id": "both", "text": "抄錄時底片翻了面，又放斜了約 3 度", "needs": ["label_mirrored", "arrow_tilted"]},
			{"id": "mirror", "text": "抄錄時底片翻了面（鏡像）", "needs": ["label_mirrored"]},
			{"id": "tilt", "text": "底片放斜了約 3 度", "needs": ["arrow_tilted"]},
			{"id": "unknown", "text": "原因還沒查明"},
			{"id": "accuse", "text": "抄錄的人草率，或是憑空編造"},
		]},
		{"id": "original", "text": "原來那張抄錄圖", "options": [
			{"id": "keep", "text": "保留原圖，旁邊附上更正與理由"},
			{"id": "redraw", "text": "重畫一張乾淨的，舊的作廢"},
		]},
		{"id": "residual", "text": "沒對上的那一點", "needs": ["residual"], "options": [
			{"id": "unresolved", "text": "標記「未解決：需要另一張同天區的底片」"},
			{"id": "delete", "text": "當成墨漬，刪掉"},
			{"id": "new_object", "text": "寫上「可能是新天體」"},
		]},
		{"id": "kit_credited", "text": "複核", "options": [
			{"id": "credited", "text": "註明：%s 獨立複核過一次" % K, "needs": ["kit_checked"]},
		]},
	]


## report: {cause, original, residual, kit_credited, kit_checked}. If the sheet accuses the copyist, the
## mentor asks for another look via key "revise_report" (0 = reopen the sheet, 1 = submit as is).
static func mentor_review(report: Dictionary) -> Array:
	var seq: Array = [
		{"s": A, "t": "這種天氣，連貓都不出門。"},
		{"s": A, "t": "%s。還有你。——14 號？讓我看看。" % K},
	]
	match report.get("cause", "unknown"):
		"accuse":
			seq.append({"s": A, "t": "「草率，或是憑空編造。」"})
			seq.append({"s": A, "t": "這是很重的兩個詞。你有什麼證據，說他編造？",
				"key": "accuse", "choices": ["……沒有。只是對不上。", "圖跟底片完全不同。不是編的，是什麼？"],
				"then": [
					[{"s": A, "t": "對不上，是一件觀測上的事實。編造，是一句關於人的指控。不要把這兩件事寫在同一行。"}],
					[{"s": A, "t": "完全不同，也可能只是用錯了方法。我年輕時把整張星圖倒過來讀過一次——沒有人說我編造，只說我是個笨蛋。這個詞比較公道。"}],
				]})
			seq.append({"s": K, "t": "（很輕地）……我們小時候畫的那張星圖，也被人這樣說過。"})
			seq.append({"s": A, "t": "再去看一次吧。看看角落那個「14」。我在這裡等。",
				"key": "revise_report", "choices": ["好。（回到看片台和筆記本）", "我想照這樣交。"],
				"then": [[], [{"s": A, "t": "那我收下。但我會在旁邊寫一行：「說抄錄者草率或編造——本紙沒有證據。」"}]]})
			return seq
		"unknown":
			seq.append({"s": A, "t": "「原因還沒查明。」"})
			if report.get("aligned", false):
				seq.append({"s": A, "t": "很少有人敢這樣交卷。你找到了怎麼對齊，卻不肯假裝知道為什麼——這很好。"})
			else:
				seq.append({"s": A, "t": "很少有人敢這樣交卷，這很好。可是你連怎麼對上都還沒試出來吧？「不知道」要在查過以後才值錢。"})
		"mirror":
			seq.append({"s": A, "t": "「翻了面。」對，是翻了面。"})
			seq.append({"s": A, "t": "可是翻過來以後，它還是歪的吧？差一點，全都朝同一個方向。你沒覺得奇怪嗎？"})
		"tilt":
			seq.append({"s": A, "t": "「放斜了約 3 度。」"})
			seq.append({"s": A, "t": "光轉三度，對得上嗎？角落那個「14」，你仔細看過了嗎？"})
		_:
			seq.append({"s": A, "t": "翻面，還轉了三度。"})
			var why_choices: Array = ["抄錄圖上的編號是反的。"]
			var why_then: Array = [[{"s": A, "t": "對。數字不會自己變成鏡像。那是抄錄方法留下的指紋。"}]]
			if report.get("aligned", false):
				why_choices.append("把它翻過來，十七個點都對上了。")
				why_then.append([{"s": A, "t": "對上了，只說明這樣對得上。要說明為什麼，得在底片和紙上找到它留下的痕跡。"}])
			why_choices.append("底片上畫的北向箭頭是斜的。")
			why_then.append([{"s": A, "t": "對。北在哪裡，要問底片自己，不能問紙的邊。"}])
			seq.append({"s": A, "t": "你怎麼知道是底片翻了面，而不是星自己跑了？",
				"key": "why", "choices": why_choices, "then": why_then})
	match report.get("original", "keep"):
		"keep":
			seq.append({"s": A, "t": "原圖留著，更正寫在旁邊。很好。三十年後有人翻到這張紙，能看見錯在哪裡，也能看見是誰、怎麼改的。"})
		"redraw":
			seq.append({"s": A, "t": "重畫了？乾淨的圖很好看。可是下一個人只看得到你的答案，看不到你怎麼得到它。原來那張呢？"})
			seq.append({"s": K, "t": "在我這裡。我……沒捨得丟。"})
			seq.append({"s": A, "t": "那就把兩張釘在一起。"})
	match report.get("residual", "not_found"):
		"unresolved":
			seq.append({"s": A, "t": "「未解決：需要另一張同天區的底片。」"})
			seq.append({"s": A, "t": "這是整張紙上我最喜歡的一行。"})
		"delete":
			seq.append({"s": A, "t": "你刪掉的這一點——你確定它是墨漬？",
				"key": "delete", "choices": ["不確定。", "大概是。"],
				"then": [[], []]})
			seq.append({"s": A, "t": "「大概」不能拿來刪東西。把它寫回去，打個問號。問號不丟人。"})
		"new_object":
			seq.append({"s": A, "t": "新天體。（笑了一下，不是嘲笑）一張底片、一個白點、一個晚上。如果我每次這樣想都寫下來，皇家天文學會早就把我請出去了。"})
			seq.append({"s": A, "t": "寫「未解決」吧。等第二張底片。它要是真的在那裡，它會等你。"})
		_:
			seq.append({"s": A, "t": "……這裡還有一點沒對上，你沒看見？（用鉛筆輕輕圈起來）沒關係。現在看見了。"})
	if report.get("kit_credited", false):
		seq.append({"s": A, "t": "兩個人各自對過。%s，謝謝。" % K})
		seq.append({"s": K, "t": "應該的。"})
	elif report.get("kit_checked", false):
		seq.append({"s": A, "t": "%s也對過一次吧？我看見紙上有兩種鉛筆的痕跡。寫上去。" % K})
	var cause: String = report.get("cause", "unknown")
	var hasty: bool = cause in ["mirror", "tilt"] or (cause == "unknown" and not report.get("aligned", false)) or report.get("original", "keep") == "redraw" or report.get("residual", "") in ["delete", "new_object", "not_found"] or (report.get("kit_checked", false) and not report.get("kit_credited", false))
	if hasty:
		seq.append({"s": A, "t": "要改，現在還來得及。",
			"key": "revise_report", "choices": ["改。（回到看片台和筆記本）", "就這樣交。"],
			"then": [[], [{"s": A, "t": "好。我照你寫的轉出去——連同我在旁邊寫的這幾行。"}]]})
	return seq


static func mentor_dyson(_report: Dictionary, state := {}) -> Array:
	var seq: Array = [
		{"s": A, "t": "好了。說點比 14 號更麻煩的事。"},
		{"s": A, "t": "（把一本濕了邊的期刊放在桌上）皇家天文學會的月報。今年春天，皇家天文學家 Dyson 寫了一篇短文。"},
		{"s": A, "t": "1919 年 5 月 29 日有一次日全食。那天，太陽會停在金牛座一片星場的前面——那裡的亮星，多得不尋常。"},
		{"s": A, "t": "他說，這是檢驗一個理論的好機會。一位在柏林工作的物理學家，愛因斯坦。"},
		{"s": A, "t": "這種時候談一個柏林來的理論，在某些人聽來就像通敵。我不這麼想——理論沒有國籍。可是它也不會因為漂亮，就變成真的。"},
		{"s": A, "t": "他的理論說：星光從太陽旁邊經過時，會被拉彎一點點。我們從地上看，那顆星就像被往外推開了。"},
		{"s": A, "t": "照我們熟悉的牛頓式算法，光如果也受引力影響，也會彎——但只有一半。也有人說，根本不會彎。"},
		{"s": A, "t": "一半、全部，或是零。差別有多大？",
			"key": "size", "choices": ["很大吧？", "……"],
			"then": [[], []]},
		{"s": A, "t": "在太陽的邊上，最多 1.75 角秒。大約是三公里外，一枚硬幣的寬度。"},
		{"s": A, "t": "平常太陽亮得什麼都看不見。只有日全食，月亮把它遮住，星才會出來。拍下那一刻太陽旁邊的星，再和夜裡拍的同一片星比——就知道它們有沒有被推開。"},
		{"s": A, "t": "他還提到一件事：上一次拿日食底片來比，底片因為用了平面鏡反射，整張是反的，得翻過來、膜面對膜面才比得了。"},
		{"s": A, "t": "聽起來耳熟嗎？"},
		{"s": A, "t": "我教了三十年牛頓。潮汐、行星、彗星回來的日子——它從來沒讓我失望過。要我為了一張日食底片改掉這些，那張底片得比這張桌上任何東西都乾淨。"},
	]
	if state.get("orrery_seen", false):
		# Issue #37: the Newtonian knows Mercury's residual and weighs it fairly.
		# HISTORICAL_RECORD: about 43″/century unexplained since Le Verrier (1859); no
		# intra-Mercurial planet confirmed. FICTION: the mentor's view.
		seq.append({"s": A, "t": "（瞥了一眼書架上的太陽系儀）你看過那台小東西了。好吧——水星例外。那 43 角秒，算了快六十年，還沒人說得清。"})
		seq.append({"s": A, "t": "也許是一顆還沒找到的行星，也許是我們哪裡量錯了。可是一個小數字，還不夠讓我拆掉整棟房子。要拆，得有第二個、第三個，而且每一個都乾淨。"})
	seq.append_array([
		{"s": A, "t": "現在你告訴我。（拿起你的紙）如果日食那張底片上的星「移動」了——我們怎麼知道，那不是有人把底片放反、放斜了？",
			"key": "bridge", "choices": ["……不知道。除非先把這些都排除掉。", "用離太陽很遠的星來檢查？", "（沉默）"],
			"then": [
				[{"s": A, "t": "對。所以我不急著相信。這不是固執——這就是你今晚做的事。"}],
				[{"s": A, "t": "……（看了你一眼）這句話留著。過幾天，也許有人會想聽。"}],
				[{"s": A, "t": "不用急著回答。你今晚已經回答了一半。"}],
			]},
		{"s": A, "t": "Eddington 前幾天問我，這棟樓裡誰的紀錄最乾淨。"},
		{"s": A, "t": "我會把你這張紙轉給他。照原樣轉——寫錯的、劃掉的，全部。"},
	])
	return seq


static func interlude_caption() -> String:
	return "三天後"


static func eddington_exam(report: Dictionary, _state: Dictionary) -> Array:
	var read_line := "我讀了三遍。不是因為難懂——是因為很少有人把「不知道」寫得這麼清楚。" if report.get("residual", "") == "unresolved" else "我讀了兩遍。寫得很清楚。"
	return [
		{"s": E, "t": "請坐。我是 Eddington。%s說，這是你寫的。" % A},
		{"s": E, "t": read_line},
		{"s": E, "t": "假如你當時沒找到那個反過來的「14」——你會交什麼？",
			"key": "q1", "choices": ["交上差異和我試過的對齊方式，寫「原因未明」。", "照最像的那樣對齊，交上去。", "先去問抄錄的人。"],
			"then": [
				[{"s": E, "t": "好。那樣的話，下一個人至少知道從哪裡接著查。"}],
				[{"s": E, "t": "那下一個人就分不清，哪些是你找到的、哪些是你猜的。"}, {"s": E, "t": "猜沒有錯。只是要寫明是猜。"}],
				[{"s": A, "t": "（輕聲）……他在法國。"}, {"s": E, "t": "問人是對的。可是人不一定都在。紙會在。"}],
			]},
		{"s": E, "t": "那多出來的一點，你覺得是什麼？",
			"key": "q2", "choices": ["不知道。一張底片分不出來。", "可能是很暗的星。", "可能只是藥膜的瑕疵。"],
			"then": [
				[{"s": E, "t": "我也不知道。我們兩個不知道得一模一樣，這讓我很放心。"}],
				[{"s": E, "t": "有可能。你打算怎麼確定？"}, {"s": YOU, "t": "……找另一張同一片天的底片。"}, {"s": E, "t": "對。一張底片只能提出問題。"}],
				[{"s": E, "t": "有可能。你打算怎麼確定？"}, {"s": YOU, "t": "……找另一張同一片天的底片。"}, {"s": E, "t": "對。一張底片只能提出問題。"}],
			]},
		{"s": E, "t": "%s大概跟你說過 Dyson 的那篇短文了。" % A},
		{"s": A, "t": "說了。也說了我不信。"},
		{"s": E, "t": "你不信什麼？"},
		{"s": A, "t": "我不信一張在雲底下、在熱帶、在戰時拍的底片，能乾淨到讓我改掉牛頓。"},
		{"s": E, "t": "我也不信。"},
		{"s": E, "t": "所以我想先把「乾淨」這兩個字，寫成一張清單。（把一張白紙放到桌子中間）你們兩位幫我寫。"},
	]


static func plan_intro() -> Array:
	return [
		{"s": E, "t": "怎樣的日食觀測，才算公平的比較？挑四件最要緊的事。"},
		{"s": "", "t": "[color=#b8ad98]點選卡片放進計畫；再點一次可以拿回來。%s和 Eddington 會說出他們的想法。[/color]" % A},
	]


## kind: "core" (the fair-test essentials), "helpful", "bias" (both characters object; blocks finishing).
static func plan_cards() -> Array:
	return [
		{"id": "comparison", "kind": "core", "text": "比對片：用同一具望遠鏡，在夜裡拍同一片星場（太陽不在的時候）",
			"react": [
				{"s": E, "t": "沒有這張，日食底片上的星就沒有「原來的位置」可以比。"},
				{"s": A, "t": "同一具望遠鏡——這點我同意。換了鏡頭，就等於換了一把尺。"},
			]},
		{"id": "far_stars", "kind": "core", "text": "用離太陽很遠的星當基準，校正底片的比例和方向",
			"react": [
				{"s": A, "t": "這就是你的 14 號。底片可能放斜、可能縮放——遠處的星不該移動，就拿它們來量這些。"},
				{"s": E, "t": "太陽旁邊的星被往外推，遠處的星幾乎不動。兩種動法不一樣，才分得開。"},
			]},
		{"id": "rules_first", "kind": "core", "text": "量之前先寫下：什麼樣的底片不能用",
			"react": [
				{"s": A, "t": "先寫規則，再看結果。不然人總會替自己喜歡的數字找理由。"},
				{"s": E, "t": "包括我。"},
			]},
		{"id": "conditions", "kind": "helpful", "text": "記下每張底片的狀況：雲、曝光秒數、溫度、時鐘驅動",
			"react": [
				{"s": E, "t": "熱帶的白天和夜晚差很多，鏡子和鏡筒都會變形。"},
				{"s": A, "t": "還有時鐘驅動。追不上太陽，星就拖成一條線。你們需要一個真正懂鐘的人。"},
			]},
		{"id": "two_sites", "kind": "helpful", "text": "派兩支隊伍到不同的地方，互相檢驗",
			"react": [
				{"s": E, "t": "Dyson 先生正有這個打算。一處下雨，另一處也許是晴天。"},
				{"s": A, "t": "兩處量出同一個數字，我才會開始坐不住。"},
			]},
		{"id": "go_anyway", "kind": "helpful", "text": "就算戰爭還沒結束，也照計畫準備",
			"react": [
				{"s": E, "t": "下一次這麼好的機會，要等很多年。"},
				{"s": A, "t": "也可能等到沒有船、沒有人。準備可以——別把準備當成結論。"},
			]},
		{"id": "nearest_only", "kind": "bias", "text": "只拍太陽旁邊那幾顆星：偏折最大，最好量",
			"react": [
				{"s": A, "t": "那你拿什麼檢查底片有沒有放斜？只有它們，你就分不清是星動了，還是底片動了。"},
				{"s": E, "t": "它們最重要，可是不能只有它們。"},
			]},
		{"id": "keep_agreeing", "kind": "bias", "text": "量完之後，只留下和預測相符的底片",
			"react": [
				{"s": E, "t": "那我們量到的，就只是自己的希望。"},
				{"s": A, "t": "我們兩個難得完全同意。"},
			]},
	]


static func plan_blocked(card: Dictionary) -> Array:
	match card.get("id", ""):
		"nearest_only":
			return [{"s": A, "t": "這一條我不能簽。"}, {"s": E, "t": "我也覺得少了什麼。換一張吧。"}]
		"keep_agreeing":
			return [{"s": E, "t": "這一條……我們拿下來吧。"}, {"s": A, "t": "我替你拿。（把卡片翻過去）"}]
	return [{"s": E, "t": "這一條，我們再想想。"}]


static func plan_finish(plan: Array) -> Array:
	var core := ["comparison", "far_stars", "rules_first"]
	var missing := core.filter(func(c): return not plan.has(c))
	var names := {"comparison": "夜裡的比對片", "far_stars": "遠處的星", "rules_first": "先寫好的規則"}
	var seq: Array = []
	if missing.is_empty():
		seq.append({"s": E, "t": "比對片、遠處的星、先寫好的規則。（把紙推到%s面前）" % A})
		seq.append({"s": A, "t": "（讀了很久）……這張紙，我願意簽。"})
		seq.append({"s": E, "t": "你願意簽的，比你願意相信的多。"})
		seq.append({"s": A, "t": "這兩件事本來就不一樣。"})
	else:
		seq.append({"s": E, "t": "這是一個好的開始。"})
		seq.append({"s": A, "t": "少了%s。" % "、".join(missing.map(func(m): return names[m]))})
		seq.append({"s": E, "t": "我把它補在最下面，你不介意吧？——這張紙還會改很多次。"})
	return seq


static func trial_task() -> Array:
	return [
		{"s": E, "t": "我想請你做一件事。"},
		{"s": E, "t": "畢宿星團那一帶，夠亮、能在日冕旁邊拍得到的星——從星表裡挑出來，列一張清單。每一顆，都找一張舊底片核對位置。"},
		{"s": E, "t": "這不是遠征隊的名額。我還不知道會不會有遠征，更不知道誰會去。"},
		{"s": E, "t": "可是如果有，這張清單會在箱子裡。三週，夠嗎？",
			"key": "weeks", "choices": ["夠。", "我盡量。", "兩週。"],
			"then": [
				[{"s": E, "t": "好。"}],
				[{"s": E, "t": "「盡量」是個誠實的詞。"}],
				[{"s": K, "t": "（從房間另一頭）……兩週？"}, {"s": E, "t": "三週。睡覺也是科學工作的一部分。"}],
			]},
	]


static func mentor_after(_report: Dictionary) -> Array:
	return [
		{"s": "", "t": "（雨停了。Eddington 的腳步聲消失在走廊盡頭。）"},
		{"s": A, "t": "他喜歡你。他不會說出來——那個人連喜歡什麼都要先量一量。"},
		{"s": A, "t": "我要說的只有一句：做他的清單，就像做我的一樣。哪顆星對不上，就寫它對不上。不管那對誰有利。",
			"key": "after", "choices": ["我會的。", "先生……您真的不信嗎？"],
			"then": [
				[{"s": A, "t": "我知道。"}],
				[{"s": A, "t": "我信了牛頓三十年。"}, {"s": A, "t": "如果要改，我希望是被一張乾淨的底片說服——而不是被一個好故事。你也一樣。"}],
			]},
	]


## Evening coda with Kit. state.accused_once is set by the director when any submitted sheet
## accused the copyist (even if it was revised afterwards). Key kit_choice is kept by Story.
static func kit_coda(report: Dictionary, state: Dictionary) -> Array:
	var accused: bool = state.get("accused_once", false)
	var still_accuses: bool = report.get("cause", "") == "accuse"
	var mirror_line := "今天你在那張紙上，把這兩件事分開寫了。"
	if still_accuses:
		mirror_line = "你今天也那樣寫了。……我不怪你。對不上的時候，人總想找個人來怪。"
	elif accused:
		mirror_line = "你今天差一點也那樣寫了。可是你回頭去看了。"
	return [
		{"s": K, "t": "清單？"},
		{"s": K, "t": "Eddington 的清單。（把茶杯推過來，已經涼了）恭喜。真的。"},
		{"s": K, "t": "我的變星今天又暗了一次，早了四分鐘。沒有人在等這四分鐘——可是我會把它寫下來。"},
		{"s": K, "t": "……你還記得我們小時候畫的那張星圖嗎？",
			"key": "kit_choice", "choices": ["記得。他們說我們是編的。", "那是很久以前的事了。", "（看著看片台，沒有說話）"],
			"then": [
				[{"s": K, "t": "我們可能真的畫錯了。可是畫錯，跟說謊，不是一回事。"},
					{"s": K, "t": mirror_line}],
				[{"s": K, "t": "是啊。"}, {"s": K, "t": "可是今晚看你對那張圖的時候，我覺得好像也沒有那麼久。"}],
				[{"s": K, "t": "……嗯。我也是。"}],
			]},
		{"s": K, "t": "如果真的有遠征……"},
		{"s": K, "t": "算了。先做清單。畢宿星團不會自己排好隊。"},
	]


## Captions over black between 1917 and the M2 departure night (1918 bridge). The tail into
## Príncipe lives in content_departure.gd montage(). tag: HISTORICAL or FICTION.
static func montage() -> Array:
	return [
		{"t": "1917 年 11 月 10 日，聯合常設日食委員會決定：如果可能，派隊到巴西的 Sobral 和非洲西岸外海的普林西比島。", "tag": "HISTORICAL"},
		{"t": "你的清單交了出去。後來又交了兩份。", "tag": "FICTION"},
		{"t": "1918 年 11 月，停戰。", "tag": "HISTORICAL"},
	]


## Extra line(s) for Eddington's 1919 briefing when the prologue was played.
static func principe_callback(story: Object) -> String:
	var t := "你那張畢宿星團的清單在箱子裡。每一顆星都核對過——今天就靠它們了。"
	if story.plan.has("far_stars"):
		t += "別忘了遠處的星。今天，它們和太陽旁邊的星一樣重要。"
	return t
