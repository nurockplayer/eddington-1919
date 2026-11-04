extends SceneTree

const Settings := preload("res://scripts/settings.gd")
const Content := preload("res://scripts/content.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
const Render := preload("res://scripts/plate_render.gd")
const Judgment := preload("res://scripts/judgment.gd")
const Overlay := preload("res://scripts/cambridge/overlay_viewer.gd")
const Checklist := preload("res://scripts/cambridge/departure_checklist.gd")
var checks := 0
var failures := 0
var context := ""


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", context, " ", message)


func bounds(node: Node) -> void:
	if node is Control:
		var control := node as Control
		if not control.is_visible_in_tree():
			return
		var rect := control.get_global_rect()
		if rect.size.x > 0 and rect.size.y > 0:
			var viewport := root.get_visible_rect()
			check(viewport.grow(1.0).encloses(rect), "%s rect %s viewport %s" % [control.get_path(), rect, viewport])
		if control is ScrollContainer:
			return
	for child in node.get_children():
		bounds(child)


func settle() -> void:
	for frame in 5:
		await process_frame


func _run() -> void:
	load("res://scripts/main.gd")._ensure_inputs()
	var had_settings := FileAccess.file_exists(Settings.settings_path())
	var original := FileAccess.get_file_as_bytes(Settings.settings_path()) if had_settings else PackedByteArray()
	var story := root.get_node("Story")
	var original_runs: Array = story.runs.duplicate(true)
	var sim := Sim.new(77)
	sim.plates_delivered = sim.MAX_EXTRA_PLATES
	sim.drive_rate_checked = true
	# Run the maximum 12 exposures through the same shutter and cloud model.
	for i in sim.plates_available():
		var start := float(i * 24)
		sim.open_shutter(start)
		for step in 32:
			var t := start + step * 0.25
			sim.accumulate(0.25, sim.cloud_over_sun(t))
		sim.close_shutter(false)
	for plate in sim.plates:
		plate.included = plate.usable
	check(sim.plates.size() == 12 and not sim.included_usable().is_empty(), "maximum real exposures include measurable plates")
	var textures: Array = []
	for plate in sim.plates:
		textures.append(Render.render(sim, plate))
	var comparison := Render.render(sim, null)
	for window in [Vector2i(1600, 900), Vector2i(1280, 800), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = Vector2i(1600, 900)
		root.size = window
		for scale in [1.0, 1.2]:
			context = "%s scale %.1f" % [window, scale]
			Settings.text_scale = scale
			Settings.save_settings()
			var game: Node = load("res://scenes/main.tscn").instantiate()
			root.add_child(game)
			game.set_process(false)
			game.sim = sim
			game.plate_textures = textures
			game.comparison_tex = comparison
			var ui = game.ui
			await settle()
			var expected := Vector2(1600, 1000) if window == Vector2i(1280, 800) else Vector2(1600, 900)
			check(root.get_visible_rect().size.is_equal_approx(expected), "visible rect %s expected %s" % [root.get_visible_rect(), expected])
			ui.hide_title()
			ui.play([Content.rules_prompt(true)[-1]])
			await settle()
			bounds(ui.dialog_panel)
			check(ui._choice_buttons.size() == 3, "three choices are visible")
			check(ui._choice_buttons[0].get_theme_font_size("font_size") == roundi(20 * scale), "choice font follows text scale")
			check(not ui.text_label.get_global_rect().intersects(ui.choice_box.get_global_rect()), "dialogue text overlaps choices")
			for i in ui._choice_buttons.size():
				for j in range(i + 1, ui._choice_buttons.size()):
					check(not ui._choice_buttons[i].get_global_rect().intersects(ui._choice_buttons[j].get_global_rect()), "choice buttons overlap")
			ui.toggle_pause()
			await settle()
			bounds(ui.pause_panel)
			ui.toggle_pause()
			sim.measured = false
			sim.first_result = null
			sim.measured_selection = null
			sim.rule_id = "strict"
			game._open_viewer()
			ui.measure_btn.pressed.emit()
			check(sim.measured and ui.chart.revealed and not ui.chart.rows.is_empty(), "real measurement reveals chart")
			check(ui.thumbs.get_child_count() == 13 and ui.viewer_note.text.contains("兩倍誤差"), "twelve plates and measured note are visible")
			await settle()
			bounds(ui.viewer)
			ui.set_viewer_report(true)
			await settle()
			bounds(ui.viewer)
			ui.close_viewer()
			var overlay := Overlay.new()
			root.add_child(overlay)
			overlay.open()
			await settle()
			bounds(overlay)
			overlay.free()
			var checklist := Checklist.new()
			root.add_child(checklist)
			checklist.open()
			await settle()
			bounds(checklist)
			checklist.free()
			story.runs.clear()
			game._telegram = 1
			game._reason = 0
			game._reasons = Judgment.reasons_for(sim)
			game._grade = Judgment.grade(sim, "hopeful", game._reasons[0].id)
			game._run_record_index = -1
			game._show_ending()
			game._run_record_index = -1
			game._telegram = 2 # Longest authored telegram.
			game._show_ending()
			var review: String = ui.ending_review.text + "\n\n" + Content.run_comparison(story.runs[0], story.runs[1])
			ui.show_ending(ui.ending_title.text, ui.ending_text.text, ui.ending_history.text, review,
				ui.ending_telegram.text, ui.ending_plate.texture, ui.ending_plate_caption.text)
			check(ui.ending_plate.texture != null and ui.ending_telegram.text.contains(Judgment.TELEGRAMS[2].text), "real ending plate and longest telegram")
			await settle()
			bounds(ui.ending_panel)
			bounds(ui.ending_slip)
			bounds(ui.ending_plate_card)
			ui._open_credits()
			await settle()
			bounds(ui.credits_panel)
			game.stop_all_audio()
			game.free()
	story.runs = original_runs
	if had_settings:
		var file := FileAccess.open(Settings.settings_path(), FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.settings_path()))
	Settings.load_settings()
	print("test_layout_bounds: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
