extends SceneTree
## Completed runs come only from the real director, shutter, viewer and dialogue.
const Settings := preload("res://scripts/settings.gd")
var content = load("res://scripts/content.gd")
const Judgment := preload("res://scripts/judgment.gd")
const HEADING := "本子上的兩次試驗｜上回 → 這回"
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func wait_for(predicate: Callable, message: String) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(predicate.call(), message)


func dialogue(game, choices := {}) -> void:
	for step in 120:
		if not game.ui.dialog_active():
			return
		var entry: Dictionary = game.ui._seq[game.ui._seq_i]
		if entry.has("choices"):
			var key: String = entry.get("key", "")
			var index: int = choices.get(key, 0)
			if key == "interval":
				index = Judgment.interval_truth(game.sim)
			game.ui._choice_buttons[index].pressed.emit()
		else:
			game.ui._advance()
		await process_frame
	check(false, "dialogue completes within 120 entries")


func new_game(prologue := false):
	var story = root.get_node("Story")
	story.from_prologue = prologue
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.set_process(false)
	game.player.set_physics_process(false)
	await process_frame
	if game.phase == game.Phase.TITLE:
		game.ui.start_pressed.emit()
		# The title fades out for 0.4 s before 1919 starts.
		await wait_for(func(): return game.phase != game.Phase.TITLE, "title start reaches 1919")
	return game


func replay(game, same_sky := true):
	var old_id: int = game.get_instance_id()
	if same_sky:
		game.ui.ending_replay.pressed.emit()
	else:
		for button in game.ui.ending_replay.get_parent().get_children():
			if button.text.begins_with("新的天空"):
				button.pressed.emit()
	await wait_for(func(): return current_scene != null and current_scene.get_instance_id() != old_id, "replay button reloads the real scene")
	var next = current_scene
	next.set_process(false)
	next.player.set_physics_process(false)
	Settings.text_scale = 1.2
	Settings.refresh_fonts(self)
	next.ui.start_pressed.emit()
	await wait_for(func(): return next.phase != next.Phase.TITLE, "replayed title start reaches 1919")
	return next


func finish_run(game, rule := 0, reason := 0, expose := true) -> void:
	await dialogue(game)
	game._interact("eddington")
	await dialogue(game)
	check(game.sim.briefed, "preparation briefing completed")
	game._hold_complete("drive")
	game._hold_complete("chronometer")
	for holder in 8:
		game._hold_complete("plate_box")
	game._interact("eddington")
	await dialogue(game, {"prep": 0})
	await wait_for(func(): return game.phase == game.Phase.TOTALITY and not game._busy, "preparation reaches totality")
	# Advance the real simulation clock in 0.1 game-second steps; no plates injected.
	var shot := 0
	while game.t_game < game.sim.TOTALITY_S:
		# Twelve real exposures exercise the longest summary. Two catch the late gap.
		var starts := [1.0, 15.0, 29.0, 43.0, 57.0, 71.0, 85.0, 99.0, 113.0, 127.0,
			float(game.sim.gaps[2].t), float(game.sim.gaps[2].t) + 9.0]
		if expose and shot < starts.size() and game.t_game >= starts[shot] and not game.sim.is_exposing() and game.change_left <= 0:
			game._toggle_shutter()
		if game.sim.is_exposing() and game.sim._open.duration >= (5.0 if rule == 0 else 6.0):
			game._toggle_shutter()
			shot += 1
		game._process_totality(0.1 / game.sim.TIME_SCALE)
	await wait_for(func(): return game.phase == game.Phase.NIGHT and not game._busy, "third contact develops the real plates and reaches night")
	await dialogue(game)
	if game._needs_comparison_fetch():
		game._interact("oxford_case")
		await dialogue(game)
	game._interact("measure")
	if not root.get_node("Story").runs.is_empty():
		check(game.ui._seq[0].t.begins_with("上一回寫的是："), "rule prompt recalls the previous wording")
	await dialogue(game, {"rule": rule})
	check(game.sim.rule_id == ["strict", "after", "none"][rule], "rule choice is made again")
	for i in game.sim.plates.size():
		if game.sim.plates[i].usable or rule == 1:
			game.ui.plate_toggled.emit(i, true)
	for p in game.sim.plates:
		if p.included and p.usable:
			# Conversion arc C: measured plates need the player's reading.
			p.read = true
			p.reading = game.sim.reading_for_value(p.value)
	game.ui.measure_btn.pressed.emit()
	check(game.sim.measured, "real measurement button completes measurement")
	game._start_judgment()
	await dialogue(game, {"telegram": 1 if expose else 3, "reason": reason})
	if game._came_from_departure:
		# Conversion arc D2: a first prologue run hands off to the epilogue, which has
		# its own suite. This probe is about the replay comparison, so it marks the
		# epilogue done and keeps the coda's lamp-out on the ordinary ending.
		root.get_node("Story").epilogue_done = true
		await wait_for(func(): return game.phase == game.Phase.CODA and not game._busy, "prologue run enters coda")
		await dialogue(game)
		game._interact("departure_workbook")
		await dialogue(game)
		game._interact("mentor_loupe")
		await dialogue(game)
	await wait_for(func(): return game.phase == game.Phase.ENDING, "reaction and coda finish at ending")


