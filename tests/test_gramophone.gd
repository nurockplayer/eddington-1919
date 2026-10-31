extends SceneTree
## Music round 2: the Cambridge gramophone prop, its hotspot and the director's
## play/stop/score-duck flow driven through the real examine path.
## Run: godot --headless --path . --script res://tests/test_gramophone.gd

const Room := preload("res://scripts/cambridge/room_builder.gd")
const StarDecor := preload("res://scripts/cambridge/star_decor.gd")
const C17 := preload("res://scripts/cambridge/content_1917.gd")
const ScorePlayer := preload("res://scripts/audio/score_player.gd")
const Score := preload("res://scripts/audio/score.gd")

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
	_check_text()
	_check_prop_and_room()
	await _check_director_flow()
	print("test_gramophone: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _check_text() -> void:
	var first := C17.examine("gramophone")
	check(first.size() == 3, "the first examine has three lines")
	check(str(first[0].t).contains("Victor") and str(first[0].t).contains("美國同行"), "it names the American record and how it came")
	check(str(first[1].t).contains("Keep the Home-Fires Burning"), "it names the song")
	check(str(first[2].t).contains("放下唱針"), "the last line lowers the needle")
	var again := C17.examine("gramophone_again")
	check(again.size() == 1 and str(again[0].t).contains("又放了一次"), "the second playing is one short line")
	var stop := C17.examine("gramophone_stop")
	check(stop.size() == 1 and str(stop[0].t).contains("抬起唱針"), "lifting the needle is one short line")


func _check_prop_and_room() -> void:
	var room := Node3D.new()
	root.add_child(room)
	var world := Room.build(room)
	var g: Node3D = world.get("gramophone")
	check(g != null and g.name == "Gramophone", "the gramophone prop is built")
	if g == null:
		room.free()
		return
	check(g.position.distance_to(Vector3(3.95, 0, -0.25)) < 0.001, "it stands at the east wall side table")
	var turntable := g.get_node_or_null("Turntable") as Node3D
	check(turntable != null, "it has a Turntable node")
	if turntable:
		var radii: Array[float] = []
		for child in turntable.get_children():
			var mi := child as MeshInstance3D
			if mi and mi.mesh is CylinderMesh:
				radii.append((mi.mesh as CylinderMesh).bottom_radius)
		check(_has_radius(radii, 0.15), "a green felt turntable of radius 0.15")
		check(_has_radius(radii, 0.125), "a disc of radius 0.125")
		check(_has_radius(radii, 0.04), "a label of radius 0.04")
		var before := turntable.rotation.y
		StarDecor.spin_gramophone(g, 0.2, false)
		check(is_equal_approx(turntable.rotation.y, before), "the turntable stands still when not playing")
		StarDecor.spin_gramophone(g, 0.2, true)
		var step1 := wrapf(turntable.rotation.y - before, -PI, PI)
		StarDecor.spin_gramophone(g, 0.2, true)
		var step2 := wrapf(turntable.rotation.y - before - step1, -PI, PI)
		check(absf(step1 - TAU * 78.0 / 60.0 * 0.2) < 0.001, "it turns at 78 rpm while playing (%.4f rad)" % step1)
		check(absf(step2 - step1) < 0.001, "every step is the same size")

	var spots := _hotspots(room)
	var hot: Node3D = null
	for body in spots:
		if str(body.get_meta("interact_id")) == "gramophone":
			hot = body
	check(hot != null, "the gramophone hotspot exists in the 1917 room")
	check(world.targets.has("gramophone"), "the room records the gramophone target")
	if hot:
		check(hot.position.distance_to(g.position + Vector3(0, 0.9, 0)) < 0.001, "the hotspot sits over the cabinet")
		for body in spots:
			if body == hot:
				continue
			check(not _hotspot_aabb(hot).intersects(_hotspot_aabb(body)),
				"the gramophone hotspot does not overlap %s" % body.get_meta("interact_id"))
	room.free()

	var away := Node3D.new()
	root.add_child(away)
	var night := Room.build(away, true)
	var found := false
	for body in _hotspots(away):
		if str(body.get_meta("interact_id")) == "gramophone":
			found = true
	check(not found, "no gramophone hotspot in the departure room")
	check(night.has("gramophone"), "the prop itself is still built in the departure room")
	away.free()


func _hotspots(node: Node) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for body in node.find_children("*", "StaticBody3D", true, false):
		if body.has_meta("interact_id"):
			found.append(body)
	return found


func _has_radius(radii: Array[float], wanted: float) -> bool:
	for r in radii:
		if absf(r - wanted) < 0.001:
			return true
	return false


## Every interactable is a StaticBody3D: a box for props, a capsule for figures.
func _hotspot_aabb(body: Node3D) -> AABB:
	for child in body.get_children():
		var shape := child as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		var local := AABB()
		if shape.shape is BoxShape3D:
			var size: Vector3 = (shape.shape as BoxShape3D).size
			local = AABB(-size * 0.5, size)
		elif shape.shape is CapsuleShape3D:
			var capsule := shape.shape as CapsuleShape3D
			local = AABB(Vector3(-capsule.radius, -capsule.height * 0.5, -capsule.radius),
				Vector3(capsule.radius * 2.0, capsule.height, capsule.radius * 2.0))
		else:
			continue
		return shape.global_transform * local
	return AABB(body.global_position, Vector3.ZERO)


func _finish_dialogue(chapter) -> void:
	var guard := 50
	while chapter.ui.dialog_active() and guard > 0:
		guard -= 1
		if not chapter.ui._choice_buttons.is_empty():
			chapter.ui._choose(0)
		else:
			chapter.ui._advance()
	check(guard > 0, "test dialogue terminates")


## The last "layer" entry for a cue after index `from`, so each step is read alone.
func _layer_since(cue: String, from: int) -> Dictionary:
	var found := {}
	for i in range(from, ScorePlayer.cue_log.size()):
		var entry: Dictionary = ScorePlayer.cue_log[i]
		if entry.event == "layer" and entry.cue == cue:
			found = entry
	return found


func _check_director_flow() -> void:
	var chapter = load("res://scripts/cambridge/director.gd").new()
	root.add_child(chapter)
	var deadline := Time.get_ticks_msec() + 15000
	while not chapter.ui.dialog_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter.ui.dialog_active(), "the Cambridge opening reaches dialogue")
	if not chapter.ui.dialog_active():
		chapter.free()
		return
	_finish_dialogue(chapter)
	check(chapter.beat == chapter.Beat.INVESTIGATE, "the opening hands over to investigation")

	# First examine: the last line starts the record and ducks the rain.
	var mark := ScorePlayer.cue_log.size()
	chapter._interact("gramophone")
	check(chapter._pending == "gramophone_play", "the first examine queues playback")
	check(not chapter.gramophone_playing and chapter.gramophone_plays == 0, "playback waits for the last line")
	_finish_dialogue(chapter)
	check(chapter.gramophone_playing, "the record plays after the last line")
	check(chapter.gramophone_plays == 1, "the first playing is counted")
	var duck := _layer_since("cambridge_rain", mark)
	check(duck.get("db", 0.0) <= ScorePlayer.SILENCE_DB and is_equal_approx(duck.get("fade", 0.0), 1.5),
		"cambridge_rain ducks to silence over 1.5 s")

	# Second examine while playing: the needle lifts and the score returns.
	mark = ScorePlayer.cue_log.size()
	chapter._interact("gramophone")
	check(chapter.ui.dialog_active(), "examining it while playing says a line")
	_finish_dialogue(chapter)
	check(not chapter.gramophone_playing, "examining it again stops the record")
	var back := _layer_since("cambridge_rain", mark)
	check(is_equal_approx(back.get("db", 0.0), Score.level_db("cambridge_rain")) and is_equal_approx(back.get("fade", 0.0), 3.0),
		"cambridge_rain returns over 3 s")

	# Third examine: the short line, and the record can play again.
	mark = ScorePlayer.cue_log.size()
	chapter._interact("gramophone")
	check(chapter.ui._seq.size() == 1 and str(chapter.ui._seq[0].t).contains("又放了一次"), "playing again uses the short line")
	_finish_dialogue(chapter)
	check(chapter.gramophone_playing and chapter.gramophone_plays == 2, "the record plays a second time")

	# The finished signal: state and score come back without a re-examine.
	mark = ScorePlayer.cue_log.size()
	chapter._gramophone_end(false)
	check(not chapter.gramophone_playing, "the finished path ends the playback state")
	var ended := _layer_since("cambridge_rain", mark)
	check(is_equal_approx(ended.get("db", 0.0), Score.level_db("cambridge_rain")) and is_equal_approx(ended.get("fade", 0.0), 3.0),
		"the finished path restores the score over 3 s")

	# Leaving Cambridge stops a playing record.
	mark = ScorePlayer.cue_log.size()
	chapter._interact("gramophone")
	_finish_dialogue(chapter)
	check(chapter.gramophone_playing, "the record is playing when the montage begins")
	chapter._montage()
	check(not chapter.gramophone_playing, "_montage stops the record")
