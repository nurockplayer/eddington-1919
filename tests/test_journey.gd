extends SceneTree
## Drive the Cambridge coda handoff using the actual montage, dialogue and paper buttons.
## With --journey-captures=<dir>, save the paper states for art review.

const C17 := preload("res://scripts/cambridge/content_1917.gd")
const Departure := preload("res://scripts/cambridge/content_departure.gd")
const Content := preload("res://scripts/cambridge/content_tribunal.gd")
const Madeira := preload("res://scripts/cambridge/content_madeira.gd")
const Sundy := preload("res://scripts/cambridge/content_sundy.gd")
const Epilogue := preload("res://scripts/cambridge/content_epilogue.gd")
const London := preload("res://scripts/cambridge/content_london.gd")
const Print := preload("res://scripts/cambridge/content_london_print.gd")
const Sobral := preload("res://scripts/cambridge/content_sobral.gd")
const Homeward := preload("res://scripts/cambridge/content_homeward.gd")
const Report := preload("res://scripts/cambridge/report_sheet.gd")
const Settings := preload("res://scripts/settings.gd")
const ObservationDirector := preload("res://scripts/main.gd")

const CAMBRIDGE := "res://scenes/cambridge.tscn"
const DEPARTURE := "res://scenes/departure.tscn"
const OBSERVATION_DAY := "res://scenes/main.tscn"
const TRAY := ["D1", "D2", "C1", "R1", "C2", "R2", "D3", "C3", "R3"]
const SLOTS := ["T04", "T04", "T05", "T06", "T05", "T06", "T04", "T05", "T06"]
const PASS_AFTER := {"T19": 0, "T44": 1, "T55": 2}
const TRIBUNAL_PAGES := [
	"T01", "T02", "T09", "T11", "T15", "T19", "T77", "T78", "T79", "T80", "T81",
	"T23", "T24", "T25", "T29",
	"T31", "T33", "T35", "T36", "T40", "T38", "T40", "T42", "T44", "T45",
	"T46", "T48", "T50", "T52", "T54", "T55",
]

var checks := 0
var capture_dir := ""
var madeira_captures := false
var madeira_filing := false
var sundy_captures := false
var sobral_captures := false
var london_captures := false
var fold_captures := false
var fold_check := false
var fold_baseline := false
var i4_captures := false
var tribunal_captures := false
var print_captures := false
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


func press(button: Button, pad := false) -> void:
	expect(not button.disabled and button.is_visible_in_tree(), "enabled button: " + button.text)
	button.grab_focus()
	await accept(pad)


func accept(pad: bool) -> void:
	if pad:
		await tap_pad(JOY_BUTTON_A)
	else:
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
	# A comparison row can be taller than the viewport. Check the whole
	# region swept by scrolling from the top to the end.
	var reachable := scroll.get_global_rect().grow(1.0)
	reachable.position.y -= scroll.scroll_vertical
	reachable.size.y += scroll.scroll_vertical
	if not reachable.encloses(tail.get_global_rect()):
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


func check_letter_fold(paper: Control, state: String, pad: bool) -> void:
	var scroll: ScrollContainer = paper.body.get_parent()
	var bar := scroll.get_v_scroll_bar()
	var advance: Button = paper.actions.get_child(0)
	for direction in [-1, 1]:
		while scroll.scroll_vertical != (0 if direction < 0 else floori(bar.max_value - bar.page)):
			var previous := scroll.scroll_vertical
			if pad:
				await tap_pad(JOY_BUTTON_DPAD_UP if direction < 0 else JOY_BUTTON_DPAD_DOWN)
			else:
				await tap(KEY_UP if direction < 0 else KEY_DOWN)
			expect((scroll.scroll_vertical - previous) * direction > 0,
				"%s: letter scroll responds to %s" % [L.current(), "pad" if pad else "keys"])
	await frames(2)
	var fold := scroll.get_global_rect()
	var tail: Control = paper.body.get_child(-1)
	expect(fold.grow(1.0).encloses(tail.get_global_rect()), "the final letter row is visible")
	expect(advance.has_focus() and root.get_visible_rect().encloses(advance.get_global_rect()),
		"Advance stays focused and visible at the end of the letter")
	var split := false
	for row: Control in paper.body.get_children():
		var rect := row.get_global_rect()
		if row is Label and rect.position.y < fold.position.y - 0.5 and rect.end.y > fold.position.y + 0.5:
			print("%s %s %s: y=%.1f crosses text row %.1f–%.1f" % [
				state, L.current(), "pad" if pad else "keys", fold.position.y, rect.position.y, rect.end.y])
			split = true
	if not fold_baseline:
		expect(not split, "%s %s: the resting fold leaves whole letter rows" % [state, L.current()])
		expect(not bar.visible or tail.get_global_rect().end.y < fold.end.y - 0.5,
			"%s %s: the final row clears the bottom fold" % [state, L.current()])
	if fold_captures:
		await capture(state, paper, "_pad" if pad else "_keys")


