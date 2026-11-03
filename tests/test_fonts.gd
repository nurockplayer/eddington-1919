extends SceneTree
## Check the shipped face directly so installed system fonts cannot hide gaps.

const Fonts := preload("res://scripts/fonts.gd")
const Bundled := preload("res://assets/fonts/NotoSansTC-Regular.otf")

var checks := 0
var failures := 0
var checked_chars := {}


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)


func _initialize() -> void:
	var font := Fonts.cjk()
	check(font is SystemFont, "CJK helper keeps system font selection")
	check((font as SystemFont).font_names[0] == "PingFang TC", "PingFang stays first")
	check(font.fallbacks.size() == 1 and font.fallbacks[0] == Bundled, "helper has the bundled fallback")
	check(Bundled is FontFile, "bundled face loads as a FontFile")
	for character in ["食", "偏"]:
		check(font.has_char(character.unicode_at(0)), "helper covers " + character)
		check(Bundled.has_char(character.unicode_at(0)), "bundled face covers " + character)
	_check_scripts("res://scripts")
	check(not checked_chars.is_empty(), "scanned non-ASCII script characters")
	print("%d script characters checked" % checked_chars.size())
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _check_scripts(path: String) -> void:
	var directory := DirAccess.open(path)
	check(directory != null, "can open " + path)
	if directory == null:
		return
	for subdirectory in directory.get_directories():
		_check_scripts(path.path_join(subdirectory))
	for filename in directory.get_files():
		if not filename.ends_with(".gd"):
			continue
		var script_path := path.path_join(filename)
		var file := FileAccess.open(script_path, FileAccess.READ)
		check(file != null, "can read " + script_path)
		if file == null:
			continue
		var source := file.get_as_text()
		for index in source.length():
			var codepoint := source.unicode_at(index)
			if codepoint < 128 or checked_chars.has(codepoint):
				continue
			checked_chars[codepoint] = true
			check(Bundled.has_char(codepoint), "bundled face missing U+%04X (%s) in %s" % [codepoint, String.chr(codepoint), script_path])
