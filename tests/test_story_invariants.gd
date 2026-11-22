extends SceneTree
## F15/F16: deterministic measured plates, real dialogue choices, coda and chart UI.

const MAIN_PATH := "res://scripts/main.gd"
const Judgment := preload("res://scripts/judgment.gd")
const EPILOGUE := "res://scenes/epilogue.tscn"
const CASES := [
	{"name": "supports-1.75", "value": 1.75, "sigma": 0.1, "verdict": 2, "telegram": 1},
	{"name": "supports-0.87", "value": 0.87, "sigma": 0.1, "verdict": 1, "telegram": 2},
	{"name": "inconclusive", "value": 1.30, "sigma": 0.3, "verdict": 3, "telegram": 2},
]
# Explicit lexical contract on displayed lines (not content helper return values).
# The existing star-chart memory distinguishes a mistake from lying; it is allowed.
const FRAUD := "(?i)fraud|falsif|fabricat|cheat|rigged|you (?:lied|are lying)|造假|偽造|捏造|舞弊|欺詐|詐欺|改ざん|不正|조작|날조|사기|부정행위"
const PROOF := "(?i)(?:your|our|these|player.s).*plates.*(?:proved|proven|prove|confirmed|established).*1[.]75|(?:你的|我們的|這些|君の|あなたの|私たちの).*1[.]75.*(?:證明|証明|確定)|(?:你的|我們的|這些|君の|あなたの|私たちの).*(?:證明|証明|確定).*1[.]75|(?:네|당신의|우리).*1[.]75.*(?:증명|입증|확정)"
const PE := {"zh_TW": "機率誤差", "en": "probable error", "ja": "確率誤差", "ko": "확률 오차"}
var checks := 0
var failures := 0
var lines: Array = []
var route := ""
var keys: Array = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: %s %s" % [route, message])


func _matches(pattern: String, text: String) -> bool:
	var regex := RegEx.new()
	regex.compile(pattern)
	return regex.search(text) != null


func _capture(speaker: String, text: String, beat: String) -> void:
	lines.append({"s": speaker, "t": text, "beat": beat})
	check(not _matches(FRAUD, text), "F15 no fraud accusation [%s/%s]: %s" % [beat, speaker, text])


# Read each entry after the UI has displayed it; choosing inserts and plays `then`.
func _finish(chapter, picks: Dictionary, stop := "") -> void:
	var remaining := 200
	while chapter.ui.dialog_active() and remaining > 0:
		if stop != "" and chapter._pending == stop:
			return
		remaining -= 1
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		_capture(chapter.ui.speaker_label.text, chapter.ui.text_label.text, chapter._pending)
		if entry.has("choices"):
			var key := str(entry.key)
			keys.append(key)
			for button in chapter.ui._choice_buttons:
				_capture("choice", button.text, chapter._pending)
			chapter.ui._choice_buttons[int(picks.get(key, 0))].pressed.emit()
		else:
			chapter.ui._advance()
	check(remaining > 0, "dialogue terminates")


func _f15(case: Dictionary, ask: bool) -> Dictionary:
	var story = root.get_node("Story")
	story.reset()
	story.from_prologue = true
	story.bet = {"pick": 2, "sure": 0, "ashby": 1, "year": 1919}
	story.kit_choice = 0
	var main = load(MAIN_PATH)
	main.next_seed = 4242
	var chapter = main.new()
	root.add_child(chapter)
	await process_frame
	chapter.set_process(false)
	chapter.ui.hide_title()
	chapter.phase = chapter.Phase.NIGHT
	chapter.sim.rule_id = "strict"
	chapter.sim.bet_pick = 2
	chapter.sim.plates = [{"number": 1, "start": 100.0, "duration": 10.0,
		"usable": true, "included": true, "quality": "good", "stars": 5, "trail": 0.0,
		"read": true, "sigma": case.sigma, "reading": chapter.sim.reading_for_value(case.value)}]
	chapter.sim.measured = true
	var image := Image.create(8, 8, false, Image.FORMAT_RGB8)
	chapter.plate_textures = [ImageTexture.create_from_image(image)]
	var before: Dictionary = chapter.sim.combined().duplicate(true)
	var plates: Array = chapter.sim.plates.duplicate(true)
	check(Judgment.verdict_truth(chapter.sim) == case.verdict, "fixture verdict class")
	lines = []
	keys = []
	chapter._start_judgment()
	var picks := {"verdict": case.verdict, "press": 0 if ask else 1,
		"telegram": case.telegram, "reason": 1, "kit_first": 1}
	_finish(chapter, picks)
	check(chapter.phase == chapter.Phase.CODA, "reaction reaches coda")
	chapter._interact("departure_workbook")
	_finish(chapter, picks)
	chapter._interact("mentor_loupe")
	_finish(chapter, picks)
	check(keys.has("press") and chapter._pressed_eddington == ask, "optional question actually chosen")
	check(keys.has("verdict") and keys.has("telegram") and keys.has("kit_first"), "judgment and coda choices played")
	chapter._coda_transition.pause()
	chapter._coda_transition.custom_step(3.0)
	check(chapter.ui.ending_panel.visible, "coda reaches real ending UI")
	check(chapter.sim.combined() == before and chapter.sim.plates == plates, "F15 measurement unchanged")
	var result := {"measurement": chapter.sim.combined().duplicate(true),
		"grade": chapter._grade.duplicate(true), "telegram": chapter.ui.ending_telegram.text,
		"run": story.runs.back().duplicate(true)}
	check(not str(result.telegram).is_empty(), "telegram UI populated")
	_capture("telegram", result.telegram, "ending")
	print("BRANCH %s ask=%s value=%.2f fit=%d telegram=%s" % [route, ask, result.measurement.value, result.grade.fit, result.run.telegram_id])
	chapter.free()
	await process_frame
	return result


