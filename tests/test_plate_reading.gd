extends SceneTree

const Render := preload("res://scripts/plate_render.gd")
const UI := preload("res://scripts/ui.gd")
const Settings := preload("res://scripts/settings.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func brightness(image: Image) -> float:
	var total := 0.0
	for y in image.get_height():
		for x in image.get_width():
			total += image.get_pixel(x, y).r
	return total / (image.get_width() * image.get_height())


func longest_star_run(image: Image) -> int:
	var longest := 0
	for y in image.get_height():
		var run := 0
		for x in image.get_width():
			# Exclude the corona; count only bright runs through the outer star field.
			if Vector2(x, y).distance_to(Vector2(180, 180)) > 80 and image.get_pixel(x, y).r > 0.4:
				run += 1
				longest = maxi(longest, run)
			else:
				run = 0
	return longest


func pad(index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func click_plate(ui, fraction: Vector2) -> void:
	var drawn := Vector2.ONE * minf(ui.big_plate.size.x, ui.big_plate.size.y)
	var event := InputEventMouseButton.new()
	event.position = ui.big_plate.global_position + (ui.big_plate.size - drawn) * 0.5 + drawn * fraction
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func _run() -> void:
	var textures := []
	for kind in ["sharp", "trailed", "fogged"]:
		var tex := Render.render_example(kind)
		textures.append(tex)
		check(tex is ImageTexture and tex.get_size() == Vector2(360, 360), kind + " is a 360×360 texture")
		check(tex.get_image().get_data() == Render.render_example(kind).get_image().get_data(), kind + " is deterministic")
	var sharp: Image = textures[0].get_image()
	var trailed: Image = textures[1].get_image()
	var fogged: Image = textures[2].get_image()
	check(sharp.get_data() != trailed.get_data() and sharp.get_data() != fogged.get_data() and trailed.get_data() != fogged.get_data(), "three distinct examples")
	check(brightness(fogged) > brightness(sharp), "fog veil raises mean brightness")
	check(longest_star_run(trailed) > longest_star_run(sharp), "trailing elongates bright row runs")
	load("res://scripts/main.gd")._ensure_inputs()
	root.size = Vector2i(1600, 900)
	var ui := UI.new()
	root.add_child(ui)
	await process_frame
	ui.hide_title()
	var old_scale := Settings.text_scale
	Settings.text_scale = 1.2
	Settings.refresh_fonts(self)
	ui.theme_res.default_font_size = Settings.fs(21)
	var plates := [
		{"number": 1, "start": 10.0, "duration": 6.0, "sunlit": false, "included": true, "usable": true, "stars": 12, "quality": "good", "value": 1.75, "sigma": 0.2},
		{"number": 2, "start": 20.0, "duration": 6.0, "sunlit": false, "included": true, "usable": true, "stars": 8, "quality": "poor", "value": 0.87, "sigma": 0.3},
	]
	var original := plates.duplicate(true)
	ui.open_viewer(plates, textures[0], textures.slice(0, 2), false)
	check(ui.reference_panel.get_child_count() == 0 and not ui.reference_panel.visible, "examples start hidden and lazy")
	ui.reference_btn.grab_focus()
	await pad(JOY_BUTTON_A)
	check(ui.reference_panel.visible, "reference button opens panel with gamepad A")
	var examples := ui.reference_panel.find_children("*", "TextureRect", true, false)
	check(examples.size() == 3, "reference panel contains three example plates")
	var captions := []
	for label in ui.reference_panel.find_children("*", "Label", true, false):
		captions.append(label.text)
	check(captions == ["星點清楚：小而圓", "拖長：每顆星都拉成同方向的短線（時鐘走速不準）", "起霧：雲光蓋住，星點淡、數得到的少", "示意圖，不是你的底片。"], "reference captions clearly identify illustrations")
	await pad(JOY_BUTTON_A)
	check(not ui.reference_panel.visible, "reference button hides panel")
	await pad(JOY_BUTTON_A)
	check(ui.reference_panel.find_children("*", "TextureRect", true, false)[0].texture == examples[0].texture, "reopening reuses the same textures")
	for i in plates.size():
		ui._select_plate(i, textures[i], false)
		check(not ui.plate_info.text.contains("星像清楚") and not ui.plate_info.text.contains("拖長或被雲霧蓋住") and not ui.plate_info.text.contains("量得偏折") and not ui.plate_info.text.contains("±"), "player quality and values stay hidden before measuring")
		check(not ui.thumbs.get_child(i + 1).text.contains("清楚") and not ui.thumbs.get_child(i + 1).text.contains("拖長"), "player thumbnails contain no quality captions")
	ui.loupe_btn.grab_focus()
	await pad(JOY_BUTTON_A)
	var zoom := ui.big_plate.texture as AtlasTexture
	check(zoom != null and zoom.atlas == textures[1] and zoom.region == Rect2(90, 90, 180, 180), "loupe shows centred half-size region of current plate")
	await pad(JOY_BUTTON_DPAD_RIGHT)
	check(ui.big_plate.texture.region.position.x > 90 and ui.loupe_btn.has_focus(), "D-pad pans without moving focus")
	var before: Vector2 = ui.big_plate.texture.region.position
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_RIGHT_Y
	motion.axis_value = 0.8
	Input.parse_input_event(motion.duplicate())
	Input.flush_buffered_events()
	for frame in 8:
		await physics_frame
	motion.axis_value = 0.0
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	check(ui.big_plate.texture.region.position.y > before.y, "right stick pans region")
	await pad(JOY_BUTTON_A)
	check(not ui.loupe_btn.button_pressed and ui.big_plate.texture == textures[1], "toggle restores full plate")
	await click_plate(ui, Vector2(0.001, 0.001))
	check(ui.big_plate.texture is AtlasTexture and ui.big_plate.texture.region == Rect2(0, 0, 180, 180), "plate click enables loupe and clamps top-left")
	await click_plate(ui, Vector2(0.999, 0.999))
	check(ui.big_plate.texture.region.position.x > 0, "click while zoomed moves centre within shown region")
	ui._select_plate(0, textures[0], false)
	check(not ui.loupe_btn.button_pressed and ui.big_plate.texture == textures[0], "selecting another plate resets loupe")
	await click_plate(ui, Vector2(0.999, 0.999))
	check(ui.big_plate.texture.region == Rect2(180, 180, 180, 180), "bottom-right crop stays inside texture")
	ui.set_viewer_locked(true)
	check(ui.plate_info.text.contains("量得偏折：[b]1.75″ ± 0.20″"), "measuring still reveals values")
	check(ui.big_plate.texture == textures[0], "measurement refresh retains original texture")
	ui.set_viewer_locked(false)
	check(not ui.plate_info.text.contains("量得偏折"), "reselect hides measured values again")
	for frame in 4:
		await process_frame
	check(root.get_visible_rect().size == Vector2(1600, 900) and Settings.text_scale == 1.2, "layout runs at base size with large text")
	check(root.get_visible_rect().encloses(ui.measure_btn.get_parent().get_global_rect()), "viewer action rows fit viewport at large text")
	check(root.get_visible_rect().encloses(ui.reference_panel.get_global_rect()), "open reference card fits viewport")
	for control in [ui.reference_btn, ui.loupe_btn]:
		check(root.get_visible_rect().encloses(control.get_global_rect()), control.text + " fits viewport")
		for other in ui.viewer.find_children("*", "BaseButton", true, false) + [ui.big_plate, ui.reference_panel]:
			if other != control and other.is_visible_in_tree():
				check(not control.get_global_rect().intersects(other.get_global_rect()), control.text + " does not overlap " + other.name)
	check(plates == original, "reference and loupe leave player plate data untouched")
	Settings.text_scale = old_scale
	Settings.refresh_fonts(self)
	ui.free()
	await create_timer(0.1).timeout
	print("test_plate_reading: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
