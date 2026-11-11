extends "res://tests/benchmark.gd"
## Cambridge G4 run: --benchmark=<out> --bench-cambridge [--bench-quality=low]

const TARGETS := ["lightbox", "fire", "orrery", "cabinet", "clock"]

var director


static func bookmarks(world: Dictionary) -> Array:
	var result := []
	for key in TARGETS:
		if key == "orrery" and not world.targets.has(key):
			continue
		result.append([key, world.spawn, world.targets[key], "night"])
	return result


func _run() -> void:
	var hidden := _hide_groups()
	director.ui.visible = false
	director.player.can_move = false
	director.player.can_look = false
	var results := []
	var shots := _shots(bookmarks(director.world))
	if shots.is_empty():
		return
	for b in shots:
		director.player.global_position = b[1]
		director.player.velocity = Vector3.ZERO
		await _frames(2)
		director.player.look_at_point(b[2])
		var r := await _sample_bookmark(b[0], b[3])
		results.append(r)
		print("[BENCH] ", JSON.stringify(r))
	# Room.build uses a fixed 1917 seed; this chapter has no eclipse simulation.
	_write_summary(results, 1917, hidden, "cambridge")
