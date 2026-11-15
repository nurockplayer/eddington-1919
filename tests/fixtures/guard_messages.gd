extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	push_error("test guard ordinary error")
	push_warning("test guard warning")
	quit(0)