func _run() -> void:
	var enabled := OS.get_cmdline_user_args().has("--journey")
	var london_only := OS.get_cmdline_user_args().has("--london-only")
	var sobral_only := OS.get_cmdline_user_args().has("--sobral-only")
	madeira_filing = OS.get_cmdline_user_args().has("--madeira-filing")
	fold_baseline = OS.get_cmdline_user_args().has("--fold-baseline")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--journey-captures="):
			capture_dir = arg.trim_prefix("--journey-captures=")
		elif arg.begins_with("--madeira-captures="):
			capture_dir = arg.trim_prefix("--madeira-captures=")
			madeira_captures = true
		elif arg.begins_with("--filing-captures="):
			capture_dir = arg.trim_prefix("--filing-captures=")
			madeira_filing = true
		elif arg.begins_with("--sundy-captures="):
			capture_dir = arg.trim_prefix("--sundy-captures=")
			sundy_captures = true
		elif arg.begins_with("--sobral-captures="):
			capture_dir = arg.trim_prefix("--sobral-captures=")
			sobral_captures = true
			sobral_only = true
		elif arg.begins_with("--i4-captures="):
			capture_dir = arg.trim_prefix("--i4-captures=")
			i4_captures = true
			sobral_only = true
		elif arg.begins_with("--london-captures="):
			capture_dir = arg.trim_prefix("--london-captures=")
			london_captures = true
		elif arg.begins_with("--fold-captures="):
			capture_dir = arg.trim_prefix("--fold-captures=")
			fold_captures = true
		elif arg.begins_with("--tribunal-captures="):
			capture_dir = arg.trim_prefix("--tribunal-captures=")
			tribunal_captures = true
		elif arg.begins_with("--print-captures="):
			capture_dir = arg.trim_prefix("--print-captures=")
			print_captures = true
			london_only = true
	fold_check = fold_captures or OS.get_cmdline_user_args().has("--fold-check")
	# Headless routes assert the transitions and controls, so advance presentation
	# time faster to keep all four locales inside the suite's wall-clock deadline.
	Engine.time_scale = 20.0 if capture_dir.is_empty() else 2.0
	root.size = Vector2i(1280, 720) if capture_dir.is_empty() or sobral_captures or london_captures or fold_captures or i4_captures or tribunal_captures or print_captures or madeira_filing else Vector2i(1920, 1080)
	if capture_dir.is_empty():
		var directory := DirAccess.create_temp("edd-journey", true)
		expect(directory != null, "create isolated checkpoint directory: " + error_string(DirAccess.get_open_error()))
		temp_settings = directory.get_current_dir().path_join("settings.cfg")
		OS.set_environment("EDD_SETTINGS_PATH", temp_settings)
		var settings := ConfigFile.new()
		settings.set_value("ui", "text_scale", 1.2)
		settings.set_value("ui", "reduced_motion", true)
		expect(settings.save(temp_settings) == OK, "save isolated test settings")
		Checkpoint.force_enabled = true
	var locales := ["en", "ja", "zh_TW", "ko"] if enabled else ["zh_TW"]
	if madeira_captures or sundy_captures or sobral_captures or london_captures or london_only or i4_captures or madeira_filing:
		locales = ["en", "ja"]
	elif tribunal_captures:
		locales = ["en"]
	# Retain the packed resources across locales. The directors still create fresh scenes.
	var route: Array[PackedScene] = [load(CAMBRIDGE), load(DEPARTURE), load(OBSERVATION_DAY)]
	if enabled and capture_dir.is_empty() and not london_only and not fold_check and not madeira_filing:
		L.apply("en")
		await _coda_without_epilogue(route[2])
		await _resume_october()
		await _resume_departure(route)
	for locale in locales:
		L.apply(locale)
		if madeira_filing:
			var story := root.get_node("Story")
			story.reset()
			story.from_prologue = true
			story.prologue_done = true
			expect(change_scene_to_packed(route[1]) == OK, "load departure before Madeira filing")
			await scene_changed
			await _departure_opening()
			await _departure(current_scene, route[2], enabled, locale == "ja", false)
		elif london_captures or london_only:
			await _london_setup()
		elif sobral_only:
			var story := root.get_node("Story")
			story.reset()
			story.from_prologue = true
			story.departure_done = true
			expect(change_scene_to_packed(route[2]) == OK, "load observation day before the Sobral handoff")
			await scene_changed
			await _sundy_coda(current_scene, enabled, false)
		else:
			await _route(route, enabled, locale == "ja")
		if capture_dir.is_empty():
			Checkpoint.clear()
	if capture_dir.is_empty():
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
		var caption: String = director.ui.caption.text
		expect(caption.begins_with(captions[i].t), "montage card %d is unchanged" % i)
		await tap(KEY_ENTER)
		while is_instance_valid(director) and director._caption_elapsed >= 0.0 and director.ui.caption.text == caption:
			await process_frame
	if enabled:
		while is_instance_valid(director) and director.get("tribunal") == null:
			await process_frame
		expect(is_instance_valid(director) and director.get("tribunal") != null,
			"--journey must enter Tribunal before departure")
		await _tribunal(director, misfile)
		expected.tribunal_packet_seen = true
	else:
		expect(director.get("tribunal") == null, "flag off creates no chapter")
	if current_scene == null or current_scene.scene_file_path != route[1].resource_path:
		await scene_changed
	expect(current_scene.scene_file_path == route[1].resource_path, "route loads existing M2 scene")
	expect(story.to_save() == expected, "M1 handoff records prologue completion and whether the packet beat played")
	if Checkpoint.force_enabled:
		expect(Checkpoint.peek() == "departure", "handoff writes the departure checkpoint")
		story.reset()
		expect(Checkpoint.restore() == "departure" and story.to_save() == expected,
			"departure checkpoint restores M1 state including the packet record")
		Checkpoint.clear()
	await _departure_opening()
	if capture_dir.is_empty() or madeira_captures or sundy_captures or fold_captures:
		await _departure(current_scene, route[2], enabled, misfile, enabled)


func _resume_departure(route: Array[PackedScene]) -> void:
	var story := root.get_node("Story")
	story.from_prologue = true
	story.prologue_done = true
	Checkpoint.save("departure")
	var legacy := Checkpoint._read()
	legacy.story.erase("tribunal_packet_seen")
	Checkpoint._write(legacy)
	story.reset()
	expect(change_scene_to_packed(route[2]) == OK, "load the title with a legacy departure save")
	await scene_changed
	expect(current_scene.ui.continue_btn != null, "the title offers the legacy departure save")
	current_scene.ui.continue_btn.pressed.emit()
	await scene_changed
	expect(current_scene.scene_file_path == route[1].resource_path, "Continue opens departure under --journey")
	expect(not story.tribunal_packet_seen, "a legacy departure save has no packet record")
	await _departure_opening()
	await _departure(current_scene, route[2], true, false, false)
	Checkpoint.clear()


func _resume_october() -> void:
	var story := root.get_node("Story")
	for letters in [[false, false], [false, true], [true, false]]:
		story.reset()
		story.bond_tone = "warm" if letters[1] else "close"
		story.madeira_letter_sent = letters[0]
		story.sundy_letter_read = letters[1]
		Checkpoint.save("epilogue")
		var checkpoint := Checkpoint._read()
		if not letters[0]:
			checkpoint.story.erase("madeira_letter_sent")
		if not letters[1]:
			checkpoint.story.erase("sundy_letter_read")
		Checkpoint._write(checkpoint)
		expect(Checkpoint.restore() == "epilogue", "restore the October checkpoint with a skipped letter scene")
		expect(change_scene_to_file(Checkpoint.scene("epilogue")) == OK, "load the restored October scene")
		await scene_changed
		await _october_opening(current_scene, true, story.bond_tone, letters[0], letters[1])
	Checkpoint.clear()
	story.reset()


func _departure_opening() -> void:
	while current_scene.ui.caption.text != Departure.intro_caption():
		await process_frame
	expect(current_scene.ui.caption.text == Departure.intro_caption(), "existing M2 opening plays")
	while not current_scene.ui.dialog_active():
		await process_frame


func _tribunal(director: Node, misfile: bool) -> void:
	var journey: Node = director.tribunal
	var paper: Control = journey.paper
	var pad := misfile or OS.get_cmdline_user_args().has("--tribunal-pad")
	var strings := Content.strings()
	var bench_speakers := {
		"T77": "T76", "T78": Content.Cast.MENTOR, "T79": Content.Cast.YOU,
		"T80": "T76", "T81": Content.Cast.KIT,
	}
	while director.ui.fade.color.a > 0.0:
		await process_frame
	await frames(2)
	for id in TRIBUNAL_PAGES:
		expect(journey.page_id == id, "expected %s, got %s" % [id, journey.page_id])
		if bench_speakers.has(id):
			expect(not paper.visible and director.ui.dialog_active(), "private exchange follows closed sourced slips")
			var speaker: String = bench_speakers[id]
			expect(director.ui.speaker_label.text == (strings.T76 if speaker == "T76" else L.t(speaker))
				and director.ui.text_label.text == strings[id],
				"private bench exchange shows its speaker and line: " + id)
			await accept(pad)
		elif director.ui.dialog_active():
			if id == "T19":
				expect(has_text(paper, strings.T11) and has_text(paper, strings.T13), "both claims stay in view")
			while director.ui.dialog_active() and journey.page_id == id:
				await accept(pad)
		else:
			if id == "T29":
				check_paper_focus(button(paper, strings.T22))
				if capture_dir.is_empty() or fold_captures or L.current() in ["en", "ja"]:
					await capture("hearing", paper)
			if id == "T54":
				expect(has_text(paper, strings.T54), "July condition has its own page")
			await press(button(paper, strings[id] if id in ["T24", "T45"] else strings.T22), pad)
		if PASS_AFTER.has(id):
			await _tribunal_pass(director, journey, strings, PASS_AFTER[id], misfile, pad)
	expect(journey.filed.size() == TRAY.size(), "nine distinct extracts before the verdict")
	for id in ["T71", "T72", "T74", "T75"]:
		expect(journey.page_id == id, "ledger sequence: " + id)
		if id == "T72":
			expect(has_text(paper, Content.ledger(strings, root.get_node("Story").bet_1917)), "ledger uses saved uncertain prediction")
			expect(has_text(paper, strings.T73), "ledger displays Ashby's own entry")
			await press(button(paper, strings.T22), pad)
		else:
			await accept(pad)
	expect(journey.page_id == "T82" and director.ui.dialog_active(), "Ashby returns to the ledger after the packet")
	expect(paper.visible and has_text(paper, strings.T73)
		and has_text(paper, Content.ledger(strings, root.get_node("Story").bet_1917)), "both entries stay open")
	for id in ["T82", "T83"]:
		expect(director.ui.speaker_label.text == L.t(Content.Cast.MENTOR)
			and director.ui.text_label.text == strings[id], "Ashby speaks beside the ledger: " + id)
		await accept(pad)
	expect(journey.page_id == "I01" and has_text(paper, strings.I05), "Armistice begins with the public report")
	expect(Checkpoint.peek() == "", "first Armistice page still has no checkpoint")
	await check_paper_layout(paper, "armistice")
	check_paper_focus(button(paper, strings.T22))
	await capture("armistice", paper)
	if tribunal_captures:
		await capture("tribunal_armistice", paper)
	await press(button(paper, strings.T22), pad)
	expect(journey.page_id == "I08" and has_text(paper, strings.I11), "Armistice ends with the Observatory's loss")
	await check_paper_layout(paper, "second armistice page")
	check_paper_focus(button(paper, strings.I12))
	await press(button(paper, strings.I12), pad)


