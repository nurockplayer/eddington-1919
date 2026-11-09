extends SceneTree
## Leak coverage the bot routes never give: the title, credits, settings, pause,
## help and log menus, and Chart's draw_string text (a node property cannot show
## it). Part A exercises the watcher against a Chart in both modes; Part B walks
## every menu only when EDD_PSEUDO_JSON is set, so all_suites.sh still runs it.
## Headless: godot --headless --path . --script res://tests/test_menu_leaks.gd

const Chart := preload("res://scripts/chart.gd")
const LeakWatch := preload("res://tests/leak_watch.gd")
const Prompts := preload("res://scripts/prompts.gd")
const Settings := preload("res://scripts/settings.gd")

var checks := 0
var failures := 0
var _last_leaks: Array = []
var _pseudo := false


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func settle(frames := 4) -> void:
	for i in frames:
		await process_frame


func _wait_for(cond: Callable, seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return cond.call()


func find_button(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node
	for child in node.get_children():
		var found := find_button(child, label)
		if found:
			return found
	return null


func find_any_button(node: Node, labels: Array) -> Button:
	for label in labels:
		var found := find_button(node, label)
		if found:
			return found
	return null


## One scan with a fresh watcher (its de-dupe is per instance). Returns the total
## finish() reported and keeps the leaked strings for assertions.
func scan() -> int:
	var watch: Node = LeakWatch.new()
	root.add_child(watch)
	watch.scan()
	var total: int = watch.finish()
	_last_leaks = watch._leaks.duplicate()
	watch.queue_free()
	await process_frame
	return total


## A multi-line source (Chart joins its strings) is one entry; match a whole
## line so the Chinese reference lines under zh-TW cannot stand in for the label.
func leaked_line(text: String) -> bool:
	for entry in _last_leaks:
		for line in String(entry).get_slice("\u0000", 1).split("\n"):
			if line == text:
				return true
	return false


# --- Part A: the watcher sees what draw_string painted -----------------------

## The chart always draws its three reference lines. They reach L.t, so under
## zh-TW they are Chinese and would mask a label leak; give them ASCII text for
## the case so only the row label can be CJK. Under pseudo they are ASCII already.
const REF_MSGIDS := ["無偏折 0″", "牛頓式 0.87″", "愛因斯坦 1.75″"]

var _ref_translation: Translation = null


func _ascii_reference_lines() -> void:
	if TranslationServer.get_locale() == "en_XA":
		return
	var translation := Translation.new()
	translation.locale = TranslationServer.get_locale()
	for i in REF_MSGIDS.size():
		translation.add_message(REF_MSGIDS[i], "reference %d" % i)
	TranslationServer.add_translation(translation)
	_ref_translation = translation


func _draw_chart(chart: Control, label: String) -> void:
	chart.set_data([{"label": label, "value": 1.0, "sigma": 0.2, "weak": false}], {}, true)
	chart.queue_redraw()
	await settle(3)


func _chart_cases() -> void:
	root.size = Vector2i(1280, 720)
	_ascii_reference_lines()
	var chart: Control = Chart.new()
	root.add_child(chart)
	chart.size = Vector2(560, 420)
	await _draw_chart(chart, "第1號")
	check(chart.drawn().label_px == Settings.fs(14), "the chart draws its labels")
	check(chart.drawn_texts().has("第1號"), "the chart records the text it draws")
	var leaked: int = await scan()
	check(leaked == 1, "a bare CJK label is reported above 0 (total %d)" % leaked)
	check(leaked_line("第1號"), "the [LEAK] report names the bare label")
	await _draw_chart(chart, "No. 1")
	var clean: int = await scan()
	check(clean == 0, "an ASCII label in the same chart returns 0 (total %d)" % clean)
	chart.queue_free()
	await settle(2)
	if _ref_translation != null:
		TranslationServer.remove_translation(_ref_translation)
		_ref_translation = null


# --- Part B: the menu walk (pseudo only) -------------------------------------

func _scan_step(watch: Node) -> void:
	await settle()
	watch.scan()


func _menu_walk() -> int:
	var previous_env := OS.get_environment("EDD_SETTINGS_PATH")
	var real_path := previous_env if not previous_env.is_empty() else ProjectSettings.globalize_path("user://settings.cfg")
	var had_real := FileAccess.file_exists(real_path)
	var real_bytes := FileAccess.get_file_as_bytes(real_path) if had_real else PackedByteArray()
	var temp_path := real_path.get_base_dir().path_join("test-menu-leaks-settings.cfg")
	var n := 0
	while temp_path == real_path or FileAccess.file_exists(temp_path) or DirAccess.dir_exists_absolute(temp_path):
		n += 1
		temp_path = real_path.get_base_dir().path_join("test-menu-leaks-settings-%d.cfg" % n)
	OS.set_environment("EDD_SETTINGS_PATH", temp_path)

	Checkpoint.force_enabled = true
	var story := root.get_node("Story")
	story.reset()
	story.prologue_done = true
	Checkpoint.save("principe")
	check(Checkpoint.peek() == "principe", "the walk starts from a saved checkpoint")
	check(change_scene_to_file("res://scenes/main.tscn") == OK, "load main")
	var ready: bool = await _wait_for(func(): return current_scene != null and current_scene.ui != null, 20.0)
	check(ready, "the main scene is up")
	if not ready:
		_cleanup(previous_env, real_path, had_real, real_bytes, temp_path)
		return 0
	var main := current_scene
	main.set_process(false)
	var ui = main.ui
	var watch: Node = LeakWatch.new()
	root.add_child(watch)

	# 1. The title, with a checkpoint so 繼續 exists.
	await _scan_step(watch)
	check(ui.title_panel.visible, "the title is up")
	check(ui.continue_btn != null and ui.continue_btn.text == L.t(Checkpoint.label("principe")),
		"the saved checkpoint adds 繼續")

	# 2. Credits and back.
	var credits_btn := find_button(ui.title_panel, L.t("製作名單"))
	check(credits_btn != null, "the title offers 製作名單")
	if credits_btn != null:
		credits_btn.pressed.emit()
		await _scan_step(watch)
		check(ui.credits_panel.visible, "製作名單 opens the credits")
		var back := find_button(ui.credits_panel, L.t("返回"))
		check(back != null, "the credits offer 返回")
		if back != null:
			back.pressed.emit()
			await _scan_step(watch)
		check(not ui.credits_panel.visible, "返回 closes the credits")

	# 3. Settings, every caption-changing button, then 返回.
	var settings_btn := find_button(ui.title_panel, L.t("設定"))
	check(settings_btn != null, "the title offers 設定")
	if settings_btn != null:
		settings_btn.pressed.emit()
		await _scan_step(watch)
		check(ui.pause_panel.visible and ui._settings_only, "設定 opens the settings panel")
		# Each press shows its other caption(s): 2-state toggles twice, the
		# three-state text size and look speed three times.
		var look := find_any_button(ui.pause_panel, [
			L.t("視角靈敏度：%s") % L.t("低"),
			L.t("視角靈敏度：%s") % L.t("標準"),
			L.t("視角靈敏度：%s") % L.t("高"),
		])
		var invert := find_any_button(ui.pause_panel, [L.t("上下反轉：開"), L.t("上下反轉：關")])
		var motion := find_any_button(ui.pause_panel, [L.t("減少晃動：開"), L.t("減少晃動：關")])
		var buttons := [
			["音樂", ui.music_button, 1],
			["全螢幕", ui.fullscreen_button, 1],
			["文字大小", ui.text_size_button, 3],
			["畫質", ui.quality_button, 2],
			["視角靈敏度", look, 3],
			["上下反轉", invert, 2],
			["減少晃動", motion, 2],
			["長按互動", ui.hold_button, 2],
		]
		for entry in buttons:
			var button: Button = entry[1]
			check(button != null and button.is_visible_in_tree(), "settings shows %s" % entry[0])
			if button == null:
				continue
			for i in entry[2]:
				button.pressed.emit()
				await _scan_step(watch)
		var close := find_button(ui.pause_panel, L.t("返回"))
		check(close != null, "settings offers 返回")
		if close != null:
			close.pressed.emit()
			await _scan_step(watch)
		check(not ui.pause_panel.visible, "返回 closes the settings")

	# 4. In game: pause and help, for a keyboard and then a pad.
	ui.start_btn.pressed.emit()
	var started: bool = await _wait_for(func(): return main.phase != main.Phase.TITLE and not ui.title_panel.visible, 20.0)
	check(started, "只玩尾章 starts the game")
	if started:
		await _scan_step(watch)
		await _pause_and_help(ui, watch)
		Prompts.joypad = true
		ui._refresh_hints()
		await _pause_and_help(ui, watch)
		Prompts.joypad = false
		ui._refresh_hints()
		await _scan_step(watch)

	# 5. The dialogue log, opened by a function the routes do not call.
	ui.toggle_log()
	await _scan_step(watch)
	check(ui.log_panel.visible, "the log opens")
	ui.toggle_log()
	await settle()

	var total: int = watch.finish()
	watch.queue_free()
	_cleanup(previous_env, real_path, had_real, real_bytes, temp_path)
	return total


func _pause_and_help(ui, watch: Node) -> void:
	ui.toggle_pause()
	await _scan_step(watch)
	check(paused and ui.pause_panel.visible, "toggle_pause opens the pause menu")
	var help := find_button(ui.pause_panel, L.t("操作說明"))
	check(help != null, "the pause menu offers 操作說明")
	if help != null:
		help.pressed.emit()
		await _scan_step(watch)
		check(ui.help_panel.visible, "操作說明 opens its panel")
		var back := find_button(ui.help_panel, L.t("返回"))
		check(back != null, "the help panel offers 返回")
		if back != null:
			back.pressed.emit()
			await _scan_step(watch)
		check(not ui.help_panel.visible, "返回 closes the help panel")
	ui.toggle_pause()
	await settle()


func _cleanup(previous_env: String, real_path: String, had_real: bool, real_bytes: PackedByteArray, temp_path: String) -> void:
	paused = false
	Checkpoint.clear()
	Checkpoint.force_enabled = false
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(temp_path)
	OS.set_environment("EDD_SETTINGS_PATH", previous_env)
	check(not FileAccess.file_exists(temp_path), "the walk leaves no test settings file")
	check(FileAccess.file_exists(real_path) == had_real and (not had_real or FileAccess.get_file_as_bytes(real_path) == real_bytes),
		"the configured settings file is unchanged")


func _run() -> void:
	_pseudo = OS.has_environment("EDD_PSEUDO_JSON")
	await _chart_cases()
	if _pseudo:
		print("menu walk: title, credits, settings, pause/help (keyboard+pad), log")
		var total: int = await _menu_walk()
		check(total == 0, "the menu walk still leaks %d string(s)" % total)
	else:
		print("menu walk skipped: no pseudo catalogue")
	print("test_menu_leaks: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
