extends SceneTree
## PR #404: Oxford tile at max text in each locale and ja default, in both states.
const NativeCaption := preload("res://tools/layout_720p/native_caption.gd")
const Settings := preload("res://scripts/settings.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
const Render := preload("res://scripts/plate_render.gd")
var out := ""


func _initialize() -> void:
	_run.call_deferred()


func frame(path: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)


func _run() -> void:
	out = OS.get_cmdline_user_args()[0]
	root.size = Vector2i(1280, 720)
	var probe := "--native-probe" in OS.get_cmdline_user_args()
	for locale in (["zh_TW"] if probe else L.LOCALES):
		L.apply(locale)
		seed(77)
		var game: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		game.player.set_physics_process(false)
		game.ui.set_process(false)
		game.ui.hide_title()
		game.ui.hud.hide()
		game.sim = Sim.new(77)
		game.sim.plates_delivered = game.sim.MAX_EXTRA_PLATES
		for i in game.sim.plates_available():
			game.sim.open_shutter(float(i * 24))
			for step in 32:
				game.sim.accumulate(0.25, game.sim.cloud_over_sun(float(i * 24) + step * 0.25))
			game.sim.close_shutter(false)
		game.plate_textures.clear()
		for plate in game.sim.plates:
			plate.included = plate.usable
			plate.read = true
			game.plate_textures.append(Render.render(game.sim, plate))
		game.comparison_tex = Render.render(game.sim, null)
		for scale in ([1.0, 1.2] if locale == "ja" else [1.2]):
			Settings.text_scale = scale
			Settings.refresh_fonts(self)
			game.ui.chart.refresh_fonts()
			game._open_viewer()
			# Reopening (ja max) queues the previous grid for deletion.
			for i in 5:
				await process_frame
			var label := "default" if scale == 1.0 else "max"
			game.ui._select_plate(-2, game.comparison_tex, false)
			game.ui.thumbs.get_child(0).grab_focus()
			if probe:
				var ok := await NativeCaption.probe(self, game.ui.thumbs.get_child(12), out)
				game.stop_all_audio()
				game.free()
				print("layout_720p native probe: " + ("PASS" if ok else "FAIL"))
				quit(0 if ok else 1)
				return
			await frame(out.path_join("oxford_%s_%s_selected_720.png" % [locale, label]))
			assert(game.ui.thumbs.get_child(0).has_focus(), "selected capture must focus the current Oxford tile")
			game.ui._select_plate(0, game.plate_textures[0], false)
			game.ui.thumbs.get_child(1).grab_focus()
			await frame(out.path_join("oxford_%s_%s_unselected_720.png" % [locale, label]))
			game.ui.close_viewer()
		game.stop_all_audio()
		game.free()
	print("layout_720p capture: 10 Oxford frames, 1280x720")
	quit()