func _tribunal_pass(director: Node, journey: Node, strings: Dictionary, pass_index: int, misfile: bool, pad: bool) -> void:
	var paper: Control = journey.paper
	var first := pass_index * 3
	var limit := first + 3
	expect(journey.page_id == "packet", "filing pass %d opens after %s, got %s" % [
		pass_index + 1, ["T21", "T44", "T55"][pass_index], journey.page_id])
	var tray: GridContainer = paper.body.find_children("*", "GridContainer", false, false)[0]
	expect(tray.get_child_count() == 3 and journey.filed.size() == first,
		"only three new extracts enter each pass")
	for i in first:
		var extract: Dictionary = Content.EXTRACTS[TRAY[i]]
		var filed_card := button(paper, strings[extract.lines[0]])
		var heading: Label = filed_card.get_parent().get_child(0)
		expect(heading.text == strings[SLOTS[i]] and journey.filed[TRAY[i]] == SLOTS[i],
			"earlier filing stays visible under its heading: " + TRAY[i])
	expect(Checkpoint.peek() == "", "checkpoint is deferred until I12")
	await check_paper_layout(paper, "packet")
	if pass_index == 2:
		await capture("packet", paper)
	if pass_index == 2 and L.current() == "en":
		expect(not strings.values().any(func(line): return "’" in line), "use proportional English apostrophes on the tribunal and Armistice pages")
		if not capture_dir.is_empty() and not madeira_captures and not sundy_captures and not fold_captures and not tribunal_captures:
			root.size = Vector2i(1280, 720)
			Settings.text_scale = 1.2
			Settings.refresh_fonts(self)
			await check_paper_layout(paper, "720p packet")
			await capture("packet", paper, "_720p", Vector2i(1280, 720))
			root.size = Vector2i(1920, 1080)
			Settings.text_scale = 1.0
			Settings.refresh_fonts(self)
			await frames(3)
	for i in range(first, limit):
		var card: String = TRAY[i]
		var extract: Dictionary = Content.EXTRACTS[card]
		var title: String = strings[extract.lines[0]]
		var source: String = strings[extract.source]
		var tray_card := button(paper, title)
		if not tray_card.button_pressed:
			await press(tray_card, pad)
		await press(button(paper, strings.T57), pad)
		expect(has_text(paper, source), "extract carries its source: " + card)
		expect(button(paper, strings.T59).disabled, "file waits for a heading")
		if i == 1:
			check_paper_focus(button(paper, strings.T04))
			if L.current() == "en" and not capture_dir.is_empty():
				await capture("packet_open", paper)
		if i == 0:
			if tribunal_captures:
				await capture("tribunal_open", paper)
			await press(button(paper, strings.T58), pad)
			expect(journey.filed.is_empty() and button(paper, title).has_focus(), "back leaves the extract in the tray")
			expect(button(paper, title).button_pressed and has_text(paper, source), "back keeps the selected extract and its source: " + card)
			if tribunal_captures:
				await capture("tribunal_back", paper)
			await press(button(paper, strings.T57), pad)
			expect(journey.page_id == card and has_text(paper, source), "reread opens the same sourced extract: " + card)
			if tribunal_captures:
				await capture("tribunal_reread", paper)
		if misfile or i == 0:
			var wrong: Array = ["T04", "T05", "T06"].filter(func(slot): return slot != SLOTS[i])
			for slot in (wrong if misfile else wrong.slice(0, 1)):
				await press(button(paper, strings[slot]), pad)
				await press(button(paper, strings.T59), pad)
				expect(journey.page_id == extract.hint and director.ui.text_label.text == strings[extract.hint],
					"wrong heading has the matching Kit hint: " + card)
				if tribunal_captures and i == 0:
					await capture("tribunal_misfile", paper)
				await accept(pad)
				expect(journey.filed.size() == i and button(paper, title).has_focus(),
					"wrong heading leaves the tray and focus unchanged: " + card)
				expect(button(paper, title).button_pressed and has_text(paper, source), "correction keeps the selected extract and its source: " + card)
				if tribunal_captures and i == 0:
					await capture("tribunal_correction", paper)
				await press(button(paper, strings.T57), pad)
			await press(button(paper, strings[wrong[0]]), pad)
		await press(button(paper, strings[SLOTS[i]]), pad)
		await press(button(paper, strings.T59), pad)
		expect(journey.filed.get(card) == SLOTS[i] and has_text(paper, strings.T60),
			"correct heading files the extract: " + card)
		var filed_card := button(paper, title)
		expect(filed_card.button_pressed and filed_card.has_focus() and has_text(paper, source), "filing keeps the selected extract and its source: " + card)
		if i == 0 and L.current() == "en" and not capture_dir.is_empty():
			await capture("packet_filed", paper)
			if tribunal_captures:
				await capture("tribunal_filed", paper)
		expect(paper.find_children("*", "Button", true, false).any(func(b): return b.text == strings.T70) == (i == limit - 1),
			"close becomes available after the three extracts in this pass")
	if pass_index == 2:
		await press(button(paper, strings.T52), pad)
		await press(button(paper, strings.T57), pad)
		expect(has_text(paper, strings.L) and has_text(paper, strings.T54), "rereading the ruling retains its citation and condition")
		expect(not paper.find_children("*", "Button", true, false).any(func(b): return b.text == strings.T59),
			"filed extract is read-only")
		await press(button(paper, strings.T58), pad)
	await press(button(paper, strings.T70), pad)


func capture(state: String, paper: Control, suffix := "", dimensions := Vector2i(1920, 1080)) -> void:
	if tribunal_captures:
		if not state.begins_with("tribunal_"):
			return
		dimensions = Vector2i(1280, 720)
	await frames(3)
	for action in paper.actions.get_children():
		expect(root.get_visible_rect().grow(1.0).encloses(action.get_global_rect()), "paper controls stay in bounds: " + state)
	if capture_dir.is_empty() or (i4_captures and not state.begins_with("i4_")) or (
		sobral_captures and not state.begins_with("sobral_")) or (
		madeira_captures and not state.begins_with("madeira_")) or (
		sundy_captures and not (state.begins_with("sundy_") or state.begins_with("i3_"))):
		return
	if fold_captures or madeira_filing:
		dimensions = Vector2i(1280, 720)
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


