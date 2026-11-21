extends SceneTree
# Headless scalar keyline checks; optional windowed capture pixel oracle.
# Written 2026-11-19 JST. --capture=<artifact directory> [--variant=main]
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func peak(c: Color) -> float:
	return maxf(c.r, maxf(c.g, c.b))

func contrast(image: Image, point: Vector2) -> float:
	var core := 0.0
	var ring := 1.0
	for y in range(int(point.y) - 3, int(point.y) + 4):
		for x in range(int(point.x) - 3, int(point.x) + 4):
			var radius := (Vector2(x + 0.5, y + 0.5) - point).length()
			var value := peak(image.get_pixel(x, y))
			if radius <= 1.5:
				core = maxf(core, value)
			elif radius <= 2.5:
				ring = minf(ring, value)
	return (core - ring) * 255.0

func changed(a: Image, b: Image, point: Vector2) -> int:
	var count := 0
	for y in range(int(point.y) - 8, int(point.y) + 9):
		for x in range(int(point.x) - 8, int(point.x) + 9):
			if (Vector2(x + 0.5, y + 0.5) - point).length() <= 8.0:
				var delta := a.get_pixel(x, y) - b.get_pixel(x, y)
				if maxf(absf(delta.r), maxf(absf(delta.g), absf(delta.b))) > 0.06:
					count += 1
	return count

# Evaluate the shipping shader's scalar expressions, rather than a copied formula.
# Dummy rendering cannot read back pixels; projection/appearance remain windowed.
func _check_headless_keylines() -> void:
	var source := FileAccess.get_file_as_string("res://shaders/style_engraving.gdshader")
	var expressions := {}
	for name in ["star_vis", "inner_px", "outer_px", "gate", "ring", "bright"]:
		var pattern := RegEx.create_from_string("float " + name + " = ([^;]+);")
		var found := pattern.search(source)
		check(found != null, "shipping shader defines " + name)
		if found == null:
			return
		expressions[name] = found.get_string(1)
	var blend := RegEx.create_from_string("print_colour = (mix\\(print_colour, ink_col, [^;]+);").search(source, source.find("float star_vis ="))
	check(blend != null, "shipping shader applies the keyline to print_colour")
	if blend == null:
		return
	expressions["result"] = blend.get_string(1)
	# Inputs: darkness, night, cloud density, radius, resolution scale, field tone.
	# Expected: a dark reserve only around a visible star, retaining its core.
	for case in [
		[1.0, 0.0, 0.0, 2.0, 1.0, 0.0, 0.0],
		[1.0, 0.0, 0.0, 2.0, 1.0, 1.0, 0.0],
		[0.85, 0.0, 0.0, 2.0, 1.0, 1.0, 1.0],
		[1.0, 1.0, 0.0, 2.0, 1.0, 1.0, 1.0],
		[1.0, 0.0, 0.80, 2.0, 1.0, 1.0, 1.0],
		[1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0],
		[1.0, 0.0, 0.0, 3.0, 1.0, 1.0, 1.0],
		[1.0, 0.0, 0.0, 4.0, 2.0, 1.0, 0.0],
	]:
		var values := {"print_darkness": case[0], "night": case[1],
			"cloud_density": case[2], "distance_px": case[3], "res_k": case[4],
			"field_tone": case[5], "star_keyline_px": 1.0, "star_keyline_all": 1.0,
			"print_colour": 1.0, "ink_col": 0.0}
		for name in expressions:
			var code: String = expressions[name].replace("mix(", "lerpf(")
			code = code.replace("eclipse_cloud_density(direction)", "cloud_density")
			code = code.replace("step(inner_px, distance_px)", "float(distance_px >= inner_px)")
			var expression := Expression.new()
			var parsed := expression.parse(code, PackedStringArray(values.keys()))
			check(parsed == OK, "CPU parses shader " + name + ": " + expression.get_error_text())
			if parsed != OK:
				return
			values[name] = expression.execute(values.values(), null, false)
			check(not expression.has_execute_failed(), "CPU evaluates shader " + name + ": " + expression.get_error_text())
			if expression.has_execute_failed():
				return
		check(is_equal_approx(values.result, case[6]), "keyline darkness/night/cloud/radius/scale/field " + str(case))


func _initialize() -> void:
	_check_headless_keylines()
	var base := ""
	var variant := "all1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): base = arg.trim_prefix("--capture=")
		if arg.begins_with("--variant="): variant = arg.trim_prefix("--variant=")
	if base.is_empty():
		print("WINDOWED ONLY: pixel checks require --capture from a rendered run")
		print("test_corona_stars: %d checks, %d failures" % [checks, failures])
		quit(1 if failures else 0)
		return
	var receipts := FileAccess.open(base.path_join("receipts.jsonl"), FileAccess.READ)
	print("frame\tindex\tgate\tmain_contrast_255\tcontrast_255\tchanged_within_8px")
	while receipts.get_position() < receipts.get_length():
		var rec: Dictionary = JSON.parse_string(receipts.get_line())
		if rec.frame not in ["frames/" + variant + "-totality_wide.png", "frames/" + variant + "-totality_sky.png"]: continue
		var after := Image.load_from_file(base.path_join(rec.frame))
		var before := Image.load_from_file(base.path_join(rec.frame.replace(variant + "-", "main-")))
		check(rec.stars.size() == 12, "all twelve field stars recorded")
		for star in rec.stars:
			var point := Vector2(star.pixel[0], star.pixel[1]) * Vector2(after.get_size()) / Vector2(rec.projection_size[0], rec.projection_size[1])
			check(star.in_frame, "star in frame: " + str(star.index))
			var old := contrast(before, point)
			var value := contrast(after, point)
			var pixels := changed(before, after, point)
			print("%s\t%d\t%.6f\t%.1f\t%.1f\t%d" % [rec.frame, star.index, star.visibility_gate, old, value, pixels])
			if star.visibility_gate >= 0.5:
				check(value >= 60.0, "visible core/ring contrast >=60: " + rec.frame + " star " + str(star.index))
			if star.visibility_gate == 0.0:
				check(pixels == 0, "hidden star draws nothing: " + rec.frame + " star " + str(star.index))
	check(checks > 2, "captures were read")
	print("test_corona_stars: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
