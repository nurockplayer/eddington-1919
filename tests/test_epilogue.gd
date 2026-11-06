extends SceneTree
## Conversion arc move D: the October 1919 epilogue. Every ledger outcome is played
## through the real dialogue, the chart overlay paints the copied rows through its own
## draw path, and the ending is the one the epilogue shows from the stored snapshot.
## Run: godot --headless --path . --script res://tests/test_epilogue.gd

const SCENE := "res://scenes/epilogue.tscn"
const CONTENT := preload("res://scripts/cambridge/content_epilogue.gd")
const ENDING := preload("res://scripts/ending.gd")
const Settings := preload("res://scripts/settings.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	var story: Node = root.get_node("Story")
	story.reset()
	await _test_ledger_cases(story)
	story.reset()
	await _test_full_flow(story)
	story.reset()
	await _test_final_replies(story)
	story.reset()
	await _test_gamepad(story)
	story.reset()
	check(not story.epilogue_done and story.ending_plate == null and story.ending_plate_caption == "",
		"Story.reset clears the epilogue state")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


## A run shaped like `main._record_run()`; the fields Ending.build reads are all here.
func _make_run(combined: Dictionary, bounds: Dictionary, clean := true) -> Dictionary:
	return {"seed": 4242, "exposures": [], "combined": combined,
		"rule_id": "brightest", "bet": {}, "bet_pick": 0, "telegram_id": "hopeful",
		"reason_id": "sharp", "reason_text": "星像清楚，底片可用。",
		"score": 80, "clean": clean,
		"grade": {"title": "看得清楚", "fit": 2, "clean": clean, "lines": ["你的底片說得清楚。"]},
		"first_result": null, "reselected_after_seeing": false,
		"drive_rate_checked": true, "drive_wound": true,
		"plate_total": 16, "plates_available": 14,
		"plate_counts": {"good": 10, "poor": 3, "unusable": 1},
		"bounds": bounds, "departure_kit": false, "kit_line": ""}


func _plate() -> ImageTexture:
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.1, 0.1, 0.12))
	return ImageTexture.create_from_image(image)


func _new_epilogue() -> Node:
	var chapter = load(SCENE).instantiate()
	root.add_child(chapter)
	var deadline := Time.get_ticks_msec() + 15000
	while chapter._pending != "opening" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter._pending == "opening", "the epilogue reaches its opening dialogue within 15 s")
	return chapter


## Advances every open page; choices use the caller's pick or the first option.
func _finish(chapter, picks := {}) -> void:
	var guard := 100
	while chapter.ui.dialog_active() and guard > 0:
		guard -= 1
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		if entry.has("choices"):
			chapter.ui._choose(int(picks.get(str(entry.get("key", "")), 0)))
		else:
			chapter.ui._advance()
	check(guard > 0, "test dialogue terminates")


func _text(chapter) -> String:
	var out := ""
	for line in chapter.ui._seq:
		out += str(line.get("s", "")) + "：" + str(line.get("t", "")) + "\n"
	return out