func _departure(chapter: Node, observation_day: PackedScene, enabled: bool, warm: bool, packet_seen: bool) -> void:
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
	var gift := {"shown": false}
	chapter.keepsake.visibility_changed.connect(func():
		gift.shown = gift.shown or chapter.keepsake.visible)
	await _dialogue(chapter, {"light_box": KEY_1})
	expect(gift.shown, "Ashby's real farewell shows the gift")
	var previous: Dictionary = story.to_save()
	expect(previous.slip_fix == 1 and previous.bond_tone == ("warm" if warm else "close"),
		"M2 has a correction and a bond tone to carry forward")
	if enabled:
		while is_instance_valid(chapter) and chapter.madeira == null and chapter.ui.caption.text == Departure.intro_caption():
			await process_frame
		expect(is_instance_valid(chapter) and chapter.madeira != null, "--journey must enter Madeira after M2")
		await _madeira(chapter.madeira, chapter, warm)
		if madeira_filing:
			return
		for frame in 150:
			if not is_instance_valid(chapter) or chapter.get("sundy") != null:
				break
			await process_frame
		expect(is_instance_valid(chapter) and chapter.get("sundy") != null, "I2 must enter Sundy before observation day")
		if fold_check:
			return
		await _sundy(chapter.sundy, chapter, warm)
	else:
		for entry in Departure.montage():
			while is_instance_valid(chapter) and not chapter.ui.caption.text.begins_with(entry.t):
				await process_frame
			expect(is_instance_valid(chapter) and chapter.madeira == null and
				chapter.ui.caption.text.begins_with(entry.t), "flag off retains M2 caption " + entry.t)
	if is_instance_valid(chapter):
		for frame in 150:
			if not is_instance_valid(chapter):
				break
			await process_frame
	expect(not is_instance_valid(chapter), "Sundy must reach observation day without showing the June cables")
	expect(current_scene.scene_file_path == observation_day.resource_path, "the route reaches the existing observation day")
	expect(current_scene._came_from_departure and story.departure_done, "arrival has the full-story origin")
	expect(current_scene.phase == current_scene.Phase.PREP and not current_scene.sim.drive_wound,
		"observation day begins in PREP with its own unwound drive")
	previous.departure_done = true
	previous.from_prologue = true
	previous.madeira_letter_sent = enabled
	previous.sundy_letter_read = enabled
	if Checkpoint.force_enabled:
		expect(Checkpoint.peek() == "principe", "the existing checkpoint is written at the slice handoff")
		expect(Checkpoint.restore() == "principe" and story.to_save() == previous,
			"the handoff preserves the prediction, certainty and M2 choices verbatim")
		Checkpoint.clear()
	await _sundy_coda(current_scene, enabled, packet_seen)


func _coda_without_epilogue(observation_day: PackedScene) -> void:
	var story := root.get_node("Story")
	var outcomes := {}
	for label in ["Príncipe tail only", "post-epilogue replay"]:
		story.reset()
		if label == "post-epilogue replay":
			story.departure_done = true
			story.epilogue_done = true
			ObservationDirector.prepare_replay(572, true, true)
		else:
			story.from_prologue = true
		expect(change_scene_to_packed(observation_day) == OK, "load " + label)
		await scene_changed
		var day := current_scene
		if day._is_replay:
			await day._start_from_title()
		day._setup_darkroom()
		day._start_judgment()
		await _dialogue(day)
		await _close_coda(day)
		for frame in 150:
			if day._paired_cables != null or day.phase == day.Phase.ENDING:
				break
			await process_frame
		outcomes[label] = "I3" if day._paired_cables != null else (
			"ending" if day.phase == day.Phase.ENDING and day.ui.ending_panel.visible else "no ending")
		Checkpoint.clear()
	expect(outcomes == {"Príncipe tail only": "ending", "post-epilogue replay": "ending"},
		"codas without a journey epilogue should go straight to the ending: %s" % str(outcomes))
	story.reset()


func _sundy_coda(day: Node, enabled: bool, packet_seen: bool) -> void:
	await _dialogue(day)
	expect(day._paired_cables == null, "no I3 at the observation-day opening")
	await day._begin_totality()
	expect(day.phase == day.Phase.TOTALITY and day._paired_cables == null, "totality precedes I3")
	await day._end_totality()
	await _dialogue(day)
	while day.phase != day.Phase.NIGHT or day._busy:
		await process_frame
	await _dialogue(day)
	expect(day._paired_cables == null, "darkroom precedes I3")
	if enabled:
		var inconclusive := L.current() in ["ja", "zh_TW"]
		day.sim.plates = [{"number": 1, "start": 100.0, "duration": 10.0, "usable": true,
			"included": true, "quality": "good", "stars": 5, "trail": 0.0, "read": true,
			"sigma": 0.33 if L.current() == "ja" else (0.25 if inconclusive else 0.18),
			"reading": day.sim.reading_for_value(1.40 if L.current() == "ja" else (1.30 if inconclusive else 1.75))}]
		day.sim.measured = true
		day.plate_textures = [ImageTexture.create_from_image(Image.create_empty(8, 8, false, Image.FORMAT_RGB8))]
		expect(day.sim.evidence_class() == ("ambiguous" if inconclusive else "favors_e"),
			"the fixture gives the intended personal result")
	var plates: Array = day.sim.plates.duplicate(true)
	var combined: Dictionary = day.sim.combined()
	day._start_judgment()
	await _dialogue(day, {"verdict": KEY_3})
	if combined.n > 0:
		while day._verdict_hold_s > 0.0:
			await process_frame
		await _dialogue(day)
	await _close_coda(day)
	var story := root.get_node("Story")
	var telegram: int = day._telegram
	var reason: String = day._reasons[day._reason].id
	if enabled:
		for frame in 150:
			if not is_instance_valid(day) or day._paired_cables != null:
				break
			await process_frame
		expect(is_instance_valid(day) and day._paired_cables != null, "I3 follows the coda fade before the epilogue")
		await _i3(day._paired_cables.paper)
		for frame in 150:
			if not is_instance_valid(day) or day.has_node("Sobral"):
				break
			await process_frame
		var chapter: Node = day.get_node_or_null("Sobral") if is_instance_valid(day) else null
		expect(chapter != null and day._paired_cables == null, "I3 closes before the Sobral archive opens")
		var before: Dictionary = story.to_save().duplicate(true)
		await _sobral(chapter, L.current() in ["en", "ja"])
		await press(button(chapter.paper, Sobral.strings().B54))
		expect(is_instance_valid(chapter) and chapter.page_id == "I4-01", "Sobral opens I4 before October")
		await _homeward(chapter.paper)
		expect(story.to_save() == before and day.sim.plates == plates,
			"Sobral and I4 leave the Príncipe state and plates intact before the October handoff")
		await press(button(chapter.paper, Homeward.strings()["I4-20"]))
	else:
		var skipped_archive := true
		while is_instance_valid(day):
			skipped_archive = skipped_archive and not day.has_node("Sobral") and day._paired_cables == null
			await process_frame
		expect(skipped_archive, "flag off starts no archive")
	if is_instance_valid(day):
		await scene_changed
	expect(current_scene.scene_file_path == "res://scenes/epilogue.tscn" and story.epilogue_done,
		"the route reaches the existing epilogue")
	var run: Dictionary = story.runs.back()
	expect(run.combined == combined and run.exposures.size() == plates.size()
		and run.telegram_id == preload("res://scripts/judgment.gd").TELEGRAMS[telegram].id
		and run.reason_id == reason, "October keeps the Príncipe measurement, telegram and reason")
	if enabled and L.current() == "zh_TW":
		expect(Epilogue.ledger_case(run) == "inconclusive", "October retains the inconclusive result")
	if capture_dir.is_empty():
		await _october(current_scene, enabled, story.bond_tone, packet_seen, combined)


func _close_coda(day: Node) -> void:
	expect(day.phase == day.Phase.CODA and day._paired_cables == null, "coda opening precedes I3")
	day._interact("departure_workbook")
	await _dialogue(day)
	day._interact("mentor_loupe")
	expect(day._pending == "coda_loupe" and day._paired_cables == null, "coda loupe precedes I3")
	await _dialogue(day)
	expect(root.get_node("Story").kit_first >= 0 and day.coda_step == day.CodaStep.FADING
		and day._paired_cables == null, "coda Kit choice is committed before I3")


