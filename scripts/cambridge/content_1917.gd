extends RefCounted
class_name CambridgeContent1917
## Temporary, replaceable dialogue and data for the Cambridge prologue.
## Interface contract (dialogue entries use {s:String, t:String, key?:String,
## choices?:Array[String], then?:Array[Array[dialogue entry]]}):
## intro_caption()->String; opening()->Array; kit_guess()->Array;
## kit_talk(state:Dictionary)->Array; kit_double_check()->Array;
## examine(id:String)->Array [logbook, empty_desk, letter, window, fire, clock,
## cabinet, kit_ledger, notebook_before]; viewer_feedback(id:String)->String
## [label_mirrored, arrow_tilted, residual]; viewer_hint(state:Dictionary)->String;
## report_rows()->Array[Dictionary]; mentor_review(report:Dictionary)->Array;
## mentor_dyson(report:Dictionary)->Array; interlude_caption()->String;
## eddington_exam(report:Dictionary, state:Dictionary)->Array; plan_intro()->Array;
## plan_cards()->Array[Dictionary]; plan_blocked(card:Dictionary)->Array;
## plan_finish(plan:Array)->Array; trial_task()->Array; mentor_after(report:Dictionary)->Array;
## kit_coda(report:Dictionary, state:Dictionary)->Array;
## montage()->Array[{t:String, tag:"HISTORICAL"|"FICTION"}];
## principe_callback(story:Object)->String.
## Report rows: {id:String, text:String, needs?:Array[String],
## options:Array[{id:String, text:String, needs?:Array[String]}]}; row ids are
## cause, original, residual, kit_credited. Cause option ids: mirror, tilt, both,
## unknown, accuse; original: keep, redraw; residual: unresolved, delete,
## new_object; Kit checkbox: credited. Clue/state keys: label_mirrored,
## arrow_tilted, residual, log, aligned, residual_found, kit_checked,
## report_done, viewer_opens. Plan cards are {id,text,kind,react:Array}; ids:
## comparison, far_stars, same_instrument, repeat, records, independent,
## discard, prove; kind is core, helpful, or bias.
## Optional mentor_review choice key revise_report: 0 reopens report, 1 continues;
## absent key also continues. kit_coda key kit_choice is retained by Story.
## Every player-facing line here is a reversible placeholder prefixed with ［暫］.

const CAST = preload("res://scripts/cambridge/cast.gd")


static func intro_caption() -> String:
	return "［暫］劍橋天文台・1917 年 10 月\n（重建場景）"


static func opening() -> Array:
	return [{"s": CAST.KIT, "t": "［暫］這是 14 號星場的抄錄圖。核對後交給 %s 吧。" % CAST.MENTOR}]


static func kit_guess() -> Array:
	return [{"s": CAST.KIT, "t": "［暫］或許抄錄的是另一片星場，或是另一個夜晚？"}]


static func kit_talk(state: Dictionary) -> Array:
	if not state.get("aligned", false):
		return [{"s": CAST.KIT, "t": "［暫］先看看標記和箭頭，再試著移動抄錄圖。"}]
	if not state.get("log", false):
		return [{"s": CAST.KIT, "t": "［暫］星點已經靠近了。觀測日誌也許能確認日期和星場。"}]
	if not state.get("residual_found", false):
		return [{"s": CAST.KIT, "t": "［暫］大部分星點都對上了。那一點還需要另一張底片。"}]
	return [{"s": CAST.KIT, "t": "［暫］如果你願意，我可以獨立再核對一次。"}]


static func kit_double_check() -> Array:
	return [{"s": CAST.KIT, "t": "［暫］我重新逐點核對過了；大部分重合，仍有一點未解。"}]


static func examine(id: String) -> Array:
	var lines: Dictionary = {
		"logbook": "［暫］1915 年觀測日誌：星場、日期和底片編號相同。",
		"empty_desk": "［暫］空椅子推在桌邊，外套還掛在鉤上。",
		"letter": "［暫］%s在 1915 年入伍。摺起的信沒有姓名。" % CAST.COPYIST,
		"window": "［暫］雨痕沿著窗玻璃滑下，窗外透進冷光。",
		"fire": "［暫］煤火只剩低低的紅光。",
		"clock": "［暫］調節鐘規律地走著。",
		"cabinet": "［暫］淺抽屜裡整齊收著玻璃底片。",
		"kit_ledger": "［暫］%s 的帳冊記下了獨立的觀測工作。" % CAST.KIT,
		"notebook_before": "［暫］筆記本攤開著，等你記下核對結果。"
	}
	return [{"s": "", "t": lines.get(id, "［暫］這件物品值得再仔細看看。")}]