func _visible_text(node: Node) -> Array[String]:
	var out: Array[String] = []
	if node is Control and not node.is_visible_in_tree():
		return out
	if node is Label or node is RichTextLabel or node is Button:
		out.append(node.text)
	for child in node.get_children():
		out.append_array(_visible_text(child))
	return out


func _chart_frame(chapter) -> void:
	# Godot headless still executes CanvasItem draw callbacks on process frames.
	await process_frame
	await process_frame
	var text := "\n".join(_visible_text(chapter.chart))
	var painted: Array = chapter.chart.chart.drawn_texts()
	check(not painted.is_empty(), "chart draw path ran")
	text += "\n" + "\n".join(painted)
	_capture("chart", text, "chart-%d" % chapter.chart.step)
	check(not _matches("(?i)σ|1\\s*[- ]?sigma|one[- ]sigma", text), "F16 no sigma label: " + text)
	for line in text.split("\n"):
		if line.contains("0.12"):
			check(line.to_lower().contains(str(PE[L.current()]).to_lower()), "F16 0.12 labelled probable error: " + line)
	if chapter.chart.step == 2:
		check(text.contains(L.t("Sobral 4 吋")), "F16 displayed 4-inch instrument")
		check(text.contains(L.t("Sobral 天體照相儀")), "F16 displayed astrographic instrument")
		check(text.contains("0.12"), "F16 probable error displayed")


func _f16(run: Dictionary, variant: int) -> void:
	var story = root.get_node("Story")
	story.reset()
	story.runs.append(run.duplicate(true))
	story.bet_1917 = {"pick": 1, "sure": 0}
	story.bet = story.bet_1917.duplicate()
	lines = []
	keys = []
	var chapter = load(EPILOGUE).instantiate()
	root.add_child(chapter)
	var deadline := Time.get_ticks_msec() + 15000
	while chapter._pending != "opening" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter._pending == "opening", "epilogue opening reached")
	var picks := {"astro_weight": variant, "click": variant, "final_reason": [0, 2, 4][variant]}
	_finish(chapter, picks)
	chapter._interact("letter")
	_finish(chapter, picks)
	check(chapter.chart.visible, "letter opens chart")
	for step in 4:
		await _chart_frame(chapter)
		if step < 3:
			chapter.chart.button.pressed.emit()
	chapter.chart.choices[[0, 1, 3][variant]].pressed.emit()
	await _chart_frame(chapter)
	chapter.chart.button.pressed.emit()
	_finish(chapter, picks, "close")
	# Capture the final Ashby reply before advancing into the asynchronous tableau.
	_finish(chapter, picks)
	deadline = Time.get_ticks_msec() + 8000
	while chapter._pending != "tableau" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter._pending == "tableau", "close reaches tableau")
	_finish(chapter, picks)
	check(keys.has("astro_weight") and keys.has("final_reason"), "Ashby route played")
	var shown := ""
	var ashby := ""
	for line in lines:
		shown += line.t + "\n"
		if line.s == L.t("Ashby 先生"):
			ashby += line.t + "\n"
			check(not _matches(PROOF, line.t), "F16 no player-plate proof [%s]: %s" % [line.beat, line.t])
		check(not _matches("(?i)σ|1\\s*[- ]?sigma|one[- ]sigma", line.t), "F16 uncertainty is not sigma: " + line.t)
		if line.t.contains("0.12"):
			check(line.t.to_lower().contains(str(PE[L.current()]).to_lower()), "F16 probable error named: " + line.t)
	check(ashby.contains(L.t("你的底片還分不出來。Sobral 的可以。一地分得出，一地還不能——所以我還不想只聽一邊，也不能假裝沒聽見。")), "F16 Ashby retains inconclusive branch: " + ashby)
	check(shown.contains(L.t("Sobral 4 吋")) and shown.contains(L.t("Sobral 天體照相儀")), "F16 both instruments shown")
	chapter.free()
	await process_frame


func _run() -> void:
	await process_frame
	for locale in L.LOCALES:
		L.apply(locale)
		for case in CASES:
			route = "%s/%s" % [locale, case.name]
			var silent: Dictionary = await _f15(case, false)
			var asked: Dictionary = await _f15(case, true)
			check(silent.measurement == asked.measurement, "F15 asking preserves measurement")
			check(silent.grade == asked.grade, "F15 asking preserves grade")
			check(silent.telegram == asked.telegram, "F15 asking preserves telegram text")
			if case.name == "inconclusive":
				for variant in 3:
					route = "%s/inconclusive/epilogue-%d" % [locale, variant]
					await _f16(asked.run, variant)
	L.apply("zh_TW")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
