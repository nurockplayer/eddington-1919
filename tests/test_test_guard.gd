extends SceneTree
## Exercise the guard in real child processes, including errors that return to quit(0).

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _fixture(filename: String) -> Dictionary:
	var output: Array = []
	var started := Time.get_ticks_msec()
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--script",
		"res://tests/fixtures/" + filename + ".gd"], output, true)
	return {"code": code, "output": "\n".join(output),
		"seconds": (Time.get_ticks_msec() - started) / 1000.0}


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
		check(result.code == 70, "%s exits 70: %s" % [filename, result])
		check("FAIL: script error" in result.output, filename + " reports its script error")
		check(result.seconds < 20.0, filename + " exits within 20 s")
		if filename == "guard_helper_error":
			check("helper returned; calling quit(0)" in result.output, "helper caller reaches quit(0)")
	var idle := _fixture("guard_idle")
	check(idle.code == 124, "idle fixture exits 124: %s" % idle)
	check("FAIL: deadline 3 s exceeded (res://tests/fixtures/guard_idle.gd)" in idle.output,
		"idle fixture reports deadline and script: %s" % idle.output)
	check(idle.seconds >= 3.0 and idle.seconds < 20.0, "idle deadline takes 3 to 20 s")
	var messages := _fixture("guard_messages")
	check(messages.code == 0, "push_error and push_warning exit 0: %s" % messages)
	check(not "FAIL: script error" in messages.output, "ordinary messages do not trigger fail-fast")
	OS.set_environment("EDD_FAILFAST", "0")
	var opted_out := _fixture("guard_script_error")
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
