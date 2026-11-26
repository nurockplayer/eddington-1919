extends SceneTree
## Drive the Cambridge coda handoff using the actual montage, dialogue and paper buttons.
## With --journey-captures=<dir>, save the paper states for art review.

const C17 := preload("res://scripts/cambridge/content_1917.gd")
const Departure := preload("res://scripts/cambridge/content_departure.gd")
const Content := preload("res://scripts/cambridge/content_tribunal.gd")
const Madeira := preload("res://scripts/cambridge/content_madeira.gd")
const Report := preload("res://scripts/cambridge/report_sheet.gd")
const Settings := preload("res://scripts/settings.gd")

const DEPARTURE := "res://scenes/departure.tscn"
const TRAY := ["D1", "C1", "R1", "C2", "D2", "R2", "D3", "C3", "R3"]
const SLOTS := ["T04", "T05", "T06", "T05", "T04", "T06", "T04", "T05", "T06"]
const BEFORE_PACKET := [
	"T01", "T02", "T09", "T11", "T15", "T19", "T23", "T24", "T25", "T29",
	"T31", "T33", "T35", "T36", "T40", "T38", "T40", "T42", "T44", "T45",
	"T46", "T48", "T50", "T52", "T54", "T55",
]

var checks := 0
var capture_dir := ""
var madeira_captures := false
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
	var available := layout.size.y - footer_height - layout.get_theme_constant("separation")
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


func _run() -> void:
	var enabled := OS.get_cmdline_user_args().has("--journey")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--journey-captures="):
			capture_dir = arg.trim_prefix("--journey-captures=")
		elif arg.begins_with("--madeira-captures="):
			capture_dir = arg.trim_prefix("--madeira-captures=")
			madeira_captures = true
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
	if madeira_captures:
		locales = ["en", "ja"]
	for locale in locales:
		L.apply(locale)
		await _route(enabled, locale == "ja")
	if capture_dir.is_empty():
		Checkpoint.clear()
		DirAccess.remove_absolute(Settings.settings_path())
		DirAccess.remove_absolute(temp_settings.get_base_dir())
	print("test_journey %s: %d checks, 0 failures" % ["on" if enabled else "off", checks])
	quit()


func _route(enabled: bool, misfile: bool) -> void:
	expect(change_scene_to_file("res://scenes/cambridge.tscn") == OK, "load real Cambridge scene")
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
	if current_scene == null or current_scene.scene_file_path != DEPARTURE:
		await scene_changed
	expect(current_scene.scene_file_path == DEPARTURE, "route loads existing M2 scene")
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
		await _departure(current_scene, enabled, misfile)


func _tribunal(director: Node, misfile: bool) -> void:
	var journey: Node = director.tribunal
	var paper: Control = journey.paper
	var strings := Content.strings()
	while director.ui.fade.color.a > 0.0:
		await process_frame
	await frames(2)
	for id in BEFORE_PACKET:
		expect(journey.page_id == id, "expected %s, got %s" % [id, journey.page_id])
		if director.ui.dialog_active():
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
		if not capture_dir.is_empty() and not madeira_captures:
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
	if capture_dir.is_empty() or (madeira_captures and not state.begins_with("madeira_")):
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


func _departure(chapter: Node, enabled: bool, warm: bool) -> void:
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
	else:
		for entry in Departure.montage():
			while is_instance_valid(chapter) and not chapter.ui.caption.text.begins_with(entry.t):
				await process_frame
			expect(is_instance_valid(chapter) and chapter.madeira == null and
				chapter.ui.caption.text.begins_with(entry.t), "flag off retains M2 caption " + entry.t)
	if is_instance_valid(chapter):
		await scene_changed
	expect(current_scene.scene_file_path == "res://scenes/main.tscn", "the route reaches the existing observation day")
	expect(current_scene._came_from_departure and story.departure_done, "arrival has the full-story origin")
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
			if madeira_captures:
				await create_timer(0.65).timeout
				check_paper_focus(button(paper, text.M09))
				await capture("madeira_arrival", paper)
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
	var order := [2, 3, 0, 1] if warm else [0, 3, 1, 2]
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
	if madeira_captures:
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
	if madeira_captures:
		check_paper_focus(button(paper, text.I10))
		await capture("madeira_onward_passage", paper)
	await press(button(paper, text.I10))
