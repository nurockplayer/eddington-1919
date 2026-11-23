extends RefCounted
## Godot ed1daf0bf scene/gui/button.cpp, _shape() and NOTIFICATION_DRAW.
## These plate buttons have a centred, expanded icon above LTR text.


static func geometry(button: Button, initial_draw := false) -> Dictionary:
	var style_names := ["normal", "pressed", "hover", "disabled", "hover_pressed"]
	var style: StyleBox = button.get_theme_stylebox(style_names[button.get_draw_mode()])
	var margins := Vector4(style.get_margin(SIDE_LEFT), style.get_margin(SIDE_TOP), style.get_margin(SIDE_RIGHT), style.get_margin(SIDE_BOTTOM))
	if button.get_theme_constant("align_to_largest_stylebox") != 0:
		for name in style_names:
			var box := button.get_theme_stylebox(name)
			margins = Vector4(maxf(margins.x, box.get_margin(SIDE_LEFT)), maxf(margins.y, box.get_margin(SIDE_TOP)), maxf(margins.z, box.get_margin(SIDE_RIGHT)), maxf(margins.w, box.get_margin(SIDE_BOTTOM)))
	var available := button.size - Vector2(margins.x + margins.z, margins.y + margins.w)
	var paragraph := paragraph_for(button, -1.0 if initial_draw else available.x)
	var icon_size := button.icon.get_size()
	if button.expand_icon:
		var height := available.y - paragraph.get_size().y
		icon_size *= minf(height / icon_size.y, available.x / icon_size.x)
	var max_width := button.get_theme_constant("icon_max_width")
	if max_width > 0 and icon_size.x > max_width:
		icon_size *= max_width / icon_size.x
	icon_size = icon_size.round()
	var icon_offset := Vector2((available.x - icon_size.x) / 2.0 + margins.x, margins.y).floor()
	# Button sets the wrapping width after calculating the icon destination.
	paragraph.width = ceilf(maxf(1.0, available.x))
	var text_offset := Vector2((available.x - paragraph.width) / 2.0 + margins.x, (available.y - icon_size.y - paragraph.get_size().y) / 2.0 + margins.y + icon_size.y)
	var lines := PackedStringArray()
	for i in paragraph.get_line_count():
		var span := paragraph.get_line_range(i)
		lines.append(button.text.substr(span.x, span.y - span.x).strip_edges())
	return {"paragraph": paragraph, "lines": lines, "text_position": button.global_position + text_offset,
		"image": Rect2(button.global_position + icon_offset, icon_size)}


static func paragraph_for(node, width: float) -> TextParagraph:
	var paragraph := TextParagraph.new()
	var flags := TextServer.BREAK_MANDATORY
	match node.autowrap_mode:
		TextServer.AUTOWRAP_WORD_SMART:
			flags |= TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
		TextServer.AUTOWRAP_WORD:
			flags |= TextServer.BREAK_WORD_BOUND
		TextServer.AUTOWRAP_ARBITRARY:
			flags |= TextServer.BREAK_GRAPHEME_BOUND
	paragraph.break_flags = flags | node.autowrap_trim_flags
	paragraph.line_spacing = node.get_theme_constant("line_spacing")
	paragraph.direction = TextServer.DIRECTION_LTR if node.text_direction == Control.TEXT_DIRECTION_INHERITED else node.text_direction
	paragraph.add_string(node.text, node.get_theme_font("font"), node.get_theme_font_size("font_size"), node.language if node.language != "" else TranslationServer.get_locale())
	paragraph.text_overrun_behavior = node.text_overrun_behavior
	paragraph.alignment = node.horizontal_alignment if node is Label else node.alignment
	paragraph.width = -1.0 if width < 0 else ceilf(maxf(1.0, width))
	return paragraph


static func font_color(button: Button) -> Color:
	var keys := ["font_focus_color" if button.has_focus() else "font_color", "font_pressed_color", "font_hover_color", "font_disabled_color", "font_hover_pressed_color"]
	return button.get_theme_color(keys[button.get_draw_mode()])


static func raster(tree: SceneTree, button: Button, layout: Dictionary, image_size: Vector2i) -> Image:
	var viewport := SubViewport.new()
	viewport.size = image_size
	viewport.size_2d_override = tree.root.get_visible_rect().size
	viewport.size_2d_override_stretch = true
	viewport.oversampling_override = tree.root.get_oversampling()
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var canvas := Control.new()
	viewport.add_child(canvas)
	canvas.draw.connect(func():
		var paragraph: TextParagraph = layout.paragraph
		paragraph.draw(canvas.get_canvas_item(), layout.text_position, font_color(button)))
	tree.root.add_child(viewport)
	canvas.queue_redraw()
	await tree.process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image()
	viewport.free()
	return result


