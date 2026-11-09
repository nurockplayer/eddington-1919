extends SceneTree
## Check the shipped faces directly so installed system fonts cannot hide gaps.

const Fonts := preload("res://scripts/fonts.gd")
const Bundled := preload("res://assets/fonts/NotoSansTC-Regular.otf")
const BundledJP := preload("res://assets/fonts/NotoSansJP-Regular.otf")
const BundledKR := preload("res://assets/fonts/NotoSansKR-Regular.otf")

var checks := 0
var failures := 0
var checked_chars := {}


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)


func _initialize() -> void:
	# Suites start in zh-TW, which uses the bundled TC face on every OS.
	var font := Fonts.cjk()
	check(not (font is SystemFont), "zh-TW uses no system font")
	check(font is FontVariation and font.base_font == Bundled, "zh-TW sets TC first")
	check(font.fallbacks.size() == 2 and font.fallbacks[0] == BundledJP and font.fallbacks[1] == BundledKR, "zh-TW also carries JP and KR fallbacks")
	check(Bundled is FontFile and BundledJP is FontFile and BundledKR is FontFile, "bundled faces load as FontFile")
	for character in ["食", "偏"]:
		check(font.has_char(character.unicode_at(0)), "helper covers " + character)
		check(Bundled.has_char(character.unicode_at(0)), "bundled face covers " + character)
	var english := Fonts.for_locale("en")
	check(not (english is SystemFont), "English uses the bundled faces only")
	check(english is FontVariation and english.base_font == Bundled, "English sets TC first")
	for character in ["한", "の"]:
		check(english.has_char(character.unicode_at(0)), "English fallbacks cover " + character)
	_check_scripts("res://scripts")
	check(not checked_chars.is_empty(), "scanned non-ASCII script characters")
	print("%d script characters checked" % checked_chars.size())
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _covered(codepoint: int) -> bool:
	return Bundled.has_char(codepoint) or BundledJP.has_char(codepoint) or BundledKR.has_char(codepoint)


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
			check(_covered(codepoint), "no bundled face has U+%04X (%s) in %s" % [codepoint, String.chr(codepoint), script_path])