func ending_objects(game) -> void:
	var ui = game.ui
	check(ui.ending_slip is PanelContainer and ui.ending_telegram.get_parent() == ui.ending_slip, "telegram lives on the paper slip")
	check(ui.ending_telegram.text.contains(Judgment.TELEGRAMS[game._telegram].text)
		and ui.ending_telegram.text.contains("理由：" + game._reasons[game._reason].text), "slip keeps telegram words and chosen reason")
	check(ui.ending_telegram.text.contains("[font_size=%d][b]" % Settings.fs(30)), "telegram retains caps size and BBCode")
	check(not ui.ending_text.text.contains("[center]"), "workbook and comparison are left aligned")
	var candidates: Array = game.sim.included_usable() if game.sim.measured else []
	candidates.sort_custom(func(a, b): return a.stars > b.stars or (a.stars == b.stars and a.number < b.number))
	if candidates.is_empty():
		check(ui.ending_plate.texture != null and ui.ending_plate.texture == game.comparison_tex
			and ui.ending_plate_caption.text == "牛津比對底片", "unmeasured ending shows cached Oxford plate and caption")
	else:
		var index: int = game.sim.plates.find(candidates[0])
		check(ui.ending_plate.texture != null and ui.ending_plate.texture == game.plate_textures[index]
			and ui.ending_plate_caption.text == "第 %d 號底片" % candidates[0].number, "best measured plate uses viewer texture, most stars then lowest number")
	var old_size := root.size
	var old_canvas := root.content_scale_size
	var old_scale := Settings.text_scale
	var old_telegram: int = game._telegram
	# The two-line telegram must fit too, not only the shorter HOPEFUL text.
	game._telegram = 2
	for canvas in [Vector2i(1600, 900), Vector2i(1280, 720)]:
		root.content_scale_size = canvas
		root.size = canvas
		for scale in Settings.TEXT_SCALES:
			Settings.text_scale = scale
			Settings.refresh_fonts(self)
			game._show_ending()
			for frame in 8:
				await process_frame
			var context := "%s scale %s" % [canvas, scale]
			var objects: Array = [ui.ending_slip, ui.ending_plate_card]
			objects.append_array(ui.ending_replay.get_parent().get_children())
			for i in objects.size():
				var rect: Rect2 = objects[i].get_global_rect()
				check(root.get_visible_rect().encloses(rect), "ending object inside viewport: %d %s" % [i, context])
				for j in range(i):
					check(not rect.intersects(objects[j].get_global_rect()), "ending objects do not overlap: %d %d %s" % [i, j, context])
				if objects[i] is Button:
					objects[i].grab_focus()
					check(root.gui_get_focus_owner() == objects[i], "ending button accepts focus: %d %s" % [i, context])
			check(ui.ending_scroll.get_global_rect().encloses(ui.ending_slip.get_global_rect())
				and ui.ending_scroll.get_global_rect().encloses(ui.ending_plate_card.get_global_rect()), "slip and card clear scroll clipping: " + context)
			check(ui.ending_telegram.get_content_height() <= ui.ending_telegram.size.y + 1, "telegram text fits paper: " + context)
			check(ui.ending_objects.vertical == (canvas.x == 1280), "plate is left on wide canvas and above on narrow canvas: " + context)
			if canvas == Vector2i(1600, 900) and is_equal_approx(scale, 1.0) and not ui.ending_text.text.contains(HEADING):
				var content_rect := (ui.ending_center.get_child(0) as Control).get_global_rect()
				var button_top: float = ui.ending_replay.get_parent().get_global_rect().position.y
				var expected_center: float = (ui.ending_panel.get_global_rect().position.y + button_top) / 2.0
				var actual_center: float = content_rect.position.y + content_rect.size.y / 2.0
				check(ui.ending_scroll.get_v_scroll_bar().max_value <= ui.ending_scroll.size.y,
					"first ending content fits without scrolling: " + context)
				check(absf(actual_center - expected_center) <= 40.0, "short ending content is vertically centred: " + context)
				check(content_rect.end.y <= button_top, "centred ending content clears buttons: " + context)
			if canvas == Vector2i(1280, 720) and is_equal_approx(scale, 1.2) and ui.ending_text.text.contains(HEADING):
				var content_top: float = (ui.ending_center.get_child(0) as Control).get_global_rect().position.y
				check(absf(content_top - ui.ending_scroll.get_global_rect().position.y) <= 2.0,
					"tall comparison content starts at the scroll top: " + context)
				check(ui.ending_scroll.get_v_scroll_bar().max_value > ui.ending_scroll.size.y,
					"tall comparison ending has an effective scroll range: " + context)
				ui.ending_scroll.scroll_vertical = int(ui.ending_scroll.get_v_scroll_bar().max_value)
				await process_frame
				check(ui.ending_text.get_global_rect().end.y <= ui.ending_scroll.get_global_rect().end.y + 2.0,
					"scroll reaches the end of the tall comparison: " + context)
				for button in ui.ending_replay.get_parent().get_children():
					check(root.get_visible_rect().encloses(button.get_global_rect()), "tall comparison button is reachable: " + button.text)
					check(not button.get_global_rect().intersects(ui.ending_scroll.get_global_rect()), "tall comparison buttons clear scroll: " + button.text)
	root.size = old_size
	root.content_scale_size = old_canvas
	Settings.text_scale = old_scale
	game._telegram = old_telegram
	Settings.refresh_fonts(self)
	game._show_ending()
	for frame in 8:
		await process_frame