func _october_opening(chapter: Node, enabled: bool, tone: String, madeira_sent: bool, sundy_read: bool) -> void:
	for frame in 150:
		if chapter._pending == "opening":
			break
		await process_frame
	expect(chapter._pending == "opening", "the October reunion opens")
	if enabled:
		var lines: Array = chapter.ui._seq.map(func(entry): return entry.t)
		var seal := lines.find(L.t("Kit 拆開封口。"))
		expect(seal > 0, "Kit opens the new envelope")
		expect(lines[seal - 1].contains(L.t("你從豐沙爾寄來的信到了。這封是我收到後寫的。")) == madeira_sent,
			"the October opening refers to the Funchal letter only if sent")
		var chair := L.t("Kit 拉了張椅子過來。")
		var sundy_chair := L.t("你把在桑迪讀過的那封信放在旁邊，攤在寫到椅子的地方。Kit 拉了張椅子過來。")
		expect(lines.has(sundy_chair) == sundy_read, "October lays out the Sundy letter only if read")
		expect(lines.has(sundy_chair if sundy_read else chair), "Kit pulls up a chair in either case")
	var opening := await _october_dialogue(chapter, enabled, tone)
	var expected := ["O03"] if enabled else []
	if madeira_sent:
		expected.push_front("O02" if tone == "close" else "O01")
	expect(opening == expected, "October includes O01 or O02 only if the Funchal letter was sent, then O03")
	expect(chapter.beat == chapter.Beat.LETTER, "the reunion hands off to Dyson's letter")


func _october(chapter: Node, enabled: bool, tone: String, packet_seen: bool, combined: Dictionary) -> void:
	await _october_opening(chapter, enabled, tone, enabled, enabled)
	var story := root.get_node("Story")
	if combined.n == 0:
		expect(Epilogue.ledger_case(story.runs.back()) == "no_value", "October plays with no readable personal plates")
	chapter._interact("letter")
	await _dialogue(chapter)
	if enabled:
		expect(chapter.chart.visible and chapter.chart.run.combined == combined, "October uses the original run")
	for step in 3:
		if enabled and step == 2:
			var rows: Array = chapter.chart.rows
			expect(rows.size() == (3 if combined.n > 0 else 2) and rows[-2].value == 1.98
				and rows[-1].value == 0.93, "both published Sobral series reach the existing October chart")
		await press(chapter.chart.button)
	await press(chapter.chart.choices[2])
	await press(chapter.chart.button)
	await _dialogue(chapter, {"astro_weight": KEY_2 if L.current() != "ja" else KEY_4})
	expect(chapter.beat == chapter.Beat.ORRERY, "the comparison and ledger reply lead to the orrery")
	chapter._interact("orrery")
	var strong := Epilogue.ledger_case(story.runs.back()) == "conceded"
	var choices := {"bet_oct": KEY_3 if strong else KEY_2, "final_reason": KEY_1 if strong else KEY_5}
	while chapter.ui.dialog_active() and chapter._pending != "close":
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		await tap(choices.get(entry.key, KEY_1) if entry.has("choices") else KEY_ENTER)
	expect(chapter._pending == "close", "October reaches the closing ledger exchange")
	var closing_lines: Array = chapter.ui._seq.slice(1).map(func(line): return line.t)
	var close := await _october_dialogue(chapter, enabled, tone)
	if enabled and not packet_seen:
		expect(close == ["O05"], "resumed departure must skip the unseen packet apology O04")
		expect(closing_lines == [
			L.t("Ashby 把帳本交到你手上。"),
			L.t("把我們兩個簽名的紀錄都帶去倫敦。要是有人問我寫的那筆，請他直接來找我。"),
			L.t("11 月 6 日，倫敦開會。"),
		], "resumed departure hands off the ledger without referring to the packet")
	else:
		expect(close == (["O04", "O05"] if packet_seen else []), "the packet apology plays after the tribunal beat")
	for frame in 150:
		if chapter._pending == "tableau":
			break
		await process_frame
	expect(chapter._pending == "tableau", "October keeps the tableau")
	await _dialogue(chapter)
	if enabled:
		await _london(chapter, combined, tone, strong)
	else:
		for frame in 150:
			if chapter.ui.ending_panel.visible:
				break
			await process_frame
		expect(chapter.ui.ending_panel.visible and chapter.get("london") == null and chapter.get("london_print") == null,
			"flag off opens the existing ending directly")


func _london(chapter: Node, combined: Dictionary, tone: String, strong: bool) -> void:
	for frame in 150:
		if chapter.get("london") != null and chapter.ui.fade.color.a == 0.0:
			break
		await process_frame
	expect(chapter.get("london") != null, "the October tableau hands off to London with the flag on")
	var meeting: Control = chapter.london
	var paper: Control = meeting.paper
	var run: Dictionary = root.get_node("Story").runs.back()
	var original := run.duplicate(true)
	var text := London.strings()
	var locale := L.current()
	var reaction := {"en": "L07", "ja": "L10", "zh_TW": "L11", "ko": "L07"}
	var read := [
		["prediction", ["L02", "L03", "L04", reaction[locale]], "L14"],
		["simulation", ["L15"], "L14"],
		["threshold", ["L85", "L86", "L87", "L12"], "L13"],
		["proceedings", ["L18", "L19", "L20", "L21", "L22", "L23"], "L14"],
		["principal", ["L29", "L30", "L31"], "L14"],
		["scale", ["L32", "L33", "L34", "L35", "L36", "L37", "L38", "L39"], "L40"],
		["precision", [], "L14"],
		["newall", ["L55", "L56", "L57", "L58", "L54"], "L14"],
		["silberstein", ["L59", "L60", "L61", "L62", "L54"], "L63"],
		["open_test", [], "L14"],
		["exchange", ["L73", "L74", "L88", "L75", "L76", "L54", "L72"], "L14"],
		["reply", ["L77"], "L79"],
		["workbook", ["L81", "L82", "L83", "L89", "L91" if tone == "close" else "L90"], "L14"],
		["hold", ["L04", "L81"], "L84"],
	]
	var line: String = text.reason if strong else text.reservation
	for sheet in read:
		var state: String = sheet[0]
		expect(meeting.page_id == state, "London paper opens " + state)
		_check_lines(paper, text, sheet[1])
		match state:
			"simulation":
				var sim_text: String = text.L16 % [combined.value, combined.sigma] if combined.n > 0 else text.L17
				expect(has_text(paper, sim_text) and not is_instance_valid(meeting.historical_chart),
					"the simulated measurement is on its own labelled sheet")
			"proceedings":
				expect(text.L23.contains("1.6″ ± 0.3″"), "London gives the Príncipe figure reported at the meeting")
			"principal":
				var historical: Array = meeting.historical_chart.rows
				expect(historical.size() == 2 and historical[0].value == 1.98 and historical[0].sigma == 0.12
					and historical[1].value == 1.61 and historical[1].sigma == 0.30,
					"London plots only the documented principal results with their probable errors")
			"precision":
				var precision := {"en": "L43", "ja": "L50", "zh_TW": "L47", "ko": "L50"}
				var notes := {"L43": ["L44", "L45", "L46"], "L47": ["L48", "L49", "L46"], "L50": ["L51", "L52"]}
				await _london_annotate(meeting, text, precision[locale], notes[precision[locale]], "L54")
				state = "precision_attached"
			"open_test":
				var test := {"en": "L70", "ja": "L68", "zh_TW": "L66", "ko": "L68"}
				var order := {"L70": ["L71", "L67", "L69"], "L68": ["L69", "L67", "L71"], "L66": ["L67", "L69", "L71"]}
				await _london_annotate(meeting, text, test[locale], order[test[locale]], "L72")
				state = "open_test_attached"
			"reply":
				await _london_frame(paper, state)
				await press(button(paper, text.reservation))
				expect(has_text(paper, text.reservation), "the reservation can be previewed")
				if strong:
					await press(button(paper, text.L80))
					await press(button(paper, text.reason))
				expect(has_text(paper, line), "the chosen words appear before committing")
				state = "reply_preview"
			"workbook", "hold":
				expect(has_text(paper, line), "the spoken line survives into the workbook and final hold")
		if meeting.historical_chart and meeting.historical_chart.rows.size() == 3:
			var astro: Dictionary = meeting.historical_chart.rows[2]
			expect(astro.value == 0.93 and astro.other_value == 1.52 and astro.no_bar,
				"the same unbarred astrograph pair stays visible on the historical chart")
		await _london_frame(paper, state)
		if state == "exchange" and london_captures and locale == "en":
			Settings.text_scale = 1.2
			Settings.refresh_fonts(self)
			meeting.refresh_fonts()
			await _london_frame(paper, state, "_scale_1_2")
			Settings.text_scale = 1.0
			Settings.refresh_fonts(self)
			meeting.refresh_fonts()
		await press(button(paper, text[sheet[2]]))
	await _london_print(chapter, text.L14)
	for frame in 150:
		if chapter.ui.ending_panel.visible:
			break
		await process_frame
	expect(chapter.ui.ending_panel.visible and chapter.ui.ending_review.text.ends_with(line),
		"the last advance reaches the deferred review with the exact spoken line")
	expect(run == original, "London leaves the run and October's recorded choices intact")