static func viewer_feedback(id: String) -> String:
	var lines: Dictionary = {
		"label_mirrored": "［暫］抄錄圖上的 14 是反向的。",
		"arrow_tilted": "［暫］底片上的北向箭頭和邊緣略有傾斜。",
		"residual": "［暫］這一點仍不能判定；單張底片不足以下結論。"
	}
	return lines.get(id, "［暫］你記下了這項細節。")


static func viewer_hint(state: Dictionary) -> String:
	if not state.get("label_mirrored", false):
		return "［暫］比較兩個 14 號標記，看看方向是否相同。"
	return "［暫］試著翻面，再按底片上的北向箭頭調整角度。"


static func report_rows() -> Array:
	return [
		{"id": "cause", "text": "［暫］原因", "options": [
			{"id": "mirror", "text": "［暫］抄錄時底片翻面（鏡像）", "needs": ["label_mirrored"]},
			{"id": "tilt", "text": "［暫］底片放斜約 3°", "needs": ["arrow_tilted"]},
			{"id": "both", "text": "［暫］兩者都有", "needs": ["label_mirrored", "arrow_tilted"]},
			{"id": "unknown", "text": "［暫］原因未查明"},
			{"id": "accuse", "text": "［暫］抄錄的人草率或編造"}
		]},
		{"id": "original", "text": "［暫］原始抄錄圖", "options": [
			{"id": "keep", "text": "［暫］保留原圖，旁附更正"},
			{"id": "redraw", "text": "［暫］重畫一張，舊的作廢"}
		]},
		{"id": "residual", "text": "［暫］沒對上的那一點", "needs": ["residual"], "options": [
			{"id": "unresolved", "text": "［暫］未解決，需另一張底片"},
			{"id": "delete", "text": "［暫］當成墨漬刪掉"},
			{"id": "new_object", "text": "［暫］寫成可能是新天體"}
		]},
		{"id": "kit_credited", "text": "［暫］複核", "options": [
			{"id": "credited", "text": "［暫］%s 獨立複核" % CAST.KIT, "needs": ["kit_checked"]}
		]}
	]


static func mentor_review(report: Dictionary) -> Array:
	var line := "［暫］你把已知和未知都寫進了報告。"
	if report.get("cause", "") == "accuse":
		line = "［暫］先讓記錄說明發生了什麼，再判斷抄錄者。"
	elif report.get("original", "") == "redraw":
		line = "［暫］乾淨的新圖方便使用；舊圖也應留下來供人核對。"
	elif report.get("residual", "") == "delete":
		line = "［暫］這個痕跡尚未判明，刪除會失去一項記錄。"
	return [{"s": CAST.MENTOR, "t": line},
		{"s": CAST.MENTOR, "t": "［暫］這份記錄現在就交出去，還是再核對一次？",
		"key": "revise_report", "choices": ["［暫］回到記錄修訂", "［暫］保留這份記錄，繼續"]}]


static func mentor_dyson(report: Dictionary) -> Array:
	return [{"s": CAST.MENTOR, "t": "［暫］Dyson 已提出觀測 1919 年日食與 Hyades 星群的計畫。我仍以牛頓的理論理解重力，但觀測應接受公平檢驗：若日食底片上的星移了，如何知道底片沒有轉動？這份記錄會交給 Eddington。"}]


static func interlude_caption() -> String:
	return "［暫］三天後"


static func eddington_exam(report: Dictionary, state: Dictionary) -> Array:
	var comparison_prompt := "［暫］第一個問題：怎樣檢查星點的位移不是底片翻面或轉動造成的？"
	if report.get("cause", "") == "mirror" or report.get("cause", "") == "both":
		comparison_prompt = "［暫］你在報告中記下了翻面問題。到了日食觀測，怎樣再檢查底片沒有轉動？"
	elif state.get("aligned", false):
		comparison_prompt = "［暫］你已比較過兩張圖。日食觀測還需要哪種比對？"
	var residual_prompt := "［暫］第二個問題：若有一點仍未能判定，報告應如何處理？"
	if report.get("residual", "") == "unresolved":
		residual_prompt = "［暫］你選擇保留未解的一點。遇到新的疑點時，該如何記錄？"
	var comparison_answers := [
		[{"s": CAST.EDDINGTON, "t": "［暫］是的。同一星場的無日食底片可以提供位置比較。"}],
		[{"s": CAST.EDDINGTON, "t": "［暫］單憑抄錄圖還不能分辨方向與轉角。"}]
	]
	var residual_answers := [
		[{"s": CAST.EDDINGTON, "t": "［暫］保留觀察並標明未知，等待另一份證據。"}],
		[{"s": CAST.EDDINGTON, "t": "［暫］過早下結論，會讓後來的檢驗失去空間。"}]
	]
	return [
		{"s": CAST.EDDINGTON, "t": comparison_prompt, "choices": ["［暫］用同一星場的無日食底片比較", "［暫］只沿用舊抄錄圖"], "key": "exam_comparison", "then": comparison_answers},
		{"s": CAST.EDDINGTON, "t": residual_prompt, "choices": ["［暫］記為未解，等待另一張底片", "［暫］先刪去或猜一個答案"], "key": "exam_residual", "then": residual_answers}
	]


