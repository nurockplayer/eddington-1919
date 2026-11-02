extends SceneTree

var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _initialize() -> void:
	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	check(error == OK, "export presets load")
	var presets := 0
	for section in config.get_sections():
		if not section.begins_with("preset.") or not section.trim_prefix("preset.").is_valid_int():
			continue
		presets += 1
		var filters := str(config.get_value(section, "exclude_filter", "")).split(",")
		var entries := PackedStringArray()
		for filter in filters:
			entries.append(filter.strip_edges())
		check(entries.has("assets/licensed/*"), section + " excludes licensed assets")
		check(entries.has("tests/*"), section + " excludes tests")
	check(presets > 0, "at least one export preset exists")
	print("%d release export checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
