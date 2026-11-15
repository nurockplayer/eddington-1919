extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var missing: Node = null
	missing.get_name()
	quit(0)
