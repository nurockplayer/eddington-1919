extends SceneTree
## Row 8: identical windowed plate/pause cases on main and the candidate.
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
	for locale in L.LOCALES:
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
		for scale in [1.0, 1.2]:
			Settings.text_scale = scale
			Settings.refresh_fonts(self)
			game.ui.chart.refresh_fonts()
			game._open_viewer()
			var label := "default" if scale == 1.0 else "max"
			await frame(out.path_join("plate_%s_%s_720.png" % [locale, label]))
			game.ui.close_viewer()
			game.ui.toggle_pause()
			await frame(out.path_join("pause_%s_%s_720.png" % [locale, label]))
			game.ui.toggle_pause()
		game.stop_all_audio()
		game.free()
	print("layout_720p capture: 16 frames, 1280x720")
	quit()
