extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_helper()
	print("helper returned; calling quit(0)")
	quit(0)


func _helper() -> void:
	var missing: Node = null
	missing.get_name()