func _london_print(chapter: Node, next: String) -> void:
	for frame in 150:
		if chapter.get("london_print") != null and chapter.ui.fade.color.a == 0.0:
			break
		await process_frame
	var paper: Control = chapter.get("london_print")
	expect(is_instance_valid(paper) and not chapter.ui.ending_panel.visible,
		"Read the headlines opens In print before the run review")
	var text := Print.strings()
	var pages := [
		["I5-03", "I5-04", "I5-05", "I5-06"], ["I5-16", "I5-17"], ["I5-07", "I5-08", "I5-09"],
		["I5-18"], ["I5-19", "I5-20", "I5-21"], ["I5-22", "I5-23", "I5-24", "I5-10"],
		["I5-25"], ["I5-13", "I5-14", "I5-15"], ["I5-11"],
		["I6-03", "I6-04", "I6-05"], ["I6-06", "I6-07", "I6-08", "I6-09", "I6-10"],
		["I6-17", "I6-18", "I6-19", "I6-20"], ["I6-11", "I6-12"], ["I6-13", "I6-14", "I6-15"],
	]
	for ids in pages:
		var state: String = ids[0]
		var fiction := state == "I5-13"
		var print_sheet := state.begins_with("I5")
		_check_lines(paper, text, ids)
		_check_lines(paper, text, ["I5-01" if print_sheet else "I6-01"])
		expect(has_text(paper, text["I5-02" if print_sheet else "I6-02"]) != fiction,
			"the historical frame is absent only on the fictional sheet")
		expect(has_text(paper, text["I5-13"]) == fiction and has_text(paper, text["I5-15"]) == fiction,
			"Rook's labelled column appears only on its own page")
		var advance_text: String = text["I5-12"] if state == "I5-11" else (
			text["I6-16"] if state == "I6-13" else next)
		var advance := button(paper, advance_text)
		check_paper_focus(advance)
		expect(not chapter.ui.ending_panel.visible, "the review waits until after " + state)
		if print_captures:
			await _paper_frame(paper, state)
			if state == "I5-22" and L.current() == "en":
				Settings.text_scale = 1.2
				Settings.refresh_fonts(self)
				paper.refresh_fonts()
				await _paper_frame(paper, state, "_scale_1_2")
				Settings.text_scale = 1.0
				Settings.refresh_fonts(self)
				paper.refresh_fonts()
		await press(advance)


func _london_annotate(meeting: Control, text: Dictionary, pick: String, notes: Array, close: String) -> void:
	var paper: Control = meeting.paper
	await _london_frame(paper, meeting.page_id)
	await press(button(paper, text[pick]))
	expect(has_text(paper, text[notes[0]]) and not has_text(paper, text[close]),
		"the selected note previews before it is attached")
	await _london_frame(paper, meeting.page_id + "_preview")
	await press(button(paper, text.L53))
	var lines: Array = paper.body.find_children("*", "Label", true, false).map(func(label): return label.text)
	var start := lines.find(text[notes[0]])
	expect(start >= 0 and lines.slice(start, start + notes.size() + 1) == (notes + [close]).map(func(id): return text[id]),
		"the complete annotation starts with the selected note")


func _london_frame(paper: Control, state: String, suffix := "") -> void:
	if not london_captures:
		return
	await _paper_frame(paper, "london_" + state, suffix)


func _paper_frame(paper: Control, state: String, suffix := "") -> void:
	await check_paper_layout(paper, state)
	var scroll: ScrollContainer = paper.body.get_parent()
	var previous := scroll.scroll_vertical
	scroll.scroll_vertical = 0
	await capture(state, paper, suffix, Vector2i(1280, 720))
	if scroll.get_v_scroll_bar().visible:
		scroll.scroll_vertical = ceili(scroll.get_v_scroll_bar().max_value)
		await capture(state, paper, suffix + "_end", Vector2i(1280, 720))
	scroll.scroll_vertical = previous


func _london_setup() -> void:
	var story := root.get_node("Story")
	story.reset()
	var strong := L.current() == "en"
	var combined := {"n": 1, "value": 1.78 if strong else 1.40, "sigma": 0.18 if strong else 0.33}
	story.bond_tone = "warm" if strong else "close"
	story.madeira_letter_sent = true
	story.sundy_letter_read = true
	story.tribunal_packet_seen = true
	story.bet_1917 = {"pick": 1, "sure": 1}
	story.bet = story.bet_1917.duplicate()
	story.runs.append({"combined": combined, "clean": true, "bounds": {
		"lo": combined.value - 2.0 * combined.sigma, "hi": combined.value + 2.0 * combined.sigma},
		"grade": {"title": "", "lines": []}, "telegram_id": "", "reason_text": "", "plate_total": 1,
		"plates_available": 16, "plate_counts": {"good": 1, "poor": 0, "unusable": 0}})
	expect(change_scene_to_file("res://scenes/epilogue.tscn") == OK, "load October for London captures")
	await scene_changed
	await _october(current_scene, true, story.bond_tone, true, combined)


func _october_dialogue(chapter: Node, enabled: bool, tone: String) -> Array:
	var ids := []
	var beat: String = chapter._pending
	while chapter._pending == beat and chapter.ui.dialog_active():
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		if entry.has("id"):
			ids.append(entry.id)
		print("OCTOBER ", L.current(), " ", "on" if enabled else "off", " ", tone, " ", beat,
			" ", entry.get("id", "-"), " ", chapter.ui.speaker_label.text, " ", JSON.stringify(chapter.ui.text_label.text))
		await tap(KEY_ENTER)
	return ids


func _dialogue(chapter: Node, choices := {}) -> void:
	while chapter.ui.dialog_active():
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		await tap(choices.get(entry.key, KEY_1) if entry.has("choices") else KEY_ENTER)


func _check_lines(paper: Control, strings: Dictionary, ids: Array) -> void:
	for id in ids:
		expect(has_text(paper, strings[id]), "%s shows %s" % [L.current(), id])


func _filing_tap(pad: bool, key: Key, pad_button: JoyButton) -> void:
	if pad:
		await tap_pad(pad_button)
	else:
		await tap(key)
	await frames(2)


func _filing_in_view(paper: Control, text: Dictionary, id: String) -> void:
	var bounds: Rect2 = paper.body.get_parent().get_global_rect().grow(1.0)
	for row in [id, "M21", "M22"]:
		var rect := button(paper, text[row]).get_global_rect()
		expect(bounds.encloses(rect), "%s stays visible with %s (%s in %s)" % [row, id, rect, bounds])