func _test_final_replies(story: Node) -> void:
	var cases := [
		{"choice": 0, "case": "own_low", "combined": {"n": 2, "value": 0.70, "sigma": 0.12}, "bounds": {"lo": 0.40, "hi": 1.50}, "pick": 1,
			"reply": "你的底片站在我這邊。你要是憑它們改了想法，改的方向，和 Sobral 的小鏡頭相反。寫清楚，別讓後人替你猜。"},
		{"choice": 0, "case": "inconclusive", "combined": {"n": 2, "value": 1.30, "sigma": 0.30}, "bounds": {"lo": 0.60, "hi": 1.90}, "pick": 1,
			"reply": "你的底片還分不出 0.87 和 1.75，剛才我們都看見了。讓你改變想法的，也許不是那個數字，是你親手量過它。那就照這樣寫。"},
		{"choice": 0, "case": "no_value", "combined": {"n": 0, "value": 0.0, "sigma": 0.0}, "bounds": {}, "pick": 1,
			"reply": "你沒有帶回數值。你要寫底片，就寫明白：改變你的是拍它們的那幾分鐘，不是數字。"},
		{"choice": 0, "case": "conceded", "combined": {"n": 3, "value": 1.90, "sigma": 0.09}, "bounds": {"lo": 1.20, "hi": 2.10}, "pick": 2,
			"reply": "你在 1917 年就寫了 1.75。那你改變的不是數字——是你憑什麼相信它。"},
		{"choice": 0, "case": "conceded", "combined": {"n": 3, "value": 1.90, "sigma": 0.09}, "bounds": {"lo": 1.20, "hi": 2.10}, "pick": 1, "reply": ""},
		{"choice": 1, "case": "no_value", "combined": {"n": 0, "value": 0.0, "sigma": 0.0}, "bounds": {}, "pick": 2,
			"reply": "你在 1917 年就寫了 1.75。那你改變的不是數字——是你憑什麼相信它。"},
		{"choice": 1, "case": "changed_prediction", "combined": {"n": 0, "value": 0.0, "sigma": 0.0}, "bounds": {}, "pick": 2, "current_pick": 1,
			"reply": "你在 1917 年寫了 1.75，現在寫下了另一個數字。你改變的，也許是你憑什麼相信它。"},
		{"choice": 4, "case": "conceded", "combined": {"n": 3, "value": 1.90, "sigma": 0.09}, "bounds": {"lo": 1.20, "hi": 2.10}, "pick": 2,
			"reply": "那就寫下來。沒有改變，也是一筆紀錄。"},
	]
	var chapter = await _new_epilogue()
	for case in cases:
		story.reset()
		var run := _make_run(case.combined, case.bounds)
		story.runs.append(run)
		story.bet_1917 = {"pick": case.pick, "sure": 1}
		story.bet = {"pick": int(case.get("current_pick", case.pick)), "sure": 1}
		chapter._pending = "final_reason"
		chapter._dialogue_done({"final_reason": case.choice})
		var seq: Array = chapter.ui._seq
		var expected: String = case.reply
		check(seq.size() == (1 if expected == "" else 2), "%s has its reply before the close lines" % case.case)
		if expected != "":
			check(str(seq[0].get("t", "")) == expected, "%s final answer receives its intended Ashby line" % case.case)
		else:
			check(seq.size() > 0 and str(seq[0].get("t", "")) == "11 月 6 日，倫敦開會。", "conceded with pick 1 has no Ashby reply")
		check(str(seq[seq.size() - 1].get("t", "")) == "11 月 6 日，倫敦開會。", "%s includes the epilogue close" % case.case)
		_finish(chapter)
		check(str(story.runs.back().get("final_reason_text", "")) == str(CONTENT.final_reason()[0].choices[case.choice]), "%s stores final_reason_text" % case.case)
		var deadline := Time.get_ticks_msec() + 8000
		while chapter.beat != chapter.Beat.ENDING and Time.get_ticks_msec() < deadline:
			await process_frame
		check(chapter.beat == chapter.Beat.ENDING, "%s ends the epilogue" % case.case)
		while chapter._busy:
			await process_frame
	chapter.free()
	await process_frame


