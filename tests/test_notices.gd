extends SceneTree

const Notices = preload("res://scripts/notices.gd")

var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _initialize() -> void:
	var notice := Notices.text()
	for phrase in ["Godot", "SIL Open Font License", "Library of Congress", "CC0"]:
		check(notice.contains(phrase), "notice contains " + phrase)
	var config := ConfigFile.new()
	check(config.load("res://export_presets.cfg") == OK, "export presets load")
	for section in config.get_sections():
		if section.begins_with("preset.") and section.trim_prefix("preset.").is_valid_int():
			var filters := str(config.get_value(section, "include_filter", "")).split(",")
			var entries := PackedStringArray()
			for filter in filters:
				entries.append(filter.strip_edges())
			check(entries.has("THIRD_PARTY_NOTICES.md"), section + " includes notices")
			check(entries.has("assets/fonts/OFL.txt"), section + " includes font licence")
	var provenance := FileAccess.get_file_as_string("res://docs/PROVENANCE.md")
	check(not provenance.contains("No samples"), "provenance has no obsolete sample claim")
	print("%d notice checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
