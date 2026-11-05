extends SceneTree

const Render := preload("res://scripts/plate_render.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
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
	await click_at(ui.big_plate.global_position + (ui.big_plate.size - drawn) * 0.5 + drawn * fraction)


func click_at(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
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
	var sim := Sim.new(1919)
	var real_plate_data := {"index": 0, "fog": 0.0, "trail": 0.0, "stars": sim.STAR_COUNT, "duration": 6.0, "sunlit": false,
		"number": 1, "start": 10.0, "included": true, "usable": true, "quality": "good", "value": 1.75, "sigma": 0.2,
		"read": true, "reading": sim.reading_for_value(1.75)}
	var real_plate := Render.render(sim, real_plate_data)
	var oxford := Render.render(sim, null)
	var before_render := real_plate_data.duplicate(true)
	var star_position: Vector2 = Vector2(Render.SIZE, Render.SIZE) * 0.5 + sim.star_offsets[0] * Render.SUN_PX
	var radial: Vector2 = sim.star_offsets[0].normalized()
	var low := real_plate_data.duplicate(true)
	low.value = 0.0
	low.stars = 1
	var high := low.duplicate(true)
	high.value = 6.0
	var base_peak := star_centroid(oxford.get_image(), star_position)
	var low_peak := star_centroid(Render.render(sim, low).get_image(), star_position)
	var high_peak := star_centroid(Render.render(sim, high).get_image(), star_position)
	check(base_peak.distance_to(star_position) < 1.5, "Oxford star 0 stays at its unshifted field position")
	check((high_peak - base_peak).dot(radial) > (low_peak - base_peak).dot(radial) + 2.0, "larger plate value produces a larger outward star 0 shift")
	check(absf((high_peak - low_peak).cross(radial)) < 1.0, "illustrative shift is radial")
	check(oxford.get_image().get_data() == Render.render(sim, null).get_image().get_data(), "Oxford pixels are independent of plate values")
	check(real_plate_data == before_render, "rendering leaves measurements, quality and star count unchanged")
	ui.loupe_start = Vector2(Render.SIZE, Render.SIZE) * 0.5 + sim.star_offsets[0] * Render.SUN_PX
	sim.plates = [real_plate_data]
	var before_combined := sim.combined()
	ui.measurement_of = Callable(sim, "measurement")
	ui.open_viewer(sim.plates, oxford, [real_plate], false)
	check(ui.plate_info.text.contains("按「閃爍比對」") and ui.plate_info.text.contains("真正的量測用顯微測微器"), "first eligible plate explains the illustrated blink")
	await process_frame
	await click_at(ui.thumbs.get_child(1).get_global_rect().get_center())
	ui.loupe_btn.grab_focus()
	await pad(JOY_BUTTON_A)
	var real_zoom := ui.big_plate.texture as AtlasTexture
	check(real_zoom != null and real_zoom.region.has_point(star_position), "viewer loupe region includes the brightest star")
	check(real_zoom != null and not real_zoom.region.has_point(Vector2(Render.SIZE, Render.SIZE) * 0.5), "viewer loupe region excludes plate centre: star=%s region=%s" % [star_position, real_zoom.region if real_zoom != null else Rect2()])
	await click_at(ui.blink_btn.get_global_rect().get_center())
	check(ui.blink_btn.button_pressed and ui.big_plate.texture.region == real_zoom.region, "blink retains the existing loupe region")
	check(ui.blink_label.text == "第 1 號（全食）・位移已放大（示意）", "eclipse phase labels the exaggeration")
	await next_blink(ui)
	check(ui.big_plate.texture.atlas == oxford and ui.big_plate.texture.region == real_zoom.region, "first half-second shows Oxford with identical crop")
	check(ui.blink_label.text == "牛津（無日）", "Oxford phase label matches atlas")
	await next_blink(ui)
	check(ui.big_plate.texture.atlas == real_plate and ui.big_plate.texture.region == real_zoom.region, "second half-second restores eclipse with identical crop")
	check(ui.blink_label.text == "第 1 號（全食）・位移已放大（示意）", "eclipse phase label returns")
	await click_plate(ui, Vector2(0.2, 0.2))
	var panned_region: Rect2 = ui.big_plate.texture.region
	check(panned_region != real_zoom.region, "click pans while blinking")
	await next_blink(ui)
	check(ui.big_plate.texture.region == panned_region and ui.big_plate.texture.atlas == oxford, "panned crop persists across phase change")
	await click_at(ui.blink_btn.get_global_rect().get_center())
	check(ui.loupe_btn.button_pressed and ui.big_plate.texture.atlas == real_plate and ui.big_plate.texture.region == panned_region and not ui.blink_label.visible, "blink off restores prior loupe with current centre")
	await click_at(ui.blink_btn.get_global_rect().get_center())
	await click_at(ui.thumbs.get_child(0).get_global_rect().get_center())
	check(ui.blink_btn.disabled and not ui.blink_btn.button_pressed and ui.big_plate.texture == oxford, "Oxford selection stops blink and restores full plate")
	await create_timer(0.55).timeout
	check(ui.big_plate.texture == oxford and not ui.blink_label.visible, "stopped blink stays stopped across another interval")
	await click_at(ui.thumbs.get_child(1).get_global_rect().get_center())
	await click_at(ui.blink_btn.get_global_rect().get_center())
	await click_at(ui.blink_btn.get_global_rect().get_center())
	check(not ui.loupe_btn.button_pressed and ui.big_plate.texture == real_plate, "blink off restores previously unzoomed plate")
	ui.set_viewer_locked(true)
	await click_at(ui.blink_btn.get_global_rect().get_center())
	ui.report_pressed.connect(func(): ui.set_viewer_report(true))
	await click_at(ui.report_btn.get_global_rect().get_center())
	check(not ui.blink_btn.button_pressed and not ui.blink_label.visible and ui.big_plate.texture == real_plate, "report button stops blink and restores full eclipse plate")
	check(sim.combined() == before_combined and sim.plates == [before_render], "blinking and report preserve measurements and inclusions")
	ui.close_viewer()
	ui.open_viewer(sim.plates, oxford, [real_plate], false)
	await process_frame
	await click_at(ui.blink_btn.get_global_rect().get_center())
	ui.close_viewer()
	check(not ui.blink_btn.button_pressed and ui.big_plate.texture == real_plate, "closing viewer stops blink")
	ui.open_viewer(sim.plates, oxford, [real_plate], false)
	ui.loupe_btn.grab_focus()
	await pad(JOY_BUTTON_A)
	ui.loupe_start = Vector2(-1, -1)
	var plates := [
		{"number": 1, "start": 10.0, "duration": 6.0, "sunlit": false, "included": true, "usable": true, "stars": 12, "quality": "good", "value": 1.75, "sigma": 0.2,
			"read": true, "reading": sim.reading_for_value(1.75)},
		{"number": 2, "start": 20.0, "duration": 6.0, "sunlit": false, "included": true, "usable": true, "stars": 8, "quality": "poor", "value": 0.87, "sigma": 0.3,
			"read": true, "reading": sim.reading_for_value(0.87)},
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
	check(ui.reference_close_btn.text == "收起參考" and ui.reference_close_btn.has_focus(), "reference overlay focuses its close button")
	await pad(JOY_BUTTON_A)
	check(not ui.reference_panel.visible and not ui.reference_btn.button_pressed and ui.reference_btn.has_focus(), "close button resets toggle and restores focus")
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
	var before_arrow: Vector2 = ui.big_plate.texture.region.position
	var arrow := InputEventKey.new()
	arrow.keycode = KEY_LEFT
	arrow.physical_keycode = KEY_LEFT
	arrow.pressed = true
	root.push_input(arrow)
	await process_frame
	arrow.pressed = false
	root.push_input(arrow)
	await process_frame
	check(ui.big_plate.texture.region.position.x < before_arrow.x and ui.loupe_btn.has_focus(), "keyboard arrow pans without moving loupe focus")
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
	check(ui.plate_info.text.contains("量得偏折：[b]1.75″ ± 0.22″"), "measuring still reveals values")
	check(ui.big_plate.texture == textures[0], "measurement refresh retains original texture")
	ui.set_viewer_locked(false)
	check(not ui.plate_info.text.contains("量得偏折"), "reselect hides measured values again")
	check(plates == original, "reference and loupe leave player plate data untouched")
	# Comparison selection bypasses the measured-plate refresh in set_viewer_locked.
	ui._select_plate(-2, textures[0], false)
	await click_plate(ui, Vector2(0.5, 0.5))
	check(ui.loupe_btn.button_pressed and ui.big_plate.texture is AtlasTexture, "comparison plate is zoomed before report")
	ui.set_viewer_report(true)
	check(not ui.loupe_btn.button_pressed and ui.big_plate.texture == textures[0], "entering report turns loupe off and restores the full comparison plate")
	var many_plates := []
	var many_textures := []
	for i in 12:
		var plate: Dictionary = plates[i % 2].duplicate(true)
		plate.number = i + 1
		many_plates.append(plate)
		many_textures.append(textures[i % 2])
	ui.open_viewer(many_plates, textures[0], many_textures, false)
	for frame in 4:
		await process_frame
	var thumb_rects := []
	for thumb in ui.thumbs.get_children():
		thumb_rects.append(thumb.get_global_rect())
	ui.reference_btn.grab_focus()
	await pad(JOY_BUTTON_A)
	for frame in 4:
		await process_frame
	check(ui.reference_panel.visible and ui.thumbs.get_child_count() == 13, "reference opens alongside twelve developed plates and comparison")
	check(ui.reference_panel.get_global_rect().encloses(ui.big_plate.get_global_rect()), "reference overlay covers the big plate")
	for i in ui.thumbs.get_child_count():
		var thumb := ui.thumbs.get_child(i) as Button
		check(thumb.get_global_rect() == thumb_rects[i], "opening reference leaves thumbnail in place: %d" % i)
		check(root.get_visible_rect().encloses(thumb.get_global_rect()), "large-text thumbnail fits viewport: %d" % i)
		check(not ui.reference_panel.get_global_rect().intersects(thumb.get_global_rect()), "reference does not cover thumbnail: %d" % i)
		await click_at(thumb.get_global_rect().get_center())
		check(ui._viewer_sel == (-2 if i == 0 else i - 1) and thumb.has_focus(), "thumbnail remains clickable with reference open: %d" % i)
	check(root.get_visible_rect().size == Vector2(1600, 900) and Settings.text_scale == 1.2, "layout runs at base size with large text")
	check(root.get_visible_rect().encloses(ui.measure_btn.get_parent().get_global_rect()), "viewer action rows fit viewport at large text")
	check(root.get_visible_rect().encloses(ui.reference_panel.get_global_rect()), "open reference card fits viewport")
	for control in [ui.reference_btn, ui.loupe_btn, ui.blink_btn]:
		check(root.get_visible_rect().encloses(control.get_global_rect()), control.text + " fits viewport")
		for other in ui.viewer.find_children("*", "BaseButton", true, false) + [ui.big_plate, ui.reference_panel]:
			if other != control and other.is_visible_in_tree():
				check(not control.get_global_rect().intersects(other.get_global_rect()), control.text + " does not overlap " + other.name)
	Settings.text_scale = old_scale
	Settings.refresh_fonts(self)
	ui.free()
	await create_timer(0.1).timeout
	print("test_plate_reading: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func next_blink(ui) -> void:
	var current: Texture2D = ui.big_plate.texture.atlas
	var deadline := Time.get_ticks_msec() + 2000
	while ui.big_plate.texture is AtlasTexture and ui.big_plate.texture.atlas == current and Time.get_ticks_msec() < deadline:
		await process_frame
	check(ui.big_plate.texture is AtlasTexture and ui.big_plate.texture.atlas != current, "blink advances through real frame time")


func star_centroid(image: Image, around: Vector2) -> Vector2:
	var total := 0.0
	var weighted := Vector2.ZERO
	for y in range(int(around.y) - 13, int(around.y) + 14):
		for x in range(int(around.x) - 13, int(around.x) + 14):
			var weight := maxf(image.get_pixel(x, y).r - 0.65, 0.0)
			total += weight
			weighted += Vector2(x, y) * weight
	return weighted / maxf(total, 0.001)
