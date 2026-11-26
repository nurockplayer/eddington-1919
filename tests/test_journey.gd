extends SceneTree
## Drive the Cambridge coda handoff using the actual montage, dialogue and paper buttons.
## With --journey-captures=<dir>, drive the same route in a window for en and ja receipts.

const C17 := preload("res://scripts/cambridge/content_1917.gd")
const Departure := preload("res://scripts/cambridge/content_departure.gd")
const Content := preload("res://scripts/cambridge/content_tribunal.gd")
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
var temp_settings := ""


func _initialize() -> void:
	_run.call_deferred()


func expect(ok: bool, message: String) -> void:
	checks += 1
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


func _run() -> void:
	var enabled := OS.get_cmdline_user_args().has("--journey")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--journey-captures="):
			capture_dir = arg.trim_prefix("--journey-captures=")
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
	var locales := ["en", "ja"] if not capture_dir.is_empty() else (L.LOCALES if enabled else ["zh_TW"])
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
				await capture("hearing", paper)
			if id == "T54":
				expect(has_text(paper, strings.T54), "July condition has its own page")
			await press(button(paper, strings[id] if id in ["T24", "T45"] else strings.T22))
	expect(journey.page_id == "packet", "packet follows the July pages")
	expect(Checkpoint.peek() == "", "checkpoint is deferred until I12")
	await capture("packet", paper)
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
	await capture("armistice", paper)
	await press(button(paper, strings.T22))
	expect(journey.page_id == "I08" and has_text(paper, strings.I11), "Armistice ends with the Observatory's loss")
	await press(button(paper, strings.I12))


func capture(state: String, paper: Control) -> void:
	await frames(3)
	for action in paper.actions.get_children():
		expect(root.get_visible_rect().grow(1.0).encloses(action.get_global_rect()), "paper controls stay in bounds: " + state)
	if capture_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	expect(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED, "capture stays windowed")
	var image := root.get_texture().get_image()
	expect(image.get_size() == Vector2i(1920, 1080), "capture is 1920×1080, got %s" % image.get_size())
	var filename := state + "_" + L.current() + ".png"
	expect(image.save_png(capture_dir.path_join(filename)) == OK, "write " + filename)
	var receipt := FileAccess.open(capture_dir.path_join("index.md"), FileAccess.READ_WRITE)
	receipt.seek_end()
	var jst := Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()) + 9 * 3600).replace("T", " ") + " JST"
	receipt.store_line("| [%s](%s) | %s | %s | 1920×1080 | %.2f | %s | %s |" % [
		filename, filename, state, L.current(), Settings.text_scale, Settings.reduced_motion, jst])
	print("saved ", filename)
