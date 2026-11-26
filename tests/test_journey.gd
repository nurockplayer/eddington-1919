extends SceneTree
## Drive the Cambridge coda handoff using the actual montage, dialogue and paper buttons.
## With --journey-captures=<dir>, save the paper states for art review.

const C17 := preload("res://scripts/cambridge/content_1917.gd")
const Departure := preload("res://scripts/cambridge/content_departure.gd")
const Content := preload("res://scripts/cambridge/content_tribunal.gd")
const Madeira := preload("res://scripts/cambridge/content_madeira.gd")
const Sundy := preload("res://scripts/cambridge/content_sundy.gd")
const Report := preload("res://scripts/cambridge/report_sheet.gd")
const Settings := preload("res://scripts/settings.gd")

const CAMBRIDGE := "res://scenes/cambridge.tscn"
const DEPARTURE := "res://scenes/departure.tscn"
const OBSERVATION_DAY := "res://scenes/main.tscn"
const TRAY := ["D1", "C1", "R1", "C2", "D2", "R2", "D3", "C3", "R3"]
const SLOTS := ["T04", "T05", "T06", "T05", "T04", "T06", "T04", "T05", "T06"]
const BEFORE_PACKET := [
	"T01", "T02", "T09", "T11", "T15", "T19", "T77", "T78", "T79", "T80", "T81",
	"T23", "T24", "T25", "T29",
	"T31", "T33", "T35", "T36", "T40", "T38", "T40", "T42", "T44", "T45",
	"T46", "T48", "T50", "T52", "T54", "T55",
]

var checks := 0
var capture_dir := ""
var madeira_captures := false
var sundy_captures := false
var temp_settings := ""


func _initialize() -> void:
	_run.call_deferred()


