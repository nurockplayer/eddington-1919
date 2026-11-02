extends SceneTree
## Run through orb-test: godot --headless --path . --script res://tools/render_icon.gd


func _initialize() -> void:
	var image := Image.new()
	var error := image.load_svg_from_string(FileAccess.get_file_as_string("res://icon.svg"), 1.0)
	if error == OK:
		error = DirAccess.make_dir_recursive_absolute("res://assets/icon")
	if error == OK:
		error = image.save_png("res://assets/icon/icon_1024.png")
	if error != OK:
		push_error("Icon render failed: %s" % error_string(error))
		quit(1)
		return
	print("Rendered assets/icon/icon_1024.png (%d × %d)" % [image.get_width(), image.get_height()])
	quit()