func _madeira_file_with_device(journey: Node, paper: Control, text: Dictionary, pad: bool) -> void:
	var device := "_pad" if pad else "_keys"
	var order := ["M28", "M25", "M26", "M27"]
	await frames(3)
	expect(button(paper, text.M25).has_focus(), "first loose row starts focused")
	for id in Madeira.LOOSE.slice(1):
		await _filing_tap(pad, KEY_DOWN, JOY_BUTTON_DPAD_DOWN)
		expect(button(paper, text[id]).has_focus(), "down reaches next loose copy " + id)
	for i in order.size():
		var id: String = order[i]
		var folder := "M21" if id in Madeira.COPIES.M21 else "M22"
		expect(button(paper, text[id]).has_focus(), "filing focuses the next loose copy " + id)
		await _filing_tap(pad, KEY_ENTER, JOY_BUTTON_A)
		expect(journey.selected == id and journey.filed.size() == i, "selects a loose copy without filing " + id)
		_filing_in_view(paper, text, id)
		await _filing_tap(pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
		expect(button(paper, text.M21).has_focus(), "right from the active copy reaches the first folder")
		if i == 0:
			await _filing_tap(pad, KEY_LEFT, JOY_BUTTON_DPAD_LEFT)
			expect(button(paper, text[id]).has_focus(), "left from the folder returns to the active copy " + id)
			await _filing_tap(pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
			_filing_in_view(paper, text, id)
			await capture("madeira_active_copy", paper, device)
		if folder == "M22" or (pad and i == 0):
			await _filing_tap(pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
			expect(button(paper, text.M22).has_focus(), "right from the first folder reaches the second")
		_filing_in_view(paper, text, id)
		if pad and i == 0:
			await _filing_tap(pad, KEY_ENTER, JOY_BUTTON_A)
			expect(journey.selected == id and journey.filed.is_empty() and button(paper, text.M22).has_focus(),
				"wrong folder leaves the copy loose with destination focus")
			_filing_in_view(paper, text, id)
			await capture("madeira_wrong_folder", paper, device)
			await _filing_tap(pad, KEY_ESCAPE, JOY_BUTTON_B)
			expect(journey.selected.is_empty() and journey.filed.is_empty() and button(paper, text[id]).has_focus(),
				"cancel returns to the same loose copy")
			_filing_in_view(paper, text, id)
			await capture("madeira_cancel", paper, device)
			await _filing_tap(pad, KEY_ENTER, JOY_BUTTON_A)
			await _filing_tap(pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
		expect(button(paper, text[folder]).has_focus(), "correct packet receives focus for " + id)
		await _filing_tap(pad, KEY_ENTER, JOY_BUTTON_A)
		expect(journey.selected.is_empty() and journey.filed.get(id) == folder and journey.filed.size() == i + 1,
			"correct packet receives only the active copy " + id)
		if i + 1 < order.size():
			_filing_in_view(paper, text, order[i + 1])
	expect(button(paper, text.M38).has_focus(), "both packets complete and continue receives focus")
	await capture("madeira_packets_filed", paper, device)


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
	if madeira_filing:
		await _madeira_file_with_device(journey, paper, text, warm)
		await _filing_tap(warm, KEY_ENTER, JOY_BUTTON_A)
		expect(journey.page_id == "M39", "completed packets hand off to the Sobral papers")
		await _filing_tap(warm, KEY_ENTER, JOY_BUTTON_A)
		await _filing_tap(warm, KEY_ENTER, JOY_BUTTON_A)
		expect(chapter.ui.dialog_active() and journey.page_id == "M47", "Kit's sky promise follows filing")
		await _filing_tap(warm, KEY_ENTER, JOY_BUTTON_A)
		expect(journey.page_id == "M46" and button(paper, text.M51).has_focus(), "sky page opens with continue focused")
		await capture("madeira_sky_page", paper, "_pad" if warm else "_keys")
		await _filing_tap(warm, KEY_ENTER, JOY_BUTTON_A)
		expect(button(paper, text.M77).has_focus(), "sky page continues into the letter")
		return
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
	await press(button(paper, text.M51))
	await frames(3)
	var sheets: HBoxContainer = paper.body.get_child(-1)
	var outgoing: VBoxContainer = sheets.get_child(-1)
	var question: Label = outgoing.get_child(-1)
	expect(question.text == text.M74, "Kit's star question is last before sealing")
	_check_lines(paper, text, ["M86", "M71", "M72", "M73", "M78", "M75" if warm else "M76"])
	var workbook: VBoxContainer = sheets.get_child(1)
	var scroll: ScrollContainer = paper.body.get_parent()
	expect(has_text(workbook, text.M50) and workbook.get_child(-1) is HSeparator
		and scroll.get_global_rect().encloses(workbook.get_child(0).get_global_rect())
		and scroll.get_global_rect().encloses(workbook.get_child(-1).get_global_rect())
		and scroll.get_global_rect().encloses(question.get_global_rect()),
		"the empty reply space is visible beside the outgoing question")
	await press(button(paper, text.M77))
	_check_lines(paper, text, ["M78", "M79", "M50", "M85"])
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
		if id == "I06" and (capture_dir.is_empty() or fold_captures):
			await frames(3)
			await check_letter_fold(paper, "i2_landfall_end", false)
			await check_letter_fold(paper, "i2_landfall_end", true)
		await press(button(paper, text.I07 if id == "I06" else text.M09))
	_check_lines(paper, text, ["I01", "I02", "I06", "I08", "I09", "I11"])
	if L.current() != "en":
		expect(has_text(paper, Madeira.QUOTES.I09), "translated passage retains original excerpt")
	await check_paper_layout(paper, "onward passage letter")
	if capture_dir.is_empty() or fold_captures:
		await check_letter_fold(paper, "i2_letter_end", false)
		await check_letter_fold(paper, "i2_letter_end", true)
		if L.current() in ["en", "zh_TW"]:
			await tap(KEY_ENTER)
		else:
			await tap_pad(JOY_BUTTON_A)
		return
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
	await _sundy_sheet(paper, "sundy_12_kit_letter", [text.S85, text.S86, text.S87, text.S88, text.S92], onward)
	expect(chapter.ui.dialog_active() and chapter.ui.text_label.text == text.S47, "Ashby's remembered instruction precedes the rehearsal")
	await _check_sundy_memory(paper, chapter.ui)
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
	await _check_sundy_memory(paper, chapter.ui)
	expect(chapter.ui.dialogue_portrait.image.texture.resource_path == "res://assets/portraits/kit_neutral.jpg",
		"Kit's memory uses the toned print")
	expect(chapter.ui.speaker_label.text == "Kit" and chapter.ui.dialogue_portrait.disclosure.text == "(Fiction)",
		"Kit's memory card keeps the name and fiction caption in Latin letters")
	if sundy_captures:
		await capture("sundy_17_kit_memory", paper)
	await tap(KEY_ENTER)
	expect(chapter.ui.text_label.text == text.S80, "Kit asks what was seen at Sundy")
	await _dialogue(chapter)
	await _sundy_sheet(paper, "sundy_18_workbook", [
		text.S81, text.S93, text.S82 if warm else text.S83, text.S89, text.S90 if warm else text.S91,
		Madeira.strings().M85], text.S84)


func _i3(paper: Control) -> void:
	var text := Sundy.strings()
	var onward: String = Madeira.strings().M09
	while not paper.actions.visible:
		await process_frame
	await _sundy_sheet(paper, "i3_01_paired_cables", [
		text["I3-02"], text["I3-03"], "Through cloud, hopeful",
		text["I3-05"], "Eclipse splendid. Crommelin", text["I3-04"], text["I3-06"]], onward)
	await _sundy_sheet(paper, "i3_02_nature_clipping", [
		text["I3-08"], text["I3-09"], text["I3-10"], text["I3-11"], text["I3-12"], text["I3-13"]], onward)
	await _sundy_sheet(paper, "i3_03_brazil_press", [
		L.t("檔案剪報・據史料編成"), text["I3-15"], text["I3-16"], text["I3-17"]], Sobral.strings().B01)


func _sobral(chapter: Node, revise: bool) -> void:
	var paper: Control = chapter.paper
	var text := Sobral.strings()
	var onward: String = Madeira.strings().M09
	while not paper.actions.visible:
		await process_frame
	var setup := [
		["01_archive", ["B02", "B03"], onward],
		["02_racecourse", ["B04", "B05", "B06", "B07", "B08"], onward],
		["03_brazil", ["B09", "B10", "B11", "DIAGRAM", "MAILHAT"], onward],
		["04_first_contact", ["B12"], onward],
		["05_programmes", ["B13", "B14", "B15", "B16", "METRONOME"], text.B17],
	]
	for sheet in setup:
		while not paper.actions.visible:
			await process_frame
		_check_lines(paper, text, sheet[1])
		await _sobral_frame(paper, sheet[0])
		await press(button(paper, sheet[2]))
	_check_lines(paper, text, ["B18", "B23"])
	expect(button(paper, text.B21).disabled and button(paper, text.B22).disabled,
		"the focus check precedes the auxiliary samples")
	await _sobral_frame(paper, "06_darkroom_covered")
	for sample in [["B20", "B25", "B27"], ["B21", "B24", "B28"], ["B22", "B26", "B29"]]:
		await press(button(paper, L.t("查看底片") if sample[0] == "B20" else text[sample[0]]))
		_check_lines(paper, text, ["B19", sample[0]])
		await _sobral_frame(paper, "07_loupe_" + sample[0])
		var before: Array = chapter.logged.duplicate()
		if revise:
			for entry in ["B24", "B25", "B26"]:
				if entry == sample[1]:
					continue
				await press(button(paper, text[entry]))
				expect(has_text(paper, text[sample[2]]) and chapter.logged == before,
					"the wrong entry leaves the slot open for " + sample[0])
			await _sobral_frame(paper, "08_revise_" + sample[0])
			await press(button(paper, L.t("關閉")))
			expect(chapter.logged == before, "closing the loupe does not file a diagnosis")
			await press(button(paper, text[sample[0]]))
		await press(button(paper, text[sample[1]]))
		expect(has_text(paper, text[sample[2]]) and chapter.logged.back() == sample[1],
			"the matching entry fills the slot for " + sample[0])
	expect(chapter.logged == ["B25", "B24", "B26"], "all three diagnoses are visible in the log")
	_check_lines(paper, text, ["B30"])
	await _sobral_frame(paper, "09_series_log")
	await press(button(paper, text.B31))
	_check_lines(paper, text, ["B32", "B33"])
	await _sobral_frame(paper, "10_predawn")
	await press(button(paper, onward))
	_check_lines(paper, text, ["B34", "MAY_AUX"])
	await _sobral_frame(paper, "11_trial_setup")
	if revise:
		for trial in [["B35", "B38"], ["B36", "B39"]]:
			await press(button(paper, text[trial[0]]))
			_check_lines(paper, text, trial)
			expect(chapter.reference.is_empty(), "incompatible reference leaves the slot open")
			await _sobral_frame(paper, "12_trial_" + trial[0])
		await press(button(paper, L.t("關閉")))
		expect(chapter.reference.is_empty() and not has_text(paper, text.B39),
			"closing the trial clears its preview and keeps the reference slot open")
	await press(button(paper, text.B37))
	_check_lines(paper, text, ["MAY_AUX", "B37"])
	expect(chapter.reference.is_empty(), "both plates can be inspected before filing")
	await _sobral_frame(paper, "13_reference_through_glass")
	await press(button(paper, L.t("翻面")))
	await _sobral_frame(paper, "14_reference_aligned")
	await press(button(paper, text.FILE))
	_check_lines(paper, text, ["B40", "B41", "B42"])
	expect(chapter.reference == "B37", "the same field and instrument fill the reference slot")
	await _sobral_frame(paper, "15_reference_filed")
	await press(button(paper, text.B43))
	_check_lines(paper, text, ["B44", "B45", "B46"])
	await _sobral_frame(paper, "16_astrograph_pair")
	if revise:
		await press(button(paper, text.B47))
		_check_lines(paper, text, ["B44", "B45", "B49", "B50"])
		expect(chapter.scale_note.is_empty(), "the July focus alone leaves the May scale note open")
		await _sobral_frame(paper, "17_scale_revise")
	await press(button(paper, text.B48))
	_check_lines(paper, text, ["B44", "B45", "B49", "B50", "B51", "B52", "B53", "MAY_AUX"])
	expect(chapter.scale_note == "B48", "the uncertainty note files both Sobral series")
	await _sobral_frame(paper, "18_both_series")
	if sobral_captures and L.current() == "en":
		Settings.text_scale = 1.2
		Settings.refresh_fonts(self)
		await _sobral_frame(paper, "18_both_series", "_scale_1_2")
		Settings.text_scale = 1.0
		Settings.refresh_fonts(self)


func _sobral_frame(paper: Control, state: String, suffix := "") -> void:
	await check_paper_layout(paper, state)
	if not sobral_captures:
		return
	await _archive_frames(paper, "sobral_" + state, suffix)


func _homeward(paper: Control) -> void:
	var text := Homeward.strings()
	var pages := [
		["return", ["03", "04", "05", "06", "07", "08", "21", "22"]],
		["plates", ["09", "23", "10", "11", "12", "13", "14"]],
		["brussels_telegram", ["15", "16", "17"]],
		["berlin_letter", ["18", "19"]],
	]
	for index in pages.size():
		var state: String = "i4_" + pages[index][0]
		var ids := ["I4-01", "I4-02"]
		for number in pages[index][1]:
			ids.append("I4-" + number)
		_check_lines(paper, text, ids)
		var lines: Array = paper.body.find_children("*", "Label", true, false).map(func(label): return label.text)
		var previous := -1
		for id in ids.slice(2):
			var position := lines.find(text[id])
			expect(position > previous, state + " follows the scripted document order")
			previous = position
			if Homeward.EXCERPTS.has(id):
				expect(lines.has(Homeward.EXCERPTS[id]), state + " retains the original excerpt")
		var last := index == pages.size() - 1
		var advance := button(paper, text["I4-20"] if last else Madeira.strings().M09)
		await check_paper_layout(paper, state)
		check_paper_focus(advance)
		if i4_captures:
			await _archive_frames(paper, state)
			if index == 0 and L.current() == "en":
				var scale := Settings.text_scale
				Settings.text_scale = 1.2
				Settings.refresh_fonts(self)
				await _archive_frames(paper, state, "_scale_1_2")
				Settings.text_scale = scale
				Settings.refresh_fonts(self)
		if not last:
			await press(advance)


func _archive_frames(paper: Control, state: String, suffix := "") -> void:
	var scroll: ScrollContainer = paper.body.get_parent()
	scroll.scroll_vertical = 0
	await capture(state, paper, suffix, Vector2i(1280, 720))
	if scroll.get_v_scroll_bar().visible:
		scroll.scroll_vertical = ceili(scroll.get_v_scroll_bar().max_value)
		await capture(state, paper, suffix + "_end", Vector2i(1280, 720))


func _check_sundy_memory(paper: Control, ui: CanvasLayer) -> void:
	await frames(3)
	var sheet: Rect2 = paper.actions.get_parent().get_parent().get_global_rect()
	expect(sheet.encloses(ui.dialog_panel.get_global_rect()), "Sundy memory dialogue stays inside the sheet")
	expect(ui.dialogue_portrait.visible and sheet.encloses(ui.dialogue_portrait.get_global_rect()),
		"Sundy memory portrait stays inside the sheet")


func _sundy_sheet(paper: Control, state: String, lines: Array, advance: String, scroll_probe := false) -> void:
	for line in lines:
		expect(has_text(paper, line), state + " shows " + line)
	if L.current() == "en" and state in ["sundy_12_kit_letter", "i3_03_brazil_press"]:
		for label: Label in paper.find_children("*", "Label", true, false):
			for glyph in "‘’“”()":
				if glyph in label.text:
					var font := label.get_theme_font("font")
					expect(font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 100).x < 65.0,
						state + " uses proportional English punctuation for " + glyph)
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
