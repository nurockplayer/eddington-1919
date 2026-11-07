extends RefCounted
## The ending screen as a pure function of the stored run snapshot.
## Conversion arc D: the October 1919 Cambridge epilogue replays the same ending from
## Story.runs, without the Príncipe scene or its simulation. No scene or autoload
## references (headless-safe, like content_coda.gd).

const Content := preload("res://scripts/content.gd")
const Judgment := preload("res://scripts/judgment.gd")
const Settings := preload("res://scripts/settings.gd")


## The few Story fields the ending reads, copied so the ending survives Story.reset().
static func story_view(story) -> Dictionary:
	var previous: Dictionary = {}
	if story.runs.size() >= 2:
		previous = story.runs[story.runs.size() - 2].duplicate(true)
	return {
		"from_prologue": story.from_prologue,
		"prologue_done": story.prologue_done,
		"kit_choice": story.kit_choice,
		"kit_first": story.kit_first,
		"bet": story.bet.duplicate(true),
		"previous_run": previous,
	}


static func build(run: Dictionary, story: Dictionary) -> Dictionary:
	var c: Dictionary = run["combined"]
	var grade: Dictionary = run["grade"]
	var first = run.get("first_result")
	var reselected: bool = run.get("reselected_after_seeing", false)
	var workbook := L.t("本子上：%.2f″ ± %.2f″（示意模擬）") % [c.value, c.sigma] if c.n > 0 else L.t("本子上：沒有量出任何數值。")
	if first != null and reselected:
		var first_result := L.t("第一次量：%.2f″ ± %.2f″") % [first.value, first.sigma] if first.n > 0 else L.t("第一次量：沒有量出任何數值。")
		workbook += L.t("（%s）") % first_result
	if run.get("departure_kit", false):
		workbook += "\n" + str(run.get("kit_line", ""))
	var telegram := L.t("[font_size=%d]電報　普林西比 → 倫敦　Dyson 收[/font_size]\n\n[font_size=%d][b]%s[/b][/font_size]\n\n理由：%s") % [Settings.fs(17), Settings.fs(30), _telegram_text(run["telegram_id"]), run["reason_text"]]
	var tableau := "[color=#8f8676]%s[/color]" % workbook
	var counts: Dictionary = run["plate_counts"]
	var lines := []
	lines.append(L.t("[b]Eddington 的回應[/b]"))
	for l in grade.lines:
		lines.append("· " + l)
	lines.append("")
	lines.append(L.t("[b]你留下的證據[/b]"))
	lines.append(L.t("· 拍了 %d 張底片（底片匣一共 %d 張）。星像清楚 %d、有瑕疵 %d、星不足五顆 %d。") % [run["plate_total"], run["plates_available"], counts["good"], counts["poor"], counts["unusable"]])
	if c.n > 0:
		lines.append(L.t("· 你量了 %d 張，合併 %.2f″ ± %.2f″（示意模擬）。") % [c.n, c.value, c.sigma])
	else:
		lines.append(L.t("· 沒有量出任何數值。"))
	if first != null and reselected:
		if first.n > 0:
			lines.append(L.t("· 第一次量：%.2f″ ± %.2f″") % [first.value, first.sigma])
		else:
			lines.append(L.t("· 第一次量：沒有量出任何數值。"))
	lines.append(L.t("· 時鐘驅動：%s。") % (L.t("上了發條並校過走速") if run.get("drive_rate_checked", false) else (L.t("上了發條但沒校走速") if run.get("drive_wound", false) else L.t("由 Cottingham 匆忙處理"))))
	# Conversion arc A: the prediction comes back beside the evidence.
	var bet: Dictionary = story.get("bet", {})
	if not bet.is_empty():
		lines.append(L.t("· 量之前你寫的：%s（%s）。") % [Content.bet_pick_text(int(bet.pick)), Content.bet_sure_text(int(bet.sure))])
	if int(bet.get("ashby", 0)) == 1:
		lines.append(L.t("· Ashby 先生寫的：0.87。"))
	# Conversion arc: FICTION — the player's own revision, written in the 1919 ledger.
	if run.has("bet_oct"):
		lines.append(L.t("· 1919 年 10 月你寫的：%s。") % Content.bet_pick_text(int(run.bet_oct)))
	# Conversion arc D: the epilogue's notebook answer and the astrographic decision.
	if str(run.get("final_reason_text", "")) != "":
		lines.append(L.t("· 筆記本最後一句：%s。") % run.final_reason_text)
	if run.has("astro_weight"):
		lines.append(L.t("· Sobral 天體照相儀那組：%s。") % _astro_weight_text(int(run.astro_weight)))
	var history := []
	history.append(L.t("\n[b]歷史上[/b] [color=#8f8676](HISTORICAL_RECORD，詳見 docs/PROVENANCE.md)[/color]"))
	history.append(L.t("普林西比在 302 秒的全食中拍了 16 張底片，曝光 2 到 20 秒；雲在全食最後三分之一才明顯變薄。前十張幾乎沒有星，最後只有兩張、五顆星能用於量測。Eddington 在島上量了一張，結果與愛因斯坦的預測相符；他發給 Dyson 的電報說雲很厚，但「有希望」（1919 年 6 月 5 日的《Nature》引作 \"Through cloud, hopeful\"；發報日期未確認）。"))
	history.append(L.t("1919 年 11 月 6 日，皇家學會與皇家天文學會聯席會議公布結果。報告最倚重的是巴西 Sobral 的 4 吋望遠鏡（1.98″ ± 0.12″）；普林西比是 1.61″ ± 0.30″（當年寫的是「機率誤差」，約是一倍標準誤差的三分之二）。Sobral 天體照相儀的結果因焦距改變、星像模糊而未採用——這是有紀錄的技術理由，而非掩蓋。一次遠征並沒有讓所有疑問就此消失。"))
	history.append(L.t("1979 年，有人重新量了 Sobral 的底片（Harvey）：4 吋 1.90″ ± 0.11″，天體照相儀 1.55″ ± 0.34″——支持了當年團隊對那組 0.93″ 的疑慮。"))
	history.append(L.t("\n[color=#8f8676][font_size=%d]虛構與示意：玩家角色、全部對白、時鐘驅動需要協助的情節、雲的細節、底片影像與所有數值。場景為推測重建；普林西比站沒有已知的現場照片，原始底片也已佚失。[/font_size][/color]") % Settings.fs(15))
	tableau += L.t("\n\n[color=#8f8676]1919 年 11 月 6 日公布的結果：Sobral 1.98″、普林西比 1.61″，都比較接近愛因斯坦的 1.75″。怎麼得出、留下哪些疑問，見「歷史上發生了什麼」。[/color]")
	var previous: Dictionary = story.get("previous_run", {})
	if not previous.is_empty():
		tableau += "\n\n" + Content.run_comparison(previous, run)
	return {
		"title": grade["title"],
		"body": tableau,
		"history": "\n".join(history),
		"review": "\n".join(lines),
		"telegram": telegram,
	}


static func _astro_weight_text(choice: int) -> String:
	return [L.t("照樣一樣重地算"), L.t("先放一邊，寫明了原因"), L.t("整組丟掉，沒有提"), L.t("還不能決定，先重量一次")][choice] if choice >= 0 and choice <= 3 else ""


static func _telegram_text(id: String) -> String:
	for t in Judgment.TELEGRAMS:
		if t.id == id:
			return t.text
	return ""