static func measure(tree: SceneTree, button: Button, original: Image, layout: Dictionary) -> Dictionary:
	var mask := await raster(tree, button, layout, original.get_size())
	var pixel_scale := Vector2(original.get_size()) / tree.root.get_visible_rect().size
	var tile := button.get_global_rect().grow(40)
	var region := Rect2i((tile.position * pixel_scale).floor(), (tile.size * pixel_scale).ceil()).intersection(Rect2i(Vector2i.ZERO, original.get_size()))
	var ink := Rect2i()
	var pixels := 0
	var cores := 0
	var matches := 0
	var color := font_color(button)
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			if mask.get_pixel(x, y).a > 0.03:
				var pixel := Rect2i(x, y, 1, 1)
				ink = pixel if pixels == 0 else ink.merge(pixel)
				pixels += 1
			if mask.get_pixel(x, y).a < 0.95:
				continue
			cores += 1
			var matched := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var at := Vector2i(x + dx, y + dy)
					if not region.has_point(at):
						continue
					var observed := original.get_pixelv(at)
					if maxf(absf(observed.r - color.r), maxf(absf(observed.g - color.g), absf(observed.b - color.b))) < 0.10:
						matched = true
			if matched:
				matches += 1
	return {"caption": Rect2(Vector2(ink.position) / pixel_scale, Vector2(ink.size) / pixel_scale),
		"image": layout.image, "raster_match": float(matches) / maxi(1, cores), "cores": cores, "mask": mask}


static func probe(tree: SceneTree, button: Button, out: String) -> bool:
	for i in 8:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var original := tree.root.get_texture().get_image()
	var layout := geometry(button, true)
	original.save_png(out.path_join("untouched.png"))
	var colors := {}
	var font_masked: Image
	for keys in [["font_color", "font_outline_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"], ["icon_normal_color", "icon_focus_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_disabled_color"]]:
		for key in keys:
			colors[key] = [button.has_theme_color_override(key), button.get_theme_color(key)]
			button.add_theme_color_override(key, Color.TRANSPARENT)
		await tree.process_frame
		await RenderingServer.frame_post_draw
		if keys[0] == "font_color":
			font_masked = tree.root.get_texture().get_image()
		tree.root.get_texture().get_image().save_png(out.path_join("font-masked.png" if keys[0] == "font_color" else "font-icon-masked.png"))
	for key in colors:
		if colors[key][0]:
			button.add_theme_color_override(key, colors[key][1])
		else:
			button.remove_theme_color_override(key)
	for i in 5:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var restored := tree.root.get_texture().get_image()
	restored.save_png(out.path_join("restored.png"))
	# Complete the masking comparison before the offscreen renderer is created.
	var measured := await measure(tree, button, original, layout)
	measured.mask.save_png(out.path_join("reconstructed-text.png"))
	var pixel_scale := Vector2(original.get_size()) / tree.root.get_visible_rect().size
	var tile := button.get_global_rect().grow(10)
	var region := Rect2i((tile.position * pixel_scale).floor(), (tile.size * pixel_scale).ceil())
	var changed := 0
	var masked_nontext_changed := 0
	var max_delta := 0.0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var a := original.get_pixel(x, y)
			var hidden := font_masked.get_pixel(x, y)
			var glyph := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					glyph = glyph or measured.mask.get_pixel(x + dx, y + dy).a > 0.03
			if not glyph and maxf(absf(a.r - hidden.r), maxf(absf(a.g - hidden.g), absf(a.b - hidden.b))) > 0.03:
				masked_nontext_changed += 1
			var b := restored.get_pixel(x, y)
			var delta := maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))
			max_delta = maxf(max_delta, delta)
			if delta > 0.03:
				changed += 1
	var report := {"case": "zh_TW plate 12 max 1280x720", "lines": layout.lines,
		"original_caption": str(measured.caption), "icon_draw_rect": str(layout.image),
		"glyph_core_pixels": measured.cores, "original_raster_match": measured.raster_match,
		"masked_nontext_changed_pixels": masked_nontext_changed,
		"masking_preserves_geometry": changed == 0 and masked_nontext_changed == 0,
		"restored_changed_pixels": changed, "restored_max_rgb_delta": max_delta,
		"window": str(tree.root.size), "viewport": str(tree.root.get_visible_rect()),
		"canvas_transform": str(button.get_global_transform_with_canvas()), "tile": str(button.get_global_rect())}
	var file := FileAccess.open(out.path_join("probe.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  ") + "\n")
	print("Native probe: ", JSON.stringify(report))
	return measured.cores > 0 and measured.raster_match >= 0.90 and "讀" in layout.lines
