extends SceneTree
## Read the PCK directory directly; do not mount it or enumerate res://.

static func read_paths(path: String) -> PackedStringArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 32 or file.get_32() != 0x43504447:
		push_error("Invalid PCK header: " + path)
		return []
	var version := file.get_32()
	var major := file.get_32()
	var minor := file.get_32()
	var patch := file.get_32()
	print("PCK format version %d (Godot %d.%d.%d)" % [version, major, minor, patch])
	if version != 2 and version != 3 and version != 4:
		push_error("Unsupported PCK format version: %d (expected 2, 3 or installed writer's 4)" % version)
		return []
	var pack_flags := file.get_32()
	file.get_64()  # Files-base offset; payloads are not needed for a directory listing.
	if pack_flags & 1:
		push_error("Encrypted PCK directory cannot be inspected")
		return []
	if pack_flags & ~2:
		push_error("Unsupported PCK flags: %d" % pack_flags)
		return []
	var directory_offset := 96  # V2: 32-byte header plus 16 reserved u32s.
	if version >= 3:
		if file.get_length() < 104:
			push_error("Truncated PCK v3/v4 header")
			return []
		directory_offset = file.get_64()  # V3/V4 skip reserved words and payloads.
	if directory_offset < (104 if version >= 3 else 96) or directory_offset > file.get_length() - 4:
		push_error("Invalid PCK directory offset")
		return []
	file.seek(directory_offset)
	var count := file.get_32()
	var paths := PackedStringArray()
	for _index in count:
		if file.get_position() + 4 > file.get_length():
			push_error("Truncated PCK path length")
			return []
		var path_length := file.get_32()
		var padded_length := (path_length + 3) & ~3
		if path_length == 0 or file.get_position() + padded_length + 36 > file.get_length():
			push_error("Truncated PCK directory entry")
			return []
		var bytes := file.get_buffer(padded_length)
		var terminator := bytes.find(0)
		if terminator >= 0:
			bytes = bytes.slice(0, terminator)
		var entry := bytes.get_string_from_utf8().trim_prefix("res://")
		paths.append(("res://" + entry).simplify_path())
		file.get_64()  # File offset.
		file.get_64()  # File size.
		file.get_buffer(16)  # MD5.
		file.get_32()  # File flags.
	return paths


static func violations(paths: PackedStringArray) -> PackedStringArray:
	var errors := PackedStringArray()
	for path in paths:
		if path.begins_with("res://assets/licensed/") or path.begins_with("res://tests/"):
			errors.append("Forbidden release path: " + path)
	for required in ["res://THIRD_PARTY_NOTICES.md", "res://assets/fonts/OFL.txt"]:
		if not paths.has(required):
			errors.append("Release PCK lacks " + required)
	for locale in ["en", "ja", "ko"]:
		if not _has_translation(paths, locale):
			errors.append("Release PCK lacks locale/" + locale + ".po")
	return errors


## A .po file packs as its source path or through an import/remap, so match either.
static func _has_translation(paths: PackedStringArray, locale: String) -> bool:
	for path in paths:
		if path.contains("locale/" + locale + ".po") or path.contains("imported/" + locale + ".po"):
			return true
	return false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Expected one release PCK path")
		quit(1)
		return
	var paths := read_paths(args[0])
	if paths.is_empty():
		quit(1)
		return
	var errors := violations(paths)
	for error in errors:
		push_error(error)
	print("Release PCK: notices and OFL present, forbidden paths absent" if errors.is_empty() else "Release PCK rejected")
	quit(0 if errors.is_empty() else 1)
