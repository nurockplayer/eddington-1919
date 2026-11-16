extends SceneTree
## Exercise the guard in real child processes, including errors that return to quit(0).

const CHILD_CAP_S := 30.0

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _shell_quote(value: String) -> String:
	return "'" + value.replace("'", "'\"'\"'") + "'"


func _fixture(filename: String) -> Dictionary:
	var log_path := ProjectSettings.globalize_path("user://guard_%s.log" % filename)
	var cmd := "exec %s --headless --path %s --script %s >%s 2>&1" % [
		_shell_quote(OS.get_executable_path()),
		_shell_quote(ProjectSettings.globalize_path("res://")),
		_shell_quote("res://tests/fixtures/%s.gd" % filename), _shell_quote(log_path)]
	var started := Time.get_ticks_msec()
	var pid := OS.create_process("/bin/sh", ["-c", cmd])
	while pid > 0 and OS.is_process_running(pid) and Time.get_ticks_msec() - started < CHILD_CAP_S * 1000.0:
		OS.delay_msec(100)
	var capped := pid > 0 and OS.is_process_running(pid)
	if capped:
		OS.kill(pid)
	var code := OS.get_process_exit_code(pid) if pid > 0 and not capped else -1
	var output := ""
	if FileAccess.file_exists(log_path):
		output = FileAccess.get_file_as_string(log_path)
		DirAccess.remove_absolute(log_path)
	return {"code": code, "output": output,
		"seconds": (Time.get_ticks_msec() - started) / 1000.0, "capped": capped}


func _run() -> void:
	var had_failfast := OS.has_environment("EDD_FAILFAST")
	var saved_failfast := OS.get_environment("EDD_FAILFAST")
	var had_deadline := OS.has_environment("EDD_TEST_DEADLINE")
	var saved_deadline := OS.get_environment("EDD_TEST_DEADLINE")
	OS.unset_environment("EDD_FAILFAST")
	# Also bounds a broken fail-fast implementation while testing the fixtures.
	OS.set_environment("EDD_TEST_DEADLINE", "3")
	for filename in ["guard_script_error", "guard_helper_error"]:
		var result := _fixture(filename)
		check(not result.capped, "%s finished before the %d s outer cap" % [filename, CHILD_CAP_S])
		check(result.code == 70, "%s exits 70: %s" % [filename, result])
		check("FAIL: script error" in result.output, filename + " reports its script error")
		check(result.seconds < 20.0, filename + " exits within 20 s")
		if filename == "guard_helper_error":
			check("helper returned; calling quit(0)" in result.output, "helper caller reaches quit(0)")
	var idle := _fixture("guard_idle")
	check(not idle.capped, "guard_idle finished before the %d s outer cap" % CHILD_CAP_S)
	check(idle.code == 124, "idle fixture exits 124: %s" % idle)
	check("FAIL: deadline 3 s exceeded (res://tests/fixtures/guard_idle.gd)" in idle.output,
		"idle fixture reports deadline and script: %s" % idle.output)
	check(idle.seconds >= 3.0 and idle.seconds < 20.0, "idle deadline takes 3 to 20 s")
	var messages := _fixture("guard_messages")
	check(not messages.capped, "guard_messages finished before the %d s outer cap" % CHILD_CAP_S)
	check(messages.code == 0, "push_error and push_warning exit 0: %s" % messages)
	check(not "FAIL: script error" in messages.output, "ordinary messages do not trigger fail-fast")
	OS.set_environment("EDD_FAILFAST", "0")
	var opted_out := _fixture("guard_script_error")
	check(not opted_out.capped, "guard_script_error finished before the %d s outer cap" % CHILD_CAP_S)
	check(opted_out.code == 124, "fail-fast opt-out still exits 124: %s" % opted_out)
	check("FAIL: deadline 3 s exceeded" in opted_out.output, "opt-out retains deadline: %s" % opted_out.output)
	check(not "FAIL: script error" in opted_out.output, "opt-out disables script error report")
	if had_failfast:
		OS.set_environment("EDD_FAILFAST", saved_failfast)
	else:
		OS.unset_environment("EDD_FAILFAST")
	if had_deadline:
		OS.set_environment("EDD_TEST_DEADLINE", saved_deadline)
	else:
		OS.unset_environment("EDD_TEST_DEADLINE")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