## Cases 8–10 of the fact check are the four shapes the ledger can take; each one is
## played in the real weight dialogue, together with its astrographic reply.
func _test_ledger_cases(story: Node) -> void:
	var chapter = await _new_epilogue()
	_finish(chapter)
	check(chapter.beat == chapter.Beat.LETTER, "the opening hands the room to the player")
	var cases := [
		{"run": _make_run({"n": 3, "value": 1.90, "sigma": 0.09}, {"lo": 1.20, "hi": 2.10}), "case": "conceded"},
		{"run": _make_run({"n": 2, "value": 0.70, "sigma": 0.12}, {"lo": 0.40, "hi": 1.50}), "case": "own_low"},
		{"run": _make_run({"n": 2, "value": 1.30, "sigma": 0.30}, {"lo": 0.60, "hi": 1.90}), "case": "inconclusive"},
		{"run": _make_run({"n": 0, "value": 0.0, "sigma": 0.0}, {}), "case": "no_value"},
	]
	for i in cases.size():
		var run: Dictionary = cases[i].run
		check(CONTENT.ledger_case(run) == cases[i].case, "ledger_case names the %s shape" % cases[i].case)
		story.runs.clear()
		story.runs.append(run)
		story.bet_1917 = {"pick": 0, "sure": 2}
		story.bet = {"pick": 2, "sure": 1}
		chapter._pending = "weight"
		chapter._dialogue_done({"astro_weight": i})
		check(chapter.ui.dialog_active(), "%s plays Ashby's reply in the real dialogue" % cases[i].case)
		var text := _text(chapter)
		if i == 0:
			check(not text.contains("搆不上") and text.contains("平均只是把分歧藏起來"), "equal weight explains the disagreement")
		check(text.contains(CONTENT.weight_reply(i)[0].t), "astro_weight %d gets its authored reply" % i)
		check(text.contains(CONTENT._case_line(run)), "%s shows Ashby's ledger line" % cases[i].case)
		check(text.contains("1917 年的帳本") and text.contains("Ashby 先生寫的：0.87")
			and text.contains("1919 年你改成"), "the 1917 ledger page carries the changed pick")
		_finish(chapter)
	chapter.free()
	await process_frame


