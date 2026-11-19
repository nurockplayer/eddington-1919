extends SceneTree
# Rendered acceptance oracle: windowed capture first, then read pixels headlessly.
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
	for y in range(int(point.y) - 4, int(point.y) + 5):
		for x in range(int(point.x) - 4, int(point.x) + 5):
			var radius := (Vector2(x + 0.5, y + 0.5) - point).length()
			var value := peak(image.get_pixel(x, y))
			if radius <= 1.5:
				core = maxf(core, value)
			elif radius <= 3.25:
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

func _initialize() -> void:
	var base := ""
	var variant := "near1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): base = arg.trim_prefix("--capture=")
		if arg.begins_with("--variant="): variant = arg.trim_prefix("--variant=")
	if base.is_empty():
		printerr("test_corona_stars requires --capture=<windowed artifact directory>")
		quit(2)
		return
	var receipts := FileAccess.open(base.path_join("receipts.jsonl"), FileAccess.READ)
	print("frame\tindex\tgate\tmain_contrast_255\tcontrast_255\tchanged_within_8px")
	while receipts.get_position() < receipts.get_length():
		var rec: Dictionary = JSON.parse_string(receipts.get_line())
		if rec.variant != variant or not rec.has("stars") or rec.frame.contains("horizon"): continue
		var after := Image.load_from_file(base.path_join(rec.frame))
		var before := Image.load_from_file(base.path_join(rec.frame.replace(variant + "-", "main-")))
		check(rec.stars.size() == 12, "all twelve field stars recorded")
		for star in rec.stars:
			var point := Vector2(star.pixel[0], star.pixel[1])
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
