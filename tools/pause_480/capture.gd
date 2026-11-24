extends SceneTree

const Settings := preload("res://scripts/settings.gd")

func _initialize() -> void:
	_run.call_deferred()

func settle(frames := 12) -> void:
	for i in frames:
		await process_frame

func shot(path: String, ui) -> void:
	await settle()
	assert(ui.pause_panel.visible)
	var font: Font = ui.totality_pace_button.get_theme_font("font")
	for character in ui.totality_pace_button.text:
		if character != "\n":
			assert(font.has_char(character.unicode_at(0)), "missing glyph: " + character)
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var build: String = args[1]
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_position(Vector2i(30, 50))
	for locale in ["en", "ja", "zh_TW", "ko"]:
		L.apply(locale)
		Settings.language = locale
		Settings.text_scale = 1.2
		Settings.reduced_motion = false
		Settings.slower_totality = false
		Settings.fullscreen = false
		assert(Settings.save_settings() == OK)
		seed(7)
		load("res://scripts/main.gd").next_seed = 7
		var game: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		game.player.set_physics_process(false)
		var ui = game.ui
		ui.set_process(false)
		await settle(20)
		game._start_game()
		game.player.can_move = false
		game.player.can_look = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		ui.show_toast("", 0.0)
		ui.toast.modulate.a = 0.0
		ui.toggle_pause()
		ui.totality_pace_button.grab_focus()
		await shot(out.path_join("%s-%s-normal.png" % [build, locale]), ui)
		ui.totality_pace_button.pressed.emit()
		await shot(out.path_join("%s-%s-slower.png" % [build, locale]), ui)
		if locale in ["ja", "zh_TW"]:
			ui.toggle_pause()
			await game._begin_totality()
			ui.toggle_pause()
			ui.music_slider.grab_focus()
			await shot(out.path_join("%s-%s-locked.png" % [build, locale]), ui)
		ui.toggle_pause()
		game.stop_all_audio()
		game.free()
		root.get_node("Story").reset()
		load("res://scripts/ui.gd").history.clear()
		await settle()
	print("pause 480 capture: 10 frames, 1280x720, scale 1.2, reduced motion false")
	quit()