func _test_full_flow(story: Node) -> void:
	var run := _make_run({"n": 3, "value": 1.90, "sigma": 0.09}, {"lo": 1.20, "hi": 2.10})
	story.runs.append(run)
	story.bet_1917 = {"pick": 1, "sure": 0}
	story.bet = {"pick": 1, "sure": 0}
	story.mercury_suspect = 3
	story.ending_plate = _plate()
	story.ending_plate_caption = "第 7 號底片"
	# main.gd sets this before the scene change; the epilogue is the first run only.
	story.epilogue_done = true
	var chapter = await _new_epilogue()
	_finish(chapter)
	check(chapter.beat == chapter.Beat.LETTER, "the opening releases the letter beat")
	check(chapter.ui.objectives.text.contains("劍橋・1919 年 10 月") and chapter.ui.objectives.text.contains("Dyson"),
		"the objective names the letter")
	var letter_prop: MeshInstance3D = chapter.world.letter_prop
	var letter_bounds: AABB = letter_prop.global_transform * letter_prop.get_aabb()
	check(letter_bounds.position.y >= 0.83 - 0.00001, "letter rests above the tabletop")
	# The normal southern approach must reach the letter, not the 1917 copyist's desk volume.
	chapter.player.velocity = Vector3.ZERO
	chapter.player.global_position = chapter.world.targets.letter + Vector3(0, -0.86, 0.85)
	chapter.player.look_at_point(chapter.world.targets.letter)
	for i in 5:
		await process_frame
	var aimed = chapter.player.aimed_interactable()
	check(aimed != null and str(aimed.get_meta("interact_id", "")) == "letter",
		"the letter is aimable from the southern approach")
	chapter._interact("letter")
	check(chapter.ui.dialog_active(), "the letter opens as real dialogue")
	var letter := _text(chapter)
	check(letter.contains("Dyson 的信（推測重建，非原文）") and letter.contains("1.98″") and letter.contains("0.93″"),
		"the letter states its reconstruction and the recorded numbers")
	_finish(chapter)
	check(chapter.chart.visible, "the letter hands to the chart overlay")
	check(chapter.chart.rows.size() == 1 and str(chapter.chart.rows[0].label) == "你的底片（示意模擬）",
		"the chart starts with the player's own row")
	check(not chapter.chart.notes.has("你的底片：沒有數值。"), "a measured run has a value, not the empty note")
	chapter.chart.button.pressed.emit()
	check(chapter.chart.step == 1 and chapter.chart.rows.size() == 2, "press 1 copies the 4-inch row")
	var four: Dictionary = chapter.chart.rows[1]
	check(str(four.label) == "Sobral 4 吋" and is_equal_approx(float(four.value), 1.98) and is_equal_approx(float(four.sigma), 0.18),
		"the 4-inch row carries 1.98 with a 0.18 standard deviation")
	check(chapter.chart.notes.has("Sobral 4 吋：1.98″，±0.12″ 機率誤差，約 0.18″ 標準差"),
		"the 4-inch note keeps the probable error and the standard deviation apart")
	check(chapter.chart.button.text == "抄上 Sobral 天體照相儀", "press 1 advances the button")
	chapter.chart.button.pressed.emit()
	check(chapter.chart.step == 2 and chapter.chart.rows.size() == 3, "press 2 copies the astrographic row")
	var astro: Dictionary = chapter.chart.rows[2]
	check(str(astro.label) == "Sobral 天體照相儀" and bool(astro.get("weak", false)) and bool(astro.get("no_bar", false)),
		"the astrographic row is weak and has no bar")
	check(chapter.chart.notes.has("Sobral 天體照相儀：約 0.93″，沒有可靠的誤差"), "the astrographic note says why")
	check(chapter.chart.button.text == "抄好了", "press 2 advances the button to 抄好了")
	await process_frame
	await process_frame
	var drawn: Dictionary = chapter.chart.chart.drawn()
	check(drawn.markers.size() == 3 and drawn.markers[2] == "hollow",
		"the chart paints the astrographic row as a hollow marker")
	check(drawn.bars == ["bar", "bar", "none"], "the chart paints no error bar for the astrographic row")
	chapter.chart.button.pressed.emit()
	check(not chapter.chart.visible and chapter.ui.dialog_active(), "press 3 closes the chart into the weight question")
	check(chapter._pending == "weight", "the weight question is the authored beat after the chart")
	check(chapter.player.camera.global_position.distance_to(chapter.world.lamp.global_position) > 1.5, "weight dialogue is clear of the lamp")
	_finish(chapter, {"astro_weight": 1})
	check(chapter.beat == chapter.Beat.ORRERY, "the ledger hands the room to the orrery")
	check(chapter.ui.objectives.text.contains("太陽系儀還在架上"), "the objective names the orrery")
	chapter._interact("orrery")
	check(root.get_camera_3d().name == "OrreryCloseup", "orrery dialogue uses the close-up")
	var orrery := _text(chapter)
	check(orrery.contains("你在 1917 年最懷疑的是") and orrery.contains("引力隨距離減弱的規則"),
		"the orrery repeats the 1917 suspect")
	check(orrery.contains("1915 年 11 月") and orrery.contains("43 角秒"), "the orrery pays off Mercury")
	var prior := orrery.find("1915 年 11 月")
	var alternatives := orrery.find("我們找過的那些說法")
	var light := orrery.find("可是光彎多少")
	check(prior >= 0 and alternatives > prior and light > alternatives, "alternatives connect Mercury to the light prediction")
	while chapter._pending in ["orrery_talk", "click_reply"]:
		check(root.get_camera_3d().name == "OrreryCloseup", "orrery and click reply keep the close-up")
		if chapter.ui._seq[chapter.ui._seq_i].has("choices"):
			chapter.ui._choose(1)
		else:
			chapter.ui._advance()
	check(root.get_camera_3d() == chapter.player.camera and chapter.find_child("OrreryCloseup", true, false) == null, "final reason restores the player camera")
	_finish(chapter, {"final_reason": 2})
	var back: Dictionary = story.runs.back()
	check(int(back.get("astro_weight", -1)) == 1, "the astrographic weighting is stored on the run")
	check(int(back.get("click", -1)) == 1, "the orrery answer is stored on the run")
	check(int(back.get("final_reason", -1)) == 2, "the notebook answer is stored on the run")
	check(str(back.get("final_reason_text", "")) == "兩地一起", "the notebook answer keeps its text")
	var deadline := Time.get_ticks_msec() + 8000
	while not chapter.ui.ending_panel.visible and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter.beat == chapter.Beat.ENDING and chapter.ui.ending_panel.visible,
		"the close fades to the ending inside the epilogue")
	var review_text: String = chapter.ui.ending_review.text
	check(review_text.contains("筆記本最後一句：兩地一起。"), "the ending shows the notebook answer")
	check(review_text.contains("Sobral 天體照相儀那組：先放一邊，寫明了原因"), "the ending shows the astrographic weighting")
	check(chapter.ui.ending_history.text.contains("1979 年，有人重新量了 Sobral 的底片"),
		"the history carries the 1979 remeasurement in this route too")
	check(chapter.ui.ending_plate.texture != null and chapter.ui.ending_plate_caption.text == "第 7 號底片",
		"the ending shows the plate carried across the scene change")
	_check_second_run(story)
	await _check_replay(chapter, story, 4242)
	chapter.free()
	await process_frame


