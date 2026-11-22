extends SceneTree
## Authored dialogue sites, including every branch; presentation comes from the real UI.
const UI := preload("res://scripts/ui.gd")
const Style := preload("res://scripts/style.gd")
const L := preload("res://scripts/l10n.gd")
const REPORT := "res://docs/design/PORTRAIT_COVERAGE.md"
const CHAPTERS := ["Cambridge 1917", "Departure", "Príncipe 1919 (including coda)", "October epilogue"]
const SOURCES := [
	"res://scripts/cambridge/content_1917.gd",
	"res://scripts/cambridge/content_departure.gd",
	"res://scripts/content.gd",
	"res://scripts/content_coda.gd",
	"res://scripts/cambridge/content_epilogue.gd",
	"res://scripts/main.gd",
]
const DIRECTORS := [
	"res://scripts/cambridge/director.gd",
	"res://scripts/cambridge/departure_director.gd",
	"res://scripts/main.gd",
	"res://scripts/cambridge/epilogue_director.gd",
]
const LOCALES := ["en", "ja", "zh_TW", "ko"]


func _initialize() -> void:
	_generate.call_deferred()


func _generate() -> void:
	var file := FileAccess.open(REPORT, FileAccess.WRITE)
	file.store_string(render(self))
	file.close()
	print("Wrote ", REPORT)
	quit()


static func speaker_value(expression: String, constants: Dictionary) -> String:
	if expression.begins_with("L.t("):
		return expression.substr(4, expression.length() - 5).c_unescape().trim_prefix('"').trim_suffix('"')
	if expression.begins_with('"'):
		return expression.substr(1, expression.length() - 2).c_unescape()
	var value: Variant = constants
	for part in expression.split("."):
		if value is Script:
			value = value.get_script_constant_map()
		value = value[part]
	return str(value)


static func entries(source: String, constants: Dictionary, chapter: int) -> Array:
	var result := []
	var speaker := RegEx.new()
	speaker.compile('"s"\\s*:\\s*(L\\.t\\("(?:[^"\\\\]|\\\\.)*"\\)|"(?:[^"\\\\]|\\\\.)*"|[A-Za-z_][A-Za-z_0-9.]*)')
	var mood := RegEx.new()
	mood.compile('"mood"\\s*:\\s*"([^"]+)"')
	var function_name := ""
	for line in source.split("\n"):
		if line.begins_with("static func ") or line.begins_with("func "):
			function_name = line.split("func ")[1].split("(")[0]
		if line.strip_edges().begins_with("#"):
			continue
		for found in speaker.search_all(line):
			var tail: String = line.substr(found.get_end()).split("}")[0]
			var expression := mood.search(tail)
			result.append({"chapter": 2 if function_name == "principe_workbook" else chapter,
				"s": speaker_value(found.get_string(1), constants),
				"mood": expression.get_string(1) if expression else "neutral", "t": "Coverage"})
	return result


static func authored_entries() -> Array:
	var result := []
	for i in SOURCES.size():
		var script: Script = load(SOURCES[i])
		result.append_array(entries(FileAccess.get_file_as_string(SOURCES[i]), script.get_script_constant_map(), [0, 1, 2, 2, 3, 2][i]))
	return result


static func chapter_ui(tree: SceneTree, chapter: int) -> Node:
	var ui := UI.new()
	tree.root.add_child(ui)
	ui.hide_title()
	# The three Cambridge-room directors opt in themselves; main's style dresses its UI.
	ui.cambridge_portraits = FileAccess.get_file_as_string(DIRECTORS[chapter]).contains("ui.cambridge_portraits = true")
	if chapter == 2:
		Style.from_args({}).dress_dialogue(ui)
	return ui


static func render(tree: SceneTree, all_entries: Array = authored_entries()) -> String:
	var text := "# Speaker / portrait coverage\n\nRegenerate: `tachi-run --host -- godot --headless --path . --script res://tools/portrait_coverage.gd`\n\n"
	text += "Acceptance row: **F4**, portrait clause made judgeable; existing gaps remain.\n\n"
	text += "Counts are authored dialogue entry sites (`s` dictionaries), across all conditional and choice branches, not one playthrough. A repeated or data-driven entry template counts once; choices, captions, toasts and text embedded within an entry are not extra lines. Inline entries in `main.gd` are included. The Príncipe workbook in Departure's content file and the May coda belong to Príncipe; October is the separate epilogue.\n\n"
	text += "Default main presentation (engraving; no debug overrides). Paths and names are obtained by playing each entry through `ui.gd` and `dialogue_portrait.gd`, with main's `Style.dress_dialogue`. Names are shown in en / ja / zh-TW / ko order; `(blank)` is an empty name, not an inferred person. `none` records a coverage gap, including unnamed narration.\n\n"
	for chapter in CHAPTERS.size():
		var ui := chapter_ui(tree, chapter)
		var rows := {}
		for entry in all_entries:
			if entry.chapter != chapter:
				continue
			var names := PackedStringArray()
			for locale in LOCALES:
				L.apply(locale)
				ui.play([entry])
				names.append(ui.speaker_label.text if not ui.speaker_label.text.is_empty() else "(blank)")
			var path := "none"
			if ui.dialogue_portrait.visible:
				path = ui.dialogue_portrait.image.texture.resource_path
			var key: String = entry.s + "\t" + path
			if not rows.has(key):
				rows[key] = {"speaker": entry.s, "path": path, "names": " / ".join(names), "count": 0}
			rows[key].count += 1
		text += "## %s\n\n| Speaker (source) | Line count | Portrait path | Displayed name (en / ja / zh-TW / ko) |\n| --- | ---: | --- | --- |\n" % CHAPTERS[chapter]
		var keys := rows.keys()
		keys.sort()
		for key in keys:
			var row: Dictionary = rows[key]
			text += "| %s | %d | %s | %s |\n" % [row.speaker if row.speaker != "" else "(blank)", row.count, row.path, row.names]
		text += "\n"
		ui.free()
	# Text changes with unchanged counts also invalidate the committed report.
	var inputs := PackedStringArray()
	for path in SOURCES + DIRECTORS + ["res://scripts/ui.gd", "res://scripts/style.gd", "res://scripts/styles/engraving.gd", "res://scripts/cambridge/dialogue_portrait.gd", "res://scripts/cambridge/cast.gd"]:
		inputs.append(path + ":" + FileAccess.get_file_as_string(path).sha256_text())
	text += "Source fingerprint: `%s`\n" % "\n".join(inputs).sha256_text()
	return text
