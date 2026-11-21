extends SceneTree
## Native 1600×900 canvas stretched by the project's own window settings.
const Settings := preload("res://scripts/settings.gd")
const Content := preload("res://scripts/content.gd")
const Judgment := preload("res://scripts/judgment.gd")
var out := ""
var records: Array = []

func _initialize() -> void:
	_run.call_deferred()

func settle(frames := 8) -> void:
	for frame in frames:
		await process_frame

func shot(id: String, panel: Control, body: Control) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := out.path_join(id + ".png")
	assert(image.save_png(path) == OK, path)
	var focus := root.gui_get_focus_owner()
	assert(focus != null and panel.is_ancestor_of(focus), "focus belongs to " + id)
	var factor := Vector2(image.get_size()) / root.get_visible_rect().size
	var body_rect := body.get_global_rect()
	var focus_rect := focus.get_global_rect().grow(-10)
	records.append({"frame": id, "body": rect_pixels(body_rect, factor), "focus": rect_pixels(focus_rect, factor)})

func rect_pixels(rect: Rect2, factor: Vector2) -> Array:
	return [roundi(rect.position.x * factor.x), roundi(rect.position.y * factor.y), roundi(rect.end.x * factor.x), roundi(rect.end.y * factor.y)]

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	assert(not out.is_empty())
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_position(Vector2i(30, 50))
	for locale in ["en", "ja", "zh_TW", "ko"]:
		for scale in ([1.0, 1.2] if locale in ["en", "ja"] else [1.0]):
			L.apply(locale)
			Settings.language = locale
			Settings.text_scale = scale
			Settings.fullscreen = false
			assert(Settings.save_settings() == OK)
			load("res://scripts/main.gd").next_seed = 7
			var game: Node = load("res://scenes/main.tscn").instantiate()
			root.add_child(game)
			game.set_process(false)
			game.player.set_physics_process(false)
			var ui = game.ui
			ui.set_process(false)
			await settle(20)
			var prefix := "%s_%s_" % [locale, "max" if scale > 1.0 else "default"]
			ui.prologue_btn.grab_focus()
			await shot(prefix + "title", ui.title_panel, ui.title_panel.find_children("*", "RichTextLabel", true, false)[0])
			ui.open_settings()
			await shot(prefix + "options", ui.pause_panel, ui.music_row.get_child(0))
			ui.close_settings()
			ui._open_credits()
			await shot(prefix + "credits", ui.credits_panel, ui.credits_scroll.get_child(0))
			ui._close_credits()
			game._start_game()
			game.player.can_move = false
			game.player.can_look = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			ui.show_toast("", 0.0)
			ui.toast.modulate.a = 0.0
			ui.toggle_pause()
			await shot(prefix + "pause", ui.pause_panel, ui.music_row.get_child(0))
			ui._open_help()
			await shot(prefix + "help", ui.help_panel, ui.help_table)
			ui._close_help()
			ui.toggle_pause()
			# Populate history through the same dialogue route as play.
			ui.play(Content.rules_prompt(true))
			await settle()
			ui.dialog_panel.hide()
			ui.toggle_log()
			await shot(prefix + "history", ui.log_panel, ui.log_text)
			ui.toggle_log()
			if locale == "en" and scale == 1.0:
				# Enter totality through its real contact transition; no sleeps or polling.
				ui._seq.clear()
				await game._begin_totality()
				ui.toggle_pause()
				await shot(prefix + "pause_totality", ui.pause_panel, ui.music_row.get_child(0))
				ui.toggle_pause()
			# Complete the no-exposure run with its actual evidence judgment.
			game._telegram = 3
			game._reason = 3
			game._grade = Judgment.grade(game.sim, "none", "nostars")
			game._show_ending()
			await shot(prefix + "ending", ui.ending_panel, ui.ending_telegram)
			game.stop_all_audio()
			game.free()
			root.get_node("Story").reset()
			load("res://scripts/ui.gd").history.clear()
			await settle()
	var file := FileAccess.open(out.path_join("frames.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(records, "\t"))
	file.close()
	print("menus-page captures: %d frames" % records.size())
	quit()