## A replay keeps epilogue_done, so the lamp-out in 1919 goes straight to _show_ending,
## and the ending compares the two runs.
func _check_second_run(story: Node) -> void:
	story.departure_done = true
	story.epilogue_done = false
	var probe = load("res://scripts/main.gd").new()
	probe._came_from_departure = true
	check(probe._epilogue_due(), "a first completed run is epilogue-due")
	story.epilogue_done = true
	check(not probe._epilogue_due(), "a replay is not epilogue-due")
	probe.free()
	var second := _make_run({"n": 2, "value": 1.70, "sigma": 0.20}, {"lo": 1.10, "hi": 2.30})
	story.runs.append(second)
	var ending: Dictionary = ENDING.build(second, ENDING.story_view(story))
	check(str(ending.body).contains("本子上的兩次試驗"), "the second run's ending compares it with the first")


## The same-sky replay button on that ending loads main.tscn with the run's seed.
func _check_replay(chapter, story: Node, seed_value: int) -> void:
	chapter.ui.ending_replay.pressed.emit()
	var existing = load("res://scripts/main.gd")
	check(existing.replay_pending and existing.next_seed == seed_value and existing.replay_same_sky,
		"the same-sky replay hands the seed and the sky to main")
	var deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var scene: Node = current_scene
		if is_instance_valid(scene) and scene.get_script() != null and scene.get_script().resource_path == "res://scripts/main.gd":
			break
	if is_instance_valid(current_scene) and current_scene.get_script() != null and current_scene.get_script().resource_path == "res://scripts/main.gd":
		current_scene.set_process(false)
		check(current_scene._is_replay and current_scene.sim.run_seed == seed_value,
			"the replay lands in 1919 with the same seed")
		check(not load("res://scripts/main.gd").replay_pending, "main consumes the replay hand-off")
	else:
		failures += 1
		print("FAIL: same-sky replay did not load main.tscn")
	# Leave the replayed scene without running its start.
	if is_instance_valid(current_scene):
		current_scene.set_process(false)


## The overlay's one button is focusable and answers the gamepad's accept.
func _test_gamepad(story: Node) -> void:
	story.runs.append(_make_run({"n": 3, "value": 1.90, "sigma": 0.09}, {"lo": 1.20, "hi": 2.10}))
	var chapter = await _new_epilogue()
	_finish(chapter)
	chapter.chart.open(story.runs.back())
	await process_frame
	check(chapter.chart.button.has_focus(), "the overlay lands focus on its button")
	var old_scale := Settings.text_scale
	Settings.text_scale = 1.2
	Settings.refresh_fonts(self)
	chapter.chart.refresh_fonts()
	await process_frame
	await process_frame
	check(chapter.chart.chart.drawn().label_px == Settings.fs(14),
		"the overlay chart follows the UI text scale")
	Settings.text_scale = old_scale
	Settings.refresh_fonts(self)
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame
	await process_frame
	check(chapter.chart.step == 1, "the gamepad's accept copies the first Sobral row")
	chapter.free()
	await process_frame