func layout(game) -> void:
	for frame in 5:
		await process_frame
	var ui = game.ui
	check(Settings.text_scale == 1.2 and ui.ending_text.get_theme_font_size("normal_font_size") == 23, "layout uses text scale 1.2")
	var viewport := root.get_visible_rect()
	var scroll_rect: Rect2 = ui.ending_scroll.get_global_rect()
	check(viewport.encloses(scroll_rect), "ending scroll fits 1600×900")
	check(ui.ending_replay.get_parent() is HFlowContainer, "#141 ending flow is preserved")
	var focus: Control = ui.ending_replay
	for i in ui.ending_replay.get_parent().get_child_count():
		focus.grab_focus()
		check(root.gui_get_focus_owner() == focus and viewport.encloses(focus.get_global_rect()), "ending button fits and accepts focus: " + focus.text)
		check(not scroll_rect.intersects(focus.get_global_rect()), "scroll clears ending button: " + focus.text)
		focus = focus.get_node(focus.focus_neighbor_right)
	check(focus == ui.ending_replay, "focus reaches every button and returns to replay")
	check(not ui.ending_review.visible and ui.ending_text.text.contains(HEADING), "comparison is outside collapsed review")
	var comparison: String = ui.ending_text.text.get_slice(HEADING + "[/b]\n", 1)
	var rows := comparison.substr(comparison.find("]") + 1).trim_suffix("[/font_size]").split("\n")
	check(rows.size() == 4, "comparison has all four rows")
	var probe: RichTextLabel = ui._rich(15)
	ui.ending_panel.add_child(probe)
	probe.size.x = ui.ending_text.size.x
	for row in rows:
		probe.text = row
		for frame in 3:
			await process_frame
		check(probe.get_line_count() <= 2, "comparison row wraps to at most two lines: " + row)
	probe.queue_free()
	# Scroll with the same input path as gamepad/keyboard while buttons keep focus.
	ui.ending_replay.grab_focus()
	for step in 100:
		var event := InputEventAction.new()
		event.action = "ui_down"
		event.pressed = true
		root.push_input(event)
		await process_frame
	var bar: VScrollBar = ui.ending_scroll.get_v_scroll_bar()
	check(bar.max_value <= bar.page or ui.ending_scroll.scroll_vertical > 0, "comparison fits or is reachable by scrolling from a focused button")
	var text_bottom: float = ui.ending_text.get_global_rect().end.y
	check(text_bottom <= scroll_rect.end.y + 1 and text_bottom > scroll_rect.position.y, "last comparison row is inside scroll after scrolling")


