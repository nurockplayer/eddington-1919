extends SceneTree
## Headless regression checks for rendered clue hit geometry.
## Run: godot --headless --path . --script res://tests/test_overlay_hits.gd

const Overlay := preload("res://scripts/cambridge/overlay_viewer.gd")

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)


func make_overlay() -> Control:
	var overlay = Overlay.new()
	root.add_child(overlay)
	overlay.visible = true
	return overlay


func local_from_screen(overlay: Control, point: Vector2) -> Vector2:
	return overlay.get_global_transform_with_canvas().affine_inverse() * point


func check_arrow_hits(overlay: Control, context: String) -> void:
	var arrows: Array = [overlay._source_arrow_pixels(), overlay._copy_arrow_pixels()]
	for arrow_index in arrows.size():
		var arrow: Array = arrows[arrow_index]
		var midpoint: Vector2 = (arrow[0] + arrow[1]) * 0.5
		var normal: Vector2 = (arrow[1] - arrow[0]).normalized().orthogonal()
		check(overlay._try_detail_click(local_from_screen(overlay, arrow[0])), "%s arrow %d tail clickable" % [context, arrow_index])
		check(overlay._try_detail_click(local_from_screen(overlay, arrow[1])), "%s arrow %d head clickable" % [context, arrow_index])
		check(overlay._try_detail_click(local_from_screen(overlay, midpoint + normal * 9.5)), "%s arrow %d midpoint with 9.5px padding clickable" % [context, arrow_index])
		check(not overlay._try_detail_click(local_from_screen(overlay, midpoint + normal * 11.0)), "%s arrow %d midpoint beyond 10px padding misses" % [context, arrow_index])


func _run() -> void:
	var overlay = make_overlay()
	await process_frame
	# Both fixed-plate and movable-copy arrows use their rendered endpoints.
	check_arrow_hits(overlay, "default pose")
	for state in [
		{"flipped": true, "angle": 31.0, "offset": Vector2(0.05, -0.04)},
		{"flipped": false, "angle": -47.0, "offset": Vector2(-0.04, 0.06)},
		{"flipped": true, "angle": -18.0, "offset": Vector2(-0.06, -0.05)},
	]:
		overlay.flipped = state.flipped
		overlay.angle_deg = state.angle
		overlay.offset = state.offset
		check_arrow_hits(overlay, "flip %s angle %s offset %s" % [state.flipped, state.angle, state.offset])
	overlay.flipped = false
	overlay.angle_deg = 0.0
	overlay.offset = Vector2.ZERO

	# Canvas transforms can rotate and zoom the whole viewer; the padding stays
	# ten rendered pixels and the segment endpoints still track the drawing.
	overlay.scale = Vector2(1.7, 0.8)
	overlay.rotation = deg_to_rad(23.0)
	check_arrow_hits(overlay, "canvas transform")
	overlay.scale = Vector2.ONE
	overlay.rotation = 0.0

	# A resized viewport changes the pixel segment length; hit endpoints are
	# recomputed from rendered geometry rather than a fixed radius around the tail.
	var arrow: Array = overlay._source_arrow_pixels()
	var old_length: float = arrow[0].distance_to(arrow[1])
	get_root().content_scale_factor = 1.5
	await process_frame
	var resized_arrow: Array = overlay._source_arrow_pixels()
	check(not is_equal_approx(old_length, resized_arrow[0].distance_to(resized_arrow[1])), "arrow hit geometry follows viewport scale")
	check(overlay._try_detail_click(local_from_screen(overlay, resized_arrow[1])), "scaled north-arrow head remains clickable")

	# Glyph bounds follow the same rotation and mirroring used by draw_string.
	for flip in [false, true]:
		overlay.flipped = flip
		for angle in [0.0, 31.0, -47.0]:
			overlay.angle_deg = angle
			var label_rect: Rect2 = overlay._copy_label_hit_rect()
			var label_anchor: Vector2 = overlay.get_global_transform_with_canvas() * overlay._detail_local_position("label_mirrored")
			check(label_rect.has_point(label_anchor), "transformed 14 label bounds include its anchor")
			check(overlay._try_detail_click(local_from_screen(overlay, label_rect.get_center())), "transformed 14 label remains clickable at rotation %s flip %s" % [angle, flip])
			# Use a fresh clue dictionary to ensure each transformed geometry is tested.
			overlay._clues.clear()
	var plate_rect: Rect2 = overlay._plate_label_hit_rect()
	check(plate_rect.size.x > 0.0 and plate_rect.size.y > 0.0, "plate 14 glyph bounds are non-empty")
	check(overlay._try_detail_click(local_from_screen(overlay, plate_rect.get_center())), "fixed plate 14 label is clickable")

	print("test_overlay_hits: %d checks, %d failures" % [checks, failures])
	get_root().content_scale_factor = 1.0
	overlay.queue_free()
	await process_frame
	quit(1 if failures else 0)