static func plan_intro() -> Array:
	return [{"s": CAST.EDDINGTON, "t": "［暫］怎樣的日食觀測，才算公平的比較？請選出幾項原則。"}]


static func plan_cards() -> Array:
	return [
		{"id": "comparison", "text": "［暫］同一星場，無日食時再拍一張", "kind": "core", "react": [{"s": CAST.EDDINGTON, "t": "［暫］同一批星可以作直接比較。"}]},
		{"id": "far_stars", "text": "［暫］記錄遠離太陽的星，檢查底片比例與方向", "kind": "core", "react": [{"s": CAST.MENTOR, "t": "［暫］遠處的星能幫忙查出底片是否轉動或縮放。"}]},
		{"id": "same_instrument", "text": "［暫］盡量使用同一具望遠鏡與測量方式", "kind": "core", "react": [{"s": CAST.MENTOR, "t": "［暫］相同器材能減少比較中的差異。"}]},
		{"id": "repeat", "text": "［暫］重複曝光並保留每張底片", "kind": "helpful", "react": [{"s": CAST.EDDINGTON, "t": "［暫］多一份記錄，便多一次交叉核對。"}]},
		{"id": "records", "text": "［暫］記下曝光與測量條件", "kind": "helpful", "react": [{"s": CAST.MENTOR, "t": "［暫］完整條件讓別人也能檢查結果。"}]},
		{"id": "independent", "text": "［暫］讓另一人獨立複核", "kind": "helpful", "react": [{"s": CAST.EDDINGTON, "t": "［暫］獨立複核可以指出我們忽略的地方。"}]},
		{"id": "discard", "text": "［暫］丟掉不符合預期的底片", "kind": "bias", "react": [{"s": CAST.MENTOR, "t": "［暫］丟棄底片會讓比較失去重要證據。"}]},
		{"id": "prove", "text": "［暫］只挑能證明預想結果的底片", "kind": "bias", "react": [{"s": CAST.EDDINGTON, "t": "［暫］先決定答案再挑證據，無法作公平檢驗。"}]}
	]


static func plan_blocked(card: Dictionary) -> Array:
	return [{"s": CAST.MENTOR, "t": "［暫］「%s」會讓比較偏向預設答案。要不要重新考慮？" % card.get("text", "［暫］這項做法")}]


static func plan_finish(plan: Array) -> Array:
	return [{"s": CAST.EDDINGTON, "t": "［暫］這些原則會讓比較更有說服力。"}]


static func trial_task() -> Array:
	return [{"s": CAST.EDDINGTON, "t": "［暫］請準備 Hyades 星場的比對星清單，並核對底片。這是遠征前的準備工作，不代表加入遠征隊。"}]


static func mentor_after(report: Dictionary) -> Array:
	return [{"s": CAST.MENTOR, "t": "［暫］我為這份誠實的記錄感到驕傲，也知道接下來仍有許多未知。"}]


static func kit_coda(report: Dictionary, state: Dictionary) -> Array:
	return [{
		"s": CAST.KIT,
		"t": "［暫］那張童年星圖的事，我還記得。現在我也有自己的觀測工作。有些人從小就能接觸天文台；機會並不總是相同。",
		"choices": ["［暫］把這次複核記在 %s 名下" % CAST.KIT, "［暫］一起保留完整記錄"],
		"key": "kit_choice",
		"then": [
			[{"s": CAST.KIT, "t": "［暫］謝謝你把我的工作也寫進記錄。"}],
			[{"s": CAST.KIT, "t": "［暫］我們都能從這份記錄繼續做下去。"}]
		]
	}]


static func montage() -> Array:
	return [
		{"t": "［暫］計畫與記錄被收進檔案。", "tag": "FICTION"},
		{"t": "［暫］1917 年 11 月，聯合常設日食委員會討論觀測計畫。", "tag": "HISTORICAL"},
		{"t": "［暫］兩年後，遠方的星光將接受檢驗。", "tag": "FICTION"}
	]


static func principe_callback(story: Object) -> String:
	return "［暫］你在劍橋寫下的原則，仍隨身帶著。"