func _run() -> void:
	var story = root.get_node("Story")
	# This assertion also makes the production-revert check fail without a hang.
	if story.get("runs") == null:
		check(false, "completed experiment history exists")
		check(false, "ending comparison exists")
		print("REPLAY EXPERIMENT: %d checks, %d failures" % [checks, failures])
		quit(1)
		return
	var old_scale := Settings.text_scale
	var old_time_scale := Engine.time_scale
	Engine.time_scale = 20.0
	root.content_scale_size = Vector2i(1600, 900)
	root.size = Vector2i(1600, 900)
	load("res://scripts/main.gd").next_seed = 77
	var game = await new_game()
	Settings.text_scale = 1.2
	Settings.refresh_fonts(self)
	check(story.runs.is_empty(), "ordinary direct entry starts without history")
	await finish_run(game)
	await ending_objects(game)
	check(story.runs.size() == 1, "first completion records once")
	check(not game.ui.ending_text.text.contains(HEADING), "first ending has no comparison")
	var first: Dictionary = story.runs[0].duplicate(true)
	check(first.exposures.size() == 12 and first.combined.n > 0, "first record contains real exposures and measurement")
	for i in first.exposures.size():
		for key in ["number", "start", "duration", "included", "usable", "quality"]:
			check(first.exposures[i][key] == game.sim.plates[i][key], "snapshot keeps actual exposure %d %s" % [i, key])
	check(first.seed == 77 and first.reason_id == "measured" and first.telegram_id == "hopeful", "record captures seed and judgment IDs")
	check(first.reason_text == game._reasons[game._reason].text and first.score == game._grade.score and first.clean == game._grade.clean, "record captures actual displayed reason and grade")
	game._show_ending()
	check(story.runs.size() == 1, "repeated ending does not duplicate capture")
	game.ui.reselect_pressed.emit()
	for i in game.sim.plates.size():
		game.ui.plate_toggled.emit(i, not game.sim.plates[i].included)
	check(story.runs[0] == first, "snapshot is independent of later live selection edits")
	game = await replay(game)
	check(game.sim.run_seed == first.seed and story.runs[0] == first, "same-sky reload retains seed and immutable snapshot")
	check(game.ui.dialog_active() and game.ui._seq[0].t.contains("第 2 次試驗") and game.ui._seq[1].t.contains("同一片雲"), "replay opens acknowledged experiment framing")
	var prep_before: float = game.prep_left
	game._process_prep(1.0)
	check(game.prep_left == prep_before and not game.player.can_move, "replay framing pauses preparation")
	check(content.plan_text().any(func(line): return line.t == content.exposure_summary(first)), "plan includes previous exposure summary")
	await finish_run(game, 1, 0)
	check(story.runs.size() == 2 and story.runs[0] == first, "changed second run retains first snapshot")
	check(game.ui.ending_text.text.contains("選片規則改了"), "changed rule wording is compared")
	check(not game.ui.ending_text.text.contains("電報的理由改了") and story.runs[1].reason_text != first.reason_text, "same reason ID with new numerical text is not called a reason change")
	check(game.ui.ending_text.text.contains(content.run_value(first)) and game.ui.ending_text.text.contains(content.run_value(story.runs[1])), "both measured values are displayed")
	check(not game.ui.ending_text.text.get_slice(HEADING, 1).contains("評分") and not game.ui.ending_text.text.get_slice(HEADING, 1).contains("／4"), "comparison does not display grades")
	check(not game.ui.ending_text.text.get_slice(HEADING, 1).contains("證明"), "comparison never calls the results proof")
	await layout(game)
	var second: Dictionary = story.runs[1].duplicate(true)
	check(content.run_comparison(first, first).contains("誤差與上回相同"), "equal reported uncertainty wording")
	var narrower: Dictionary = first if first.combined.sigma < second.combined.sigma else second
	var wider: Dictionary = second if first.combined.sigma < second.combined.sigma else first
	check(content.run_comparison(wider, narrower).contains("這回的誤差較小") and content.run_comparison(narrower, wider).contains("這回的誤差較大"), "precision compares uncertainty in both directions")
	game = await replay(game, false)
	check(game.ui._seq[1].t.contains("天空換了；差異也可能來自雲況。"), "new-sky framing acknowledges weather")
	await finish_run(game, 0, 3, false)
	check(story.runs.size() == 3 and story.runs[2].combined == {"n": 0}, "zero-result completion preserves n=0 without invented numbers")
	await ending_objects(game)
	check(game.ui.ending_text.text.contains("這回：沒有量出數值。") and game.ui.ending_text.text.contains("電報的理由改了"), "missing measurement and changed reason ID are explicit")
	check(content.run_comparison(story.runs[2], first).contains("上回：沒有量出數值。"), "missing previous measurement is explicit")
	game.queue_free()
	await process_frame
	story.prologue_done = true
	story.departure_done = true
	story.plan = ["comparison"]
	story.bond_tone = "warm"
	game = await new_game(true)
	check(game._came_from_departure and story.prologue_done and story.runs.size() == 3, "prologue entry preserves continuity")
	# New chapter entry normally resets Story in Cambridge; exercise that reset here.
	story.reset()
	check(story.runs.is_empty(), "ordinary reset clears session history")
	story.prologue_done = true
	story.departure_done = true
	story.plan = ["comparison"]
	story.bond_tone = "warm"
	await finish_run(game, 0, 3, false)
	game = await replay(game)
	check(game._came_from_departure and story.prologue_done and story.departure_done and story.bond_tone == "warm" and story.plan == ["comparison"], "prologue replay preserves chapter continuity")
	check(story.runs.size() == 1 and story.kit_first == -1, "prologue replay retains completed run and resets Kit's first reply")
	await dialogue(game)
	game.queue_free()
	await process_frame
	check(story.runs.size() == 1, "abandoned replay is not recorded")
	game = await new_game()
	check(story.runs.is_empty() and not story.prologue_done, "ordinary direct entry clears history and prologue")
	game.queue_free()
	await process_frame
	Settings.text_scale = old_scale
	Engine.time_scale = old_time_scale
	print("REPLAY EXPERIMENT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
