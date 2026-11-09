extends SceneTree

const PackCheck = preload("res://tools/check_release_pack.gd")
const SCRATCH := "res://.godot/release_pack_test"

var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _initialize() -> void:
	check(DirAccess.make_dir_recursive_absolute(SCRATCH) == OK, "create worktree-local scratch directory")
	var source := SCRATCH.path_join("source.txt")
	var file := FileAccess.open(source, FileAccess.WRITE)
	file.store_string("Tiny release parser fixture\n")
	file.close()
	var pack_path := SCRATCH.path_join("tiny.pck")
	var packer := PCKPacker.new()
	check(packer.pck_start(pack_path) == OK, "start a real PCK with installed Godot")
	var expected := PackedStringArray([
		"res://THIRD_PARTY_NOTICES.md",
		"res://assets/fonts/OFL.txt",
		"res://assets/sample.txt",
		"res://locale/en.po",
		"res://locale/ja.po",
		"res://locale/ko.po",
	])
	for path in expected:
		check(packer.add_file(path, source) == OK, "pack " + path)
	check(packer.flush() == OK, "flush six-file PCK")
	var paths := PackCheck.read_paths(pack_path)
	paths.sort()
	expected.sort()
	check(paths == expected, "direct parser lists exactly the six packed files")
	# Reuse the real pack's table and payloads to exercise both earlier headers.
	var packed := FileAccess.get_file_as_bytes(pack_path)
	var directory_offset := packed.decode_u64(32)
	var payload_offset := packed.decode_u64(24)
	var table := packed.slice(directory_offset)
	for version in [2, 3]:
		var bytes := packed.duplicate()
		bytes.encode_u32(4, version)
		if version == 2:
			bytes.resize(32)
			bytes.encode_u64(24, 96 + table.size())
			bytes.resize(96)
			bytes.append_array(table)
			bytes.append_array(packed.slice(payload_offset, directory_offset))
		var legacy_path := SCRATCH.path_join("v%d.pck" % version)
		file = FileAccess.open(legacy_path, FileAccess.WRITE)
		file.store_buffer(bytes)
		file.close()
		var legacy_paths := PackCheck.read_paths(legacy_path)
		legacy_paths.sort()
		check(legacy_paths == expected, "format %d header lists the same three files" % version)
		DirAccess.remove_absolute(legacy_path)
	check(PackCheck.violations(paths).is_empty(), "notice and font licence pass the release policy")
	for forbidden in ["res://tests/no_ship.gd", "res://assets/licensed/no_ship.glb"]:
		var bad := paths.duplicate()
		bad.append(forbidden)
		check(PackCheck.violations(bad).size() == 1, "reject " + forbidden)
	for required in ["res://THIRD_PARTY_NOTICES.md", "res://assets/fonts/OFL.txt",
			"res://locale/en.po", "res://locale/ja.po", "res://locale/ko.po"]:
		var missing := paths.duplicate()
		if missing.has(required):
			missing.remove_at(missing.find(required))
		check(PackCheck.violations(missing).size() == 1, "reject missing " + required)
	DirAccess.remove_absolute(pack_path)
	DirAccess.remove_absolute(source)
	DirAccess.remove_absolute(SCRATCH)
	print("%d release pack checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
