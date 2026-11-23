extends SceneTree

const Settings := preload("res://scripts/settings.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
const Render := preload("res://scripts/plate_render.gd")
const Content := preload("res://scripts/content.gd")


func _initialize() -> void:
	_run.call_deferred()


func _save(game: Node, out: String, name: String, scroll: String) -> void:
	var ui = game.ui
	var viewport: Control = ui.chart.get_parent()
	if viewport is ScrollContainer:
		var bar: VScrollBar = viewport.get_v_scroll_bar()
		if scroll == "bottom":
			viewport.scroll_vertical = int(bar.max_value - bar.page)
		elif scroll == "middle":
			# Halfway through the scroll range, adjusted into a measured row.
			viewport.scroll_vertical = int((bar.max_value - bar.page) * 0.5) + 7
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := out.path_join(name + ".png")
	assert(root.get_texture().get_image().save_png(path) == OK, "failed to save " + path)
	var plates: Array = []
	for plate in game.sim.included_usable():
		var measurement: Dictionary = game.sim.measurement(plate)
		plates.append({"plate": plate.number, "deflection_arcsec": measurement.value,
			"uncertainty_arcsec": measurement.sigma})
	var info := {"frame": name + ".png", "locale": L.current(), "text_scale": Settings.text_scale,
		"scroll": scroll, "scroll_vertical": viewport.scroll_vertical if viewport is ScrollContainer else 0,
		"plates": plates, "combined": game.sim.combined(), "units": "arcseconds"}
	var file := FileAccess.open(out.path_join(name + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(info, "  ") + "\n")
	print("saved ", path)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	var baseline := "--baseline" in args
	root.size = Vector2i(1280, 720)
	var cases := [[12, "ko", 1.2], [1, "en", 1.0]] if baseline else [
		[12, "ko", 1.2], [12, "zh_TW", 1.2],
		[4, "ja", 1.2], [1, "en", 1.0]]
	for item in cases:
		var count: int = item[0]
		var locale: String = item[1]
		var scale: float = item[2]
		L.apply(locale)
		seed(77)
		var game: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		Settings.text_scale = scale
		game.set_process(false)
		game.player.set_physics_process(false)
		game.ui.set_process(false)
		game.ui.hide_title()
		game.ui.hud.hide()
		Settings.refresh_fonts(self)
		game.ui.chart.refresh_fonts()
		game.sim = Sim.new(77)
		game.sim.drive_rate_checked = true
		game.sim.rule_id = "strict"
		game.sim.bet_pick = 2
		game.sim.measured = true
		root.get_node("Story").bet_1917 = {"pick": 3, "year": 1917}
		game.plate_textures.clear()
		for i in count:
			var plate: Dictionary = game.sim.develop({"start": float(i * 24), "duration": 8.0,
				"clear": 8.0, "cloudy": 0.0, "sunlit": false}, i)
			assert(plate.usable, "capture plate must be measurable")
			plate.included = true
			plate.read = true
			plate.reading = game.sim.reading_for_value(plate.value)
			game.sim.plates.append(plate)
			game.plate_textures.append(Render.render(game.sim, plate))
		game.comparison_tex = Render.render(game.sim, null)
		game._open_viewer()
		game.ui.set_viewer_report(true)
		game._refresh_viewer()
		var combined: Dictionary = game.sim.combined()
		var interval := L.t("%.2f″ ± %.2f″，兩倍誤差是 %.2f″ 到 %.2f″") % [combined.value,
			combined.sigma, combined.value - 2 * combined.sigma, combined.value + 2 * combined.sigma]
		game.ui.play(Content.verdict_prompt(interval))
		for i in 20:
			await process_frame
		var label := "%d-%s-%s" % [count, locale, "default" if scale == 1.0 else "max"]
		var scroll := "middle" if locale == "zh_TW" else "top"
		await _save(game, out, label + "-" + scroll, scroll)
		if count == 12 and locale == "ko" and not baseline:
			await _save(game, out, label + "-bottom", "bottom")
		game.stop_all_audio()
		game.free()
	print("report capture complete: ", out)
	quit()
