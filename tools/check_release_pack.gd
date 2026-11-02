extends SceneTree
## Called by export_release.sh with an empty --path, never the source checkout.

var forbidden := false


func _scan(path: String) -> void:
	for directory in DirAccess.get_directories_at(path):
		var child := path.path_join(directory)
		if child == "res://assets/licensed" or child == "res://tests":
			push_error("Forbidden release path: " + child)
			forbidden = true
		else:
			_scan(child)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not ProjectSettings.load_resource_pack(args[0]):
		push_error("Could not load release PCK")
		quit(1)
		return
	_scan("res://")
	if not FileAccess.file_exists("res://THIRD_PARTY_NOTICES.md"):
		push_error("Release PCK lacks THIRD_PARTY_NOTICES.md")
		quit(1)
		return
	print("Release PCK: notices present, forbidden paths absent" if not forbidden else "Release PCK rejected")
	quit(1 if forbidden else 0)
