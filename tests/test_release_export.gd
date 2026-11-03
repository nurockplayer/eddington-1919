extends SceneTree

var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _initialize() -> void:
	var project := ConfigFile.new()
	check(project.load("res://project.godot") == OK, "project settings load")
	var version := str(project.get_value("application", "config/version", ""))
	check(version == "0.3.0", "project defines release version")
	check(project.get_value("application", "config/icon", "") == "res://icon.svg", "project defines SVG icon")
	_test_icon()
	_test_committed_icon()
	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	check(error == OK, "export presets load")
	var presets := 0
	for section in config.get_sections():
		if not section.begins_with("preset.") or not section.trim_prefix("preset.").is_valid_int():
			continue
		presets += 1
		if config.get_value(section, "platform", "") == "macOS":
			check(config.get_value(section + ".options", "application/icon", "") == "res://assets/icon/icon_1024.png", "macOS preset uses committed PNG")
		for key in ["application/short_version", "application/version"]:
			check(config.get_value(section + ".options", key, "") == version, section + " " + key + " matches project version")
		var filters := str(config.get_value(section, "exclude_filter", "")).split(",")
		var entries := PackedStringArray()
		for filter in filters:
			entries.append(filter.strip_edges())
		check(entries.has("assets/licensed/*"), section + " excludes licensed assets")
		check(entries.has("tests/*"), section + " excludes tests")
	check(presets > 0, "at least one export preset exists")
	print("%d release export checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_icon() -> void:
	var image := Image.new()
	var svg := FileAccess.get_file_as_string("res://icon.svg")
	check(image.load_svg_from_string(svg, 32.0 / 1024.0) == OK, "res://icon.svg loads at 32 px")
	if image.is_empty():
		return
	var path := "res://.godot/icon_32_check.png"
	check(image.save_png(path) == OK, "32 px icon renders to PNG")
	image = Image.load_from_file(path)
	DirAccess.remove_absolute(path)
	check(image != null and image.get_size() == Vector2i(32, 32), "rendered PNG is 32 × 32")
	if image == null or image.get_size() != Vector2i(32, 32):
		return
	var centre := image.get_pixel(16, 16)
	check(maxf(centre.r, maxf(centre.g, centre.b)) < 0.04, "Moon centre stays near-black at 32 px")
	var bead := Vector2(771.8, 362.0) / 32.0
	var bright := false
	for y in 32:
		for x in 32:
			if Vector2(x + 0.5, y + 0.5).distance_to(bead) > 20.0 / 32.0:
				continue
			var pixel := image.get_pixel(x, y)
			var luminance := 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b
			bright = bright or (pixel.a > 0.8 and luminance > 0.8)
	check(bright, "2 o'clock bead has luminance > 0.8 within 20 SVG px at 32 px")


func _test_committed_icon() -> void:
	var image := Image.load_from_file("res://assets/icon/icon_1024.png")
	check(image != null and image.get_size() == Vector2i(1024, 1024), "committed macOS icon is 1024 × 1024")
	if image == null or image.get_size() != Vector2i(1024, 1024):
		return
	var centre := image.get_pixel(512, 512)
	check(centre.a > 0.99 and maxf(centre.r, maxf(centre.g, centre.b)) < 0.04, "committed PNG Moon centre is opaque near-black")
	var bead := Vector2(771.8, 362.0)
	var bright := false
	for y in range(342, 383):
		for x in range(751, 793):
			if Vector2(x + 0.5, y + 0.5).distance_to(bead) > 20.0:
				continue
			var pixel := image.get_pixel(x, y)
			var luminance := 0.2126 * pixel.r + 0.7152 * pixel.g + 0.0722 * pixel.b
			bright = bright or (pixel.a > 0.8 and luminance > 0.8)
	check(bright, "committed PNG has a bright 2 o'clock bead")
	var corner := image.get_pixel(0, 0)
	var background := Color("101826")
	var matches_background := absf(corner.r - background.r) < 0.01 and absf(corner.g - background.g) < 0.01 and absf(corner.b - background.b) < 0.01
	check(corner.a < 0.01 or matches_background, "committed PNG corner is transparent or night-blue")