func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		quit(1)
	assert(ok, message)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func tap(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.physical_keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame


func tap_pad(button_index: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button_index
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame


func press(button: Button) -> void:
	expect(not button.disabled and button.is_visible_in_tree(), "enabled button: " + button.text)
	button.grab_focus()
	await tap(KEY_ENTER)


func button(paper: Control, text: String) -> Button:
	for item in paper.find_children("*", "Button", true, false):
		if item.text == text:
			return item
	assert(false, "missing control: " + text)
	return null


func has_text(paper: Control, text: String) -> bool:
	return paper.find_children("*", "Label", true, false).any(func(label): return label.text == text)


func check_paper_focus(control: Button) -> void:
	expect(control.has_focus(), "paper button has focus: " + control.text)
	expect(control.get_theme_color("font_focus_color") == Report.INK,
		"focused paper button uses ink: " + control.text)


func check_paper_layout(paper: Control, state: String) -> void:
	await frames(3)
	var failures: Array[String] = []
	var footer_height := 0.0
	for action: Button in paper.actions.get_children():
		var font := action.get_theme_font("font")
		var font_size := action.get_theme_font_size("font_size")
		var text_size := font.get_string_size(action.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var minimum := text_size + action.get_theme_stylebox("normal").get_minimum_size()
		footer_height = maxf(footer_height, minimum.y)
		if action.size.x + 1.0 < minimum.x:
			failures.append("collapsed footer button: " + action.text)
	var scroll: ScrollContainer = paper.body.get_parent()
	var layout: VBoxContainer = scroll.get_parent()
	var available := layout.get_global_rect().end.y - scroll.global_position.y - footer_height - layout.get_theme_constant("separation")
	if scroll.size.y + 1.0 < minf(paper.body.size.y, available) or paper.body.size.x > scroll.size.x + 1.0:
		failures.append("paper body clipped before available space is used")
	var previous := scroll.scroll_vertical
	if paper.body.size.y > scroll.size.y + 1.0:
		scroll.scroll_vertical = ceili(scroll.get_v_scroll_bar().max_value)
		await frames(2)
	var tail: Control = paper.body.get_child(-1)
	if not scroll.get_global_rect().grow(1.0).encloses(tail.get_global_rect()):
		failures.append("last paper row cannot fit or scroll fully into view")
	scroll.scroll_vertical = previous
	expect(failures.is_empty(), "%s %s scale %.1f: %s" % [L.current(), state, Settings.text_scale, "; ".join(failures)])


func check_madeira_scroll(paper: Control, finish_with_pad: bool) -> void:
	var scroll: ScrollContainer = paper.body.get_parent()
	var bar := scroll.get_v_scroll_bar()
	var end := floori(bar.max_value - bar.page)
	var advance: Button = paper.actions.get_child(0)
	expect(end > 0 and advance.has_focus(), "overflowing Madeira paper starts with its continue button focused")
	scroll.scroll_vertical = 0
	await tap(KEY_DOWN)
	expect(scroll.scroll_vertical > 0, "Down arrow scrolls the Madeira paper")
	await tap(KEY_UP)
	expect(scroll.scroll_vertical == 0, "Up arrow scrolls the Madeira paper back to the top")
	await tap_pad(JOY_BUTTON_DPAD_DOWN)
	expect(scroll.scroll_vertical > 0, "D-pad Down scrolls the Madeira paper")
	await tap_pad(JOY_BUTTON_DPAD_UP)
	expect(scroll.scroll_vertical == 0, "D-pad Up scrolls the Madeira paper back to the top")
	while scroll.scroll_vertical < end:
		var previous := scroll.scroll_vertical
		if finish_with_pad:
			await tap_pad(JOY_BUTTON_DPAD_DOWN)
		else:
			await tap(KEY_DOWN)
		expect(scroll.scroll_vertical > previous, "scroll input keeps moving toward the end of the Madeira paper")
	await frames(2)
	var tail: Control = paper.body.get_child(-1)
	expect(advance.has_focus() and scroll.get_global_rect().grow(1.0).encloses(tail.get_global_rect()),
		"scroll input reveals the last Madeira line and leaves continue focused")


func _run() -> void:
	var enabled := OS.get_cmdline_user_args().has("--journey")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--journey-captures="):
			capture_dir = arg.trim_prefix("--journey-captures=")
		elif arg.begins_with("--madeira-captures="):
			capture_dir = arg.trim_prefix("--madeira-captures=")
			madeira_captures = true
		elif arg.begins_with("--sundy-captures="):
			capture_dir = arg.trim_prefix("--sundy-captures=")
			sundy_captures = true
	Engine.time_scale = 8.0 if capture_dir.is_empty() else 2.0
	root.size = Vector2i(1280, 720) if capture_dir.is_empty() else Vector2i(1920, 1080)
	if capture_dir.is_empty():
		var directory := "%s/edd-journey-%d" % [OS.get_temp_dir(), OS.get_process_id()]
		expect(DirAccess.make_dir_absolute(directory) == OK, "create isolated checkpoint directory")
		temp_settings = directory.path_join("settings.cfg")
		OS.set_environment("EDD_SETTINGS_PATH", temp_settings)
		var settings := ConfigFile.new()
		settings.set_value("ui", "text_scale", 1.2)
		settings.set_value("ui", "reduced_motion", true)
		expect(settings.save(temp_settings) == OK, "save isolated test settings")
		Checkpoint.force_enabled = true
	var locales := ["en", "ja", "zh_TW", "ko"] if enabled else ["zh_TW"]
	if madeira_captures or sundy_captures:
		locales = ["en", "ja"]
	# Retain the packed resources across locales. The directors still create fresh scenes.
	var route: Array[PackedScene] = [load(CAMBRIDGE), load(DEPARTURE), load(OBSERVATION_DAY)]
	for locale in locales:
		L.apply(locale)
		await _route(route, enabled, locale == "ja")
	if capture_dir.is_empty():
		Checkpoint.clear()
		DirAccess.remove_absolute(Settings.settings_path())
		DirAccess.remove_absolute(temp_settings.get_base_dir())
	print("test_journey %s: %d checks, 0 failures" % ["on" if enabled else "off", checks])
	quit()


func _route(route: Array[PackedScene], enabled: bool, misfile: bool) -> void:
	expect(change_scene_to_packed(route[0]) == OK, "load real Cambridge scene")
	await scene_changed
	var director := current_scene
	while not director.ui.dialog_active():
		await process_frame
	var story := root.get_node("Story")
	story.from_prologue = true
	story.bet_1917 = {"pick": 3, "sure": 2, "ashby": 0.87, "year": 1917}
	story.bet = {"pick": 1, "sure": 1, "year": 1919}
	story.report = {"cause": "swap"}
	story.plan = ["far_stars"]
	await director._coda()
	while director.ui.dialog_active():
		var line: Dictionary = director.ui._seq[director.ui._seq_i]
		match line.get("key", ""):
			"kit_choice": await tap(KEY_2)
			"want": await tap(KEY_3)
			_: await tap(KEY_ENTER)
	expect(story.kit_choice == 1 and story.want == 2, "coda commits both decisions")
	var expected: Dictionary = story.to_save()
	expected.prologue_done = true
	var captions := C17.montage()
	for i in (2 if enabled else 3):
		while is_instance_valid(director) and director._caption_elapsed < 1.2:
			await process_frame
		expect(is_instance_valid(director), "montage card %d is present" % i)
		expect(director.ui.caption.text.begins_with(captions[i].t), "montage card %d is unchanged" % i)
		await tap(KEY_ENTER)
		while is_instance_valid(director) and director._caption_elapsed >= 0.0:
			await process_frame
	if enabled:
		while is_instance_valid(director) and director.get("tribunal") == null:
			await process_frame
		expect(is_instance_valid(director) and director.get("tribunal") != null,
			"--journey must enter Tribunal before departure")
		await _tribunal(director, misfile)
	else:
		expect(director.get("tribunal") == null, "flag off creates no chapter")
	if current_scene == null or current_scene.scene_file_path != route[1].resource_path:
		await scene_changed
	expect(current_scene.scene_file_path == route[1].resource_path, "route loads existing M2 scene")
	expect(story.to_save() == expected, "only prologue completion changes saved M1 state")
	if Checkpoint.force_enabled:
		expect(Checkpoint.peek() == "departure", "handoff writes the departure checkpoint")
		story.reset()
		expect(Checkpoint.restore() == "departure" and story.to_save() == expected,
			"departure checkpoint restores M1 state verbatim")
		Checkpoint.clear()
	while current_scene.ui.caption.text != Departure.intro_caption():
		await process_frame
	expect(current_scene.ui.caption.text == Departure.intro_caption(), "existing M2 opening plays")
	while not current_scene.ui.dialog_active():
		await process_frame
	if capture_dir.is_empty() or madeira_captures:
		await _departure(current_scene, route[2], enabled, misfile)


func _tribunal(director: Node, misfile: bool) -> void:
	var journey: Node = director.tribunal
	var paper: Control = journey.paper
	var strings := Content.strings()
	var bench_speakers := {
		"T77": "T76", "T78": Content.Cast.MENTOR, "T79": Content.Cast.YOU,
		"T80": "T76", "T81": Content.Cast.KIT,
	}
	while director.ui.fade.color.a > 0.0:
		await process_frame
	await frames(2)
	for id in BEFORE_PACKET:
		expect(journey.page_id == id, "expected %s, got %s" % [id, journey.page_id])
		if bench_speakers.has(id):
			expect(not paper.visible and director.ui.dialog_active(), "private exchange follows closed sourced slips")
			var speaker: String = bench_speakers[id]
			expect(director.ui.speaker_label.text == (strings.T76 if speaker == "T76" else L.t(speaker))
				and director.ui.text_label.text == strings[id],
				"private bench exchange shows its speaker and line: " + id)
			await tap(KEY_ENTER)
		elif director.ui.dialog_active():
			if id == "T19":
				expect(has_text(paper, strings.T11) and has_text(paper, strings.T13), "both claims stay in view")
			while director.ui.dialog_active() and journey.page_id == id:
				await tap(KEY_ENTER)
		else:
			if id == "T29":
				check_paper_focus(button(paper, strings.T22))
				if capture_dir.is_empty() or L.current() in ["en", "ja"]:
					await capture("hearing", paper)
			if id == "T54":
				expect(has_text(paper, strings.T54), "July condition has its own page")
			await press(button(paper, strings[id] if id in ["T24", "T45"] else strings.T22))
	expect(journey.page_id == "packet", "packet follows the July pages")
	expect(Checkpoint.peek() == "", "checkpoint is deferred until I12")
	await check_paper_layout(paper, "packet")
	await capture("packet", paper)
	if L.current() == "en":
		expect(not strings.values().any(func(line): return "’" in line), "use proportional English apostrophes on the tribunal and Armistice pages")
		if not capture_dir.is_empty() and not madeira_captures and not sundy_captures:
			root.size = Vector2i(1280, 720)
			Settings.text_scale = 1.2
			Settings.refresh_fonts(self)
			await check_paper_layout(paper, "720p packet")
			await capture("packet", paper, "_720p", Vector2i(1280, 720))
			root.size = Vector2i(1920, 1080)
			Settings.text_scale = 1.0
			Settings.refresh_fonts(self)
			await frames(3)
	for i in TRAY.size():
		var card: String = TRAY[i]
		var extract: Dictionary = Content.EXTRACTS[card]
		var title: String = strings[extract.lines[0]]
		var source: String = strings[extract.source]
		var tray_card := button(paper, title)
		expect(tray_card.has_focus(), "next tray card has focus: " + card)
		await press(button(paper, strings.T57))
		expect(has_text(paper, source), "extract carries its source: " + card)
		expect(button(paper, strings.T59).disabled, "file waits for a heading")
		if i == 1:
			check_paper_focus(button(paper, strings.T04))
			if L.current() == "en" and not capture_dir.is_empty():
				await capture("packet_open", paper)
		if i == 0:
			await press(button(paper, strings.T58))
			expect(journey.filed.is_empty() and button(paper, title).has_focus(), "back leaves the extract in the tray")
			await press(button(paper, strings.T57))
		if misfile:
			var wrong: Array = ["T04", "T05", "T06"].filter(func(slot): return slot != SLOTS[i])
			for slot in wrong:
				await press(button(paper, strings[slot]))
				await press(button(paper, strings.T59))
				expect(journey.page_id == extract.hint and director.ui.text_label.text == strings[extract.hint],
					"wrong heading has the matching Kit hint: " + card)
				await tap(KEY_ENTER)
				expect(journey.filed.size() == i and button(paper, title).has_focus(),
					"wrong heading leaves the tray and focus unchanged: " + card)
				await press(button(paper, strings.T57))
			await press(button(paper, strings[wrong[0]]))
		await press(button(paper, strings[SLOTS[i]]))
		await press(button(paper, strings.T59))
		expect(journey.filed.get(card) == SLOTS[i] and has_text(paper, strings.T60),
			"correct heading files the extract: " + card)
		if i == 0 and L.current() == "en" and not capture_dir.is_empty():
			await capture("packet_filed", paper)
		expect(paper.find_children("*", "Button", true, false).any(func(b): return b.text == strings.T70) == (i == 8),
			"close becomes available after all nine extracts")
	await press(button(paper, strings.T52))
	await press(button(paper, strings.T57))
	expect(has_text(paper, strings.L) and has_text(paper, strings.T54), "rereading the ruling retains its citation and condition")
	expect(not paper.find_children("*", "Button", true, false).any(func(b): return b.text == strings.T59),
		"filed extract is read-only")
	await press(button(paper, strings.T58))
	await press(button(paper, strings.T70))
	for id in ["T71", "T72", "T74", "T75"]:
		expect(journey.page_id == id, "ledger sequence: " + id)
		if id == "T72":
			expect(has_text(paper, Content.ledger(strings, root.get_node("Story").bet_1917)), "ledger uses saved uncertain prediction")
			expect(has_text(paper, strings.T73), "ledger displays Ashby's own entry")
			await press(button(paper, strings.T22))
		else:
			await tap(KEY_ENTER)
	expect(journey.page_id == "T82" and director.ui.dialog_active(), "Ashby returns to the ledger after the packet")
	expect(paper.visible and has_text(paper, strings.T73)
		and has_text(paper, Content.ledger(strings, root.get_node("Story").bet_1917)), "both entries stay open")
	for id in ["T82", "T83"]:
		expect(director.ui.speaker_label.text == L.t(Content.Cast.MENTOR)
			and director.ui.text_label.text == strings[id], "Ashby speaks beside the ledger: " + id)
		await tap(KEY_ENTER)
	expect(journey.page_id == "I01" and has_text(paper, strings.I05), "Armistice begins with the public report")
	expect(Checkpoint.peek() == "", "first Armistice page still has no checkpoint")
	await check_paper_layout(paper, "armistice")
	check_paper_focus(button(paper, strings.T22))
	await capture("armistice", paper)
	await press(button(paper, strings.T22))
	expect(journey.page_id == "I08" and has_text(paper, strings.I11), "Armistice ends with the Observatory's loss")
	await check_paper_layout(paper, "second armistice page")
	check_paper_focus(button(paper, strings.I12))
	await press(button(paper, strings.I12))


func capture(state: String, paper: Control, suffix := "", dimensions := Vector2i(1920, 1080)) -> void:
	await frames(3)
	for action in paper.actions.get_children():
		expect(root.get_visible_rect().grow(1.0).encloses(action.get_global_rect()), "paper controls stay in bounds: " + state)
	if capture_dir.is_empty() or (madeira_captures and not state.begins_with("madeira_")) or (
		sundy_captures and not (state.begins_with("sundy_") or state.begins_with("i3_"))):
		return
	await RenderingServer.frame_post_draw
	expect(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED, "capture stays windowed")
	var image := root.get_texture().get_image()
	expect(image.get_size() == dimensions, "capture is %s, got %s" % [dimensions, image.get_size()])
	var filename := state + "_" + L.current() + suffix + ".png"
	expect(image.save_png(capture_dir.path_join(filename)) == OK, "write " + filename)
	var receipt := FileAccess.open(capture_dir.path_join("index.md"), FileAccess.READ_WRITE)
	receipt.seek_end()
	var jst := Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()) + 9 * 3600).replace("T", " ") + " JST"
	receipt.store_line("| [%s](%s) | %s | %s | %d×%d | %.2f | %s | %s |" % [
		filename, filename, state, L.current(), dimensions.x, dimensions.y, Settings.text_scale, Settings.reduced_motion, jst])
	print("saved ", filename)


func _departure(chapter: Node, observation_day: PackedScene, enabled: bool, warm: bool) -> void:
	var story := root.get_node("Story")
	await _dialogue(chapter)
	chapter._interact("lightbox")
	var sheet: Control = chapter.checklist
	for i in sheet.entries.size():
		await _dialogue(chapter)
		await press(sheet.row_buttons[i][1 if i == 2 else 0])
	await _dialogue(chapter, {"slip_fix": KEY_2})
	while sheet.continue_btn.disabled:
		await process_frame
	await press(sheet.continue_btn)
	chapter._interact("kit")
	await _dialogue(chapter, {"bond": KEY_2 if warm else KEY_1, "promise": KEY_1})
	chapter._interact("mentor")
	await _dialogue(chapter, {"gift": KEY_1})
	var sketch: Control = chapter.box_sketch
	await press(sketch.guess_btns[2])
	for i in 2:
		if i == 1:
			await press(sketch.frame_btns[1])
		await press(sketch.release_btn)
		while sketch.release_btn.disabled:
			await process_frame
	await press(sketch.next_btn)
	await _dialogue(chapter, {"light_box": KEY_1})
	expect(chapter.keepsake.visible, "Ashby's real farewell shows the gift")
	var previous: Dictionary = story.to_save()
	expect(previous.slip_fix == 1 and previous.bond_tone == ("warm" if warm else "close"),
		"M2 has a correction and a bond tone to carry forward")
	if enabled:
		while is_instance_valid(chapter) and chapter.madeira == null and chapter.ui.caption.text == Departure.intro_caption():
			await process_frame
		expect(is_instance_valid(chapter) and chapter.madeira != null, "--journey must enter Madeira after M2")
		await _madeira(chapter.madeira, chapter, warm)
		for frame in 150:
			if not is_instance_valid(chapter) or chapter.get("sundy") != null:
				break
			await process_frame
		expect(is_instance_valid(chapter) and chapter.get("sundy") != null, "I2 must enter Sundy before observation day")
		await _sundy(chapter.sundy, chapter, warm)
	else:
		for entry in Departure.montage():
			while is_instance_valid(chapter) and not chapter.ui.caption.text.begins_with(entry.t):
				await process_frame
			expect(is_instance_valid(chapter) and chapter.madeira == null and
				chapter.ui.caption.text.begins_with(entry.t), "flag off retains M2 caption " + entry.t)
	if is_instance_valid(chapter):
		await scene_changed
	expect(current_scene.scene_file_path == observation_day.resource_path, "the route reaches the existing observation day")
	expect(current_scene._came_from_departure and story.departure_done, "arrival has the full-story origin")
	expect(current_scene.phase == current_scene.Phase.PREP and not current_scene.sim.drive_wound,
		"observation day begins in PREP with its own unwound drive")
	previous.departure_done = true
	previous.from_prologue = true
	if Checkpoint.force_enabled:
		expect(Checkpoint.peek() == "principe", "the existing checkpoint is written at the slice handoff")
		expect(Checkpoint.restore() == "principe" and story.to_save() == previous,
			"the handoff preserves the prediction, certainty and M2 choices verbatim")
		Checkpoint.clear()


func _dialogue(chapter: Node, choices := {}) -> void:
	while chapter.ui.dialog_active():
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		await tap(choices.get(entry.key, KEY_1) if entry.has("choices") else KEY_ENTER)


func _check_lines(paper: Control, strings: Dictionary, ids: Array) -> void:
	for id in ids:
		expect(has_text(paper, strings[id]), "%s shows %s" % [L.current(), id])


func _madeira(journey: Node, chapter: Node, warm: bool) -> void:
	var text := Madeira.strings()
	var paper: Control = journey.paper
	var story := root.get_node("Story")
	while chapter.ui.fade.color.a > 0.0 or paper.actions.get_child_count() == 0:
		await process_frame
	for id in ["M01", "M04", "M80", "M81", "M05", "M82", "M06", "M83", "M84", "M07", "M10", "M12"]:
		expect(journey.page_id == id, "arrival order: " + id)
		_check_lines(paper, text, [id])
		if id == "M06":
			_check_lines(paper, text, ["M01", "M02", "M03", "M04", "M05"])
			await check_paper_layout(paper, "Madeira arrival")
		if id == "M12":
			_check_lines(paper, text, ["M13"])
		await press(button(paper, text.M09))
	while paper.actions.get_child_count() == 0:
		await process_frame
	_check_lines(paper, text, ["M14", "M15"])
	await press(button(paper, text.M09))
	expect(chapter.ui.dialog_active() and journey.page_id == "M17", "empty place precedes Ashby's memory")
	await tap(KEY_ENTER)
	await press(button(paper, text.M18))
	expect(Checkpoint.peek() != "principe" and not story.departure_done,
		"Madeira remains before the departure handoff")
	expect(button(paper, text.M21).disabled and button(paper, text.M22).disabled, "folders wait for a selection")
	await press(button(paper, text.M25))
	await press(button(paper, text.M26))
	expect(journey.selected == "M26" and journey.filed.is_empty(), "another loose row changes only the selection")
	await tap(KEY_ESCAPE)
	expect(journey.selected.is_empty() and button(paper, text.M26).has_focus(), "cancel returns focus to the loose row")
	var order := [2, 3, 0, 1] if warm or madeira_captures else [0, 3, 1, 2]
	for i in order.size():
		var index: int = order[i]
		var id: String = Madeira.LOOSE[index]
		var folder := "M21" if index in [0, 3] else "M22"
		await press(button(paper, text[id]))
		if warm:
			await press(button(paper, text.M22 if folder == "M21" else text.M21))
			expect(journey.selected == id and journey.filed.size() == i, "wrong folder keeps the row loose")
			_check_lines(paper, text, [Madeira.CORRECTIONS[id]])
		await press(button(paper, text[folder]))
		expect(journey.selected.is_empty() and journey.filed.get(id) == folder, "correct folder matches " + id)
		_check_lines(paper, text, ["M31"])
		if i < 3:
			var next := (index + 1) % Madeira.LOOSE.size()
			while journey.filed.has(Madeira.LOOSE[next]):
				next = (next + 1) % Madeira.LOOSE.size()
			expect(button(paper, text[Madeira.LOOSE[next]]).has_focus(), "advances focus to next loose row")
	await check_paper_layout(paper, "Madeira completed copies")
	var copies: HBoxContainer = paper.body.get_child(2)
	for index in 2:
		var folder: String = Madeira.COPIES.keys()[index]
		_check_lines(copies.get_child(index), text, ["M19", folder] + Madeira.COPIES[folder] + ["M29", "M30"])
	_check_lines(paper, text, ["M36", "M37"])
	if madeira_captures:
		check_paper_focus(button(paper, text.M38))
		await capture("madeira_worktable", paper)
	if L.current() == "en":
		await check_madeira_scroll(paper, false)
		if madeira_captures:
			await capture("madeira_worktable", paper, "_end")
			var scroll: ScrollContainer = paper.body.get_parent()
			scroll.scroll_vertical = 0
			root.size = Vector2i(1280, 720)
			Settings.text_scale = 1.2
			Settings.refresh_fonts(self)
			await check_paper_layout(paper, "720p Madeira worktable")
			await capture("madeira_worktable", paper, "_720p", Vector2i(1280, 720))
			root.size = Vector2i(1920, 1080)
			Settings.text_scale = 1.0
			Settings.refresh_fonts(self)
	await press(button(paper, text.M38))
	_check_lines(paper, text, ["M39"] + Madeira.SOBRAL)
	await press(button(paper, text.M44))
	await press(button(paper, text.M45))
	expect(chapter.ui.dialog_active() and journey.page_id == "M47", "Kit's sky promise is remembered at the window")
	await tap(KEY_ENTER)
	_check_lines(paper, text, ["M46", "M50", "M48" if warm else "M49"])
	expect(has_text(paper, L.t("1919 年 5 月 29 日")), "the dated blank leaf is separate")
	await press(button(paper, text.M51))
	_check_lines(paper, text, ["M71", "M72", "M73", "M74", "M75" if warm else "M76"])
	await press(button(paper, text.M77))
	_check_lines(paper, text, ["M78", "M79", "M50"])
	await press(button(paper, text.M09))
	_check_lines(paper, text, ["M52", "M53", "M54", "M55", "M56"])
	await press(button(paper, text.M09))
	_check_lines(paper, text, ["M57"])
	await press(button(paper, text.M09))
	_check_lines(paper, text, ["M58"])
	await press(button(paper, text.M09))
	_check_lines(paper, text, ["M59", "M60", "M61"])
	await press(button(paper, text.M09))
	_check_lines(paper, text, ["M62", "M63"])
	await press(button(paper, text.M64))
	_check_lines(paper, text, ["M65", "M66", "M67", "M68", "M69"])
	while paper.actions.get_child_count() == 0:
		await process_frame
	await check_paper_layout(paper, "Madeira dockside")
	if madeira_captures and L.current() == "en":
		await create_timer(0.65).timeout
		check_paper_focus(button(paper, text.M70))
		await capture("madeira_dockside", paper)
	await press(button(paper, text.M70))
	expect(story.departure_done and story.from_prologue and Checkpoint.peek() != "principe",
		"I2 follows departure completion before the slice checkpoint")
	for id in Madeira.PASSAGE:
		expect(journey.page_id == id, "onward stop in order: " + id)
		_check_lines(paper, text, [id])
		await press(button(paper, text.I07 if id == "I06" else text.M09))
	_check_lines(paper, text, ["I01", "I02", "I06", "I08", "I09", "I11"])
	if L.current() != "en":
		expect(has_text(paper, Madeira.QUOTES.I09), "translated passage retains original excerpt")
	await check_paper_layout(paper, "onward passage letter")
	if L.current() in ["en", "ja"]:
		await check_madeira_scroll(paper, true)
	if madeira_captures:
		check_paper_focus(button(paper, text.I10))
		await capture("madeira_onward_passage", paper, "_end")
	await press(button(paper, text.I10))


func _sundy(journey: Node, chapter: Node, warm: bool) -> void:
	var text := Sundy.strings()
	var onward: String = Madeira.strings().M09
	var paper: Control = journey.paper
	while not paper.actions.visible:
		await process_frame
	await _sundy_sheet(paper, "sundy_01_title", [text.S01], onward)
	await _sundy_sheet(paper, "sundy_02_shore", [text.S04, text.S05], text.S06)
	await _sundy_sheet(paper, "sundy_03_esperanca", [text.S09], onward)
	expect(not has_text(paper, text.S12), "the site is only revealed after the other two visits")
	await _sundy_sheet(paper, "sundy_04_sao_joaquim", [text.S10, text.S11], onward)
	await _sundy_sheet(paper, "sundy_05_sundy_choice", [text.S12], text.S13, true)
	await _sundy_sheet(paper, "sundy_06_track_end", [text.S15, text.S16, text.S17], onward)
	await _sundy_sheet(paper, "sundy_07_cargo_arrival", [text.S18, text.S19], text.S20)
	await _sundy_sheet(paper, "sundy_08_work_record", [text.S22, text.S23, text.S24, text.S25], text.S26)
	await _sundy_sheet(paper, "sundy_09_packed_mirror", [text.S28], onward)
	await _sundy_sheet(paper, "sundy_10_station", [text.S30, text.S31, text.S32, text.S33, text.S34], text.S35)
	await _sundy_sheet(paper, "sundy_11_field_records", [text.S37, text.S38, text.S39, text.S40], text.S43)
	await _sundy_sheet(paper, "sundy_12_kit_letter", [text.S86, text.S87, text.S88], onward)
	expect(chapter.ui.dialog_active() and chapter.ui.text_label.text == text.S47, "Ashby's remembered instruction precedes the rehearsal")
	if sundy_captures:
		await capture("sundy_13_ashby_memory", paper)
	await _dialogue(chapter)
	await _sundy_pair(journey, text, "first", [0, 1, 2, 3], "S64", "S67", "S70", "S73")
	await _sundy_pair(journey, text, "repeat", [0, 1, 2, 3], "S63", "S68", "S71", "S74")
	while not has_text(paper, text.S59) or not paper.actions.visible:
		await process_frame
	await _sundy_sheet(paper, "sundy_14_cloud_crossing", [text.S59], onward)
	await _sundy_pair(journey, text, "clouded", [0, -1, 2, -1], "S65", "S69", "S72", "S75")
	expect(journey.accepted_log == ["S70", "S71", "S72"], "three accepted logs remain in order")
	await _sundy_sheet(paper, "sundy_15_clear_horizon", [], text.S76)
	await _sundy_sheet(paper, "sundy_16_clouded_day", [text.S77], text.S78)
	expect(chapter.ui.dialog_active() and chapter.ui.text_label.text == text.S79, "Kit remembers the room left on the page")
	if sundy_captures:
		await capture("sundy_17_kit_memory", paper)
	await tap(KEY_ENTER)
	expect(chapter.ui.text_label.text == text.S80, "Kit asks what was seen at Sundy")
	await _dialogue(chapter)
	await _sundy_sheet(paper, "sundy_18_workbook", [
		text.S81, text.S82 if warm else text.S83, text.S89, text.S90 if warm else text.S91,
		L.t("1919 年 5 月 29 日")], text.S84)
	while not paper.actions.visible:
		await process_frame
	await _sundy_sheet(paper, "i3_01_paired_cables", [
		text["I3-02"], text["I3-03"], "Through cloud, hopeful",
		text["I3-05"], "Eclipse splendid. Crommelin", text["I3-04"], text["I3-06"]], onward)
	await _sundy_sheet(paper, "i3_02_nature_clipping", [
		text["I3-08"], text["I3-09"], text["I3-10"], text["I3-11"], text["I3-12"], text["I3-13"]], onward)
	await _sundy_sheet(paper, "i3_03_brazil_press", [
		text["I3-15"], text["I3-16"], text["I3-17"]], text["I3-14"])


func _sundy_sheet(paper: Control, state: String, lines: Array, advance: String, scroll_probe := false) -> void:
	for line in lines:
		expect(has_text(paper, line), state + " shows " + line)
	if paper.body.get_child_count() > 0:
		await check_paper_layout(paper, state)
	var next := button(paper, advance)
	check_paper_focus(next)
	if scroll_probe:
		var scroll: ScrollContainer = paper.body.get_parent()
		if scroll.get_v_scroll_bar().visible:
			await tap(KEY_DOWN)
			expect(scroll.scroll_vertical > 0 and next.has_focus(), "Down scrolls the Sundy sheet")
			await tap(KEY_UP)
			expect(scroll.scroll_vertical == 0, "Up scrolls the Sundy sheet to the beginning")
			await tap_pad(JOY_BUTTON_DPAD_DOWN)
			expect(scroll.scroll_vertical > 0 and next.has_focus(), "D-pad Down scrolls the Sundy sheet")
			await tap_pad(JOY_BUTTON_DPAD_UP)
			expect(scroll.scroll_vertical == 0, "D-pad Up scrolls the Sundy sheet to the beginning")
	await _sundy_frames(state, paper)
	await press(next)


func _sundy_frames(state: String, paper: Control, suffix := "", dimensions := Vector2i(1920, 1080)) -> void:
	if not sundy_captures:
		return
	var scroll: ScrollContainer = paper.body.get_parent()
	scroll.scroll_vertical = 0
	await capture(state, paper, suffix, dimensions)
	if scroll.get_v_scroll_bar().visible:
		scroll.scroll_vertical = ceili(scroll.get_v_scroll_bar().max_value)
		await capture(state, paper, suffix + "_end", dimensions)


func _sundy_pair(journey: Node, text: Dictionary, state: String, marks: Array, judgment: String,
		reason: String, log: String, advance: String) -> void:
	var paper: Control = journey.paper
	var plate: Control = journey.plate
	var compare := button(paper, text.S52)
	var submit := button(paper, text[judgment])
	expect(has_text(paper, text.S44) and has_text(paper, text.S45), "the active plate and log are labelled as simulation")
	expect(has_text(paper, text.S50) and submit.disabled, "pair starts on A with judgment locked")
	check_paper_focus(compare)
	await _sundy_frames("sundy_check_" + state + "_a", paper)
	await press(compare)
	expect(has_text(paper, text.S51) and plate.exposure_b and submit.disabled, "B alone does not enable judgment")
	expect(plate.targets.size() == 4 - marks.count(-1), "only sharp centres have targets")
	check_paper_focus(compare)
	await _sundy_frames("sundy_check_" + state + "_b", paper)
	if state == "first":
		await press(button(paper, text.S54 % 1))
		expect(plate.targets[1].has_focus(), "topmost sharp centre gains focus first")
		await tap_pad(JOY_BUTTON_DPAD_DOWN)
		expect(plate.targets[0].has_focus(), "D-pad follows the visible centres top to bottom")
		await tap(KEY_UP)
		expect(plate.targets[1].has_focus(), "Up returns focus to the top centre")
		await press(plate.targets[1])
		expect(plate.marks[0] == 1, "a player can mark the wrong centre")
		await press(compare)
		expect(plate.marks[0] == 1 and not plate.exposure_b, "switching to A retains the mark")
		await press(compare)
	for i in marks.size():
		if state == "first" and i == 0:
			continue
		await _sundy_mark(paper, plate, text, i, marks[i])
	if state == "first":
		await press(submit)
		expect(has_text(paper, text.S66) and journey.accepted_log.is_empty(), "wrong evidence keeps the pair open")
		await _sundy_mark(paper, plate, text, 0, 0)
	await press(button(paper, text.S64 if judgment == "S63" else text.S63))
	expect(has_text(paper, text[reason]) and not has_text(paper, text[log]),
		"wrong judgment shows the pair's reason without logging it")
	await press(submit)
	expect(has_text(paper, text[reason]) and has_text(paper, text[log]), "correct judgment shows reason and accepted log")
	var next := button(paper, text[advance])
	check_paper_focus(next)
	await _sundy_frames("sundy_check_" + state + "_log", paper)
	if sundy_captures and state == "clouded" and L.current() == "en":
		var old_scale := Settings.text_scale
		root.size = Vector2i(1280, 720)
		Settings.text_scale = 1.2
		Settings.refresh_fonts(self)
		await _sundy_frames("sundy_check_clouded_log", paper, "_720p", Vector2i(1280, 720))
		Settings.text_scale = old_scale
		Settings.refresh_fonts(self)
		root.size = Vector2i(1920, 1080)
		await frames(3)
	await press(next)


func _sundy_mark(paper: Control, plate: Control, text: Dictionary, ring: int, target: int) -> void:
	var control: Button = paper.find_children("*", "Button", true, false).filter(
		func(item: Button): return item.text.begins_with(text.S54 % (ring + 1)))[0]
	await press(control)
	await press(button(paper, text.S55) if target == -1 else plate.targets[target])
	expect(plate.marks[ring] == target, "reference %d records the chosen centre or blank" % (ring + 1))
