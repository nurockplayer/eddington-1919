extends SceneTree

const Room := preload("res://scripts/cambridge/room_builder.gd")
const Benchmark := preload("res://tests/benchmark_cambridge.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	var room := Node3D.new()
	root.add_child(room)
	var world := Room.build(room)
	var names := []
	for b in Benchmark.bookmarks(world):
		names.append(b[0])
		check(world.targets.has(b[0]), "existing target: " + b[0])
		check(b[1] == world.spawn, "bookmark starts at spawn: " + b[0])
		check(b[2] == world.targets[b[0]], "bookmark looks at target: " + b[0])
	check(names == ["lightbox", "fire", "orrery", "cabinet", "clock"], "Cambridge bookmark order")
	world.targets.erase("orrery")
	names.clear()
	for b in Benchmark.bookmarks(world):
		names.append(b[0])
	check(names == ["lightbox", "fire", "cabinet", "clock"], "orrery is optional")
	room.free()
	print("test_benchmark_cambridge: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
