extends Node
## Script errors abort test coroutines before quit(); guard script runs against idle hangs.

class ScriptErrorLogger extends Logger:
	var report: Callable

	func _log_error(_function: String, file: String, line: int, code: String,
			rationale: String, _editor_notify: bool, error_type: int,
			_script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == Logger.ERROR_TYPE_SCRIPT:
			report.call_deferred(file, line, rationale if not rationale.is_empty() else code)


var _logger: ScriptErrorLogger
var _script_failed := false
var _script_path := ""
var _deadline_seconds := 900.0
var _deadline_msec := 0


func _ready() -> void:
	set_process(false)
	var main_script = Engine.get_main_loop().get_script()
	if main_script == null:
		return
	_script_path = main_script.resource_path
	if OS.get_environment("EDD_FAILFAST") != "0":
		_logger = ScriptErrorLogger.new()
		_logger.report = _on_script_error
		OS.add_logger(_logger)
	if OS.has_environment("EDD_TEST_DEADLINE"):
		_deadline_seconds = OS.get_environment("EDD_TEST_DEADLINE").to_float()
	elif not (_script_path.begins_with("res://tests/test_") and _script_path.ends_with(".gd")):
		return
	_deadline_msec = Time.get_ticks_msec() + int(_deadline_seconds * 1000.0)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func _on_script_error(file: String, line: int, message: String) -> void:
	if _script_failed:
		return
	_script_failed = true
	print("FAIL: script error at %s:%d: %s" % [file, line, message])
	get_tree().quit(70)


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() >= _deadline_msec:
		set_process(false)
		print("FAIL: deadline %s s exceeded (%s)" % [_deadline_seconds, _script_path])
		get_tree().quit(124)


func _exit_tree() -> void:
	if _logger != null:
		OS.remove_logger(_logger)
	# A helper's error can return to a caller that subsequently calls quit(0).
	if _script_failed:
		get_tree().quit(70)
