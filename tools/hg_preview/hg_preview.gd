extends Node3D
## Human Generator prototype viewer (evaluation only, docs/HG_PROTOTYPE.md).
##
## glTF puts the character's front on +Z. Loads the HG GLB at runtime from OUTSIDE the repo (HG licence: no redistribution,
## and this repo is public), lights it like the Cambridge study, and performs:
## breathing idle, blinks, small gaze saccades, mood cycling via FACS blend shapes.
##
##   godot --path . res://tools/hg_preview/hg_preview.tscn -- --glb=<file> [--light=studio|study] [--shots=<dir>]
## --light=studio (default): neutral grey look-dev light, no grade, to judge materials.
## --light=study: the Cambridge-like lamp/window light with the game's grade.
## With --shots it saves close-up/medium PNGs per mood (godot_<light>_<mood>.png) and quits.

const LOOK := preload("res://scripts/look.gd")
const HG_FIGURE := preload("res://tools/hg_preview/hg_figure.gd")

const MOODS := {
	"neutral": {"mouthPress_L": 0.15, "mouthPress_R": 0.15, "browInnerUp": 0.1},
	"intent": {"browInnerUp": 0.35, "browDown_L": 0.35, "browDown_R": 0.35, "eyeSquint_L": 0.45,
		"eyeSquint_R": 0.45, "mouthPress_L": 0.45, "mouthPress_R": 0.45},
	"warm": {"mouthSmile_L": 0.8, "mouthSmile_R": 0.7, "cheekSquint_L": 0.55, "cheekSquint_R": 0.5,
		"eyeSquint_L": 0.45, "eyeSquint_R": 0.4, "browInnerUp": 0.15, "mouthDimple_L": 0.3},
	"doubt": {"browInnerUp": 0.85, "browDown_L": 0.45, "browOuterUp_R": 0.3, "mouthFrown_L": 0.45,
		"mouthFrown_R": 0.3, "mouthPress_L": 0.4, "mouthRollLower": 0.25, "mouth_L": 0.2,
		"eyeLookDownLeft": 0.3, "eyeLookDownRight": 0.3},
}
const MOOD_ORDER := ["neutral", "intent", "warm", "doubt"]

var body: MeshInstance3D
var skel: Skeleton3D
var cam: Camera3D
var head_pos := Vector3.ZERO
var mood_w := {}          # blend shape name -> current weight
var mood_target := {}
var t := 0.0
var next_blink := 2.0
var blink_t := -1.0
var gaze := Vector2.ZERO
var gaze_target := Vector2.ZERO
var next_saccade := 1.0
var mood_i := 0
var next_mood := 4.0
var shots_dir := ""
var light := "studio"


func _ready() -> void:
	var glb := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--glb="):
			glb = a.substr(6)
		elif a.begins_with("--shots="):
			shots_dir = a.substr(8)
		elif a.begins_with("--light="):
			light = a.substr(8)
	if glb == "" or not FileAccess.file_exists(glb):
		push_error("hg_preview: pass --glb=<path to eddington_hg.glb>")
		get_tree().quit(2)
		return
	var root := HG_FIGURE.load_figure(glb)
	if root == null:
		get_tree().quit(3)
		return
	add_child(root)
	_find(root)
	var ap := root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation("idle"):
		ap.play("idle")
		ap.seek(0.0, true)
		ap.pause()
	if OS.has_environment("HG_DEBUG"):
		_debug(root)
	head_pos = (skel.global_transform * skel.get_bone_global_pose(skel.find_bone("head"))).origin
	_stage()
	_set_mood("neutral")
	if shots_dir != "":
		_shots.call_deferred()


func _find(n: Node) -> void:
	if n is MeshInstance3D and n.name.begins_with("HG_Body"):
		body = n
	if n is Skeleton3D:
		skel = n
	for c in n.get_children():
		_find(c)


func _stage() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.045, 0.035, 0.028)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.30, 0.30)
	env.ambient_light_energy = 0.55
	if light == "studio":
		env.background_color = Color(0.18, 0.18, 0.18)
		env.ambient_light_color = Color(0.5, 0.5, 0.5)
		env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.ssao_enabled = true
	env.ssao_radius = 0.25
	env.ssao_intensity = 1.2
	env.glow_enabled = true
	env.glow_intensity = 0.25
	if light == "study":
		LOOK.apply_grade(env)
	we.environment = env
	add_child(we)
	if light == "studio":
		_studio_lights()
	else:
		_study_lights()
	cam = Camera3D.new()
	add_child(cam)
	_close_up()


## Neutral look-dev: white soft key 45° camera-left and above, weak fill, no rim.
func _studio_lights() -> void:
	var key := SpotLight3D.new()
	key.light_energy = 1.1
	key.spot_range = 5.0
	key.spot_angle = 40.0
	key.shadow_enabled = true
	key.light_size = 0.6
	add_child(key)
	key.global_position = head_pos + Vector3(-0.9, 0.55, 0.9)
	key.look_at(head_pos)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.3
	add_child(fill)
	fill.look_at_from_position(head_pos + Vector3(1.0, 0.1, 0.8), head_pos)


func _study_lights() -> void:
	# warm desk-lamp key, low camera-left (character's right); cool window fill; warm rim
	var key := SpotLight3D.new()
	key.light_color = Color(1.0, 0.8, 0.6)
	key.light_energy = 1.1
	key.spot_range = 4.0
	key.spot_angle = 35.0
	key.shadow_enabled = true
	key.light_size = 0.35
	add_child(key)
	key.global_position = head_pos + Vector3(-0.75, -0.2, 0.55)
	key.look_at(head_pos)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.74, 0.79, 0.92)
	fill.light_energy = 0.6
	add_child(fill)
	fill.look_at_from_position(head_pos + Vector3(1.0, 0.3, 0.6), head_pos)
	var rim := OmniLight3D.new()
	rim.light_color = Color(1.0, 0.82, 0.6)
	rim.light_energy = 2.5
	rim.omni_range = 1.6
	add_child(rim)
	rim.global_position = head_pos + Vector3(0.45, 0.35, -0.65)


func _close_up() -> void:
	cam.fov = 22.0
	cam.look_at_from_position(head_pos + Vector3(-0.32, 0.07, 1.25), head_pos + Vector3(0, 0.03, 0))


func _medium() -> void:
	cam.fov = 40.0
	cam.look_at_from_position(head_pos + Vector3(-0.7, -0.15, 2.4), head_pos + Vector3(0, -0.35, 0))


func _set_shape(n: String, v: float) -> void:
	if body == null:
		return
	var i := body.find_blend_shape_by_name(n)
	if i >= 0:
		body.set_blend_shape_value(i, v)


func _set_mood(m: String) -> void:
	mood_target.clear()
	for k in mood_w.keys():
		mood_target[k] = 0.0
	for k in MOODS[m]:
		mood_target[k] = MOODS[m][k]
		if not mood_w.has(k):
			mood_w[k] = 0.0


func _process(delta: float) -> void:
	if body == null:
		return
	t += delta
	# moods ease in over ~0.4 s
	for k in mood_target:
		mood_w[k] = lerpf(mood_w[k], mood_target[k], 1.0 - exp(-delta * 7.0))
		_set_shape(k, mood_w[k])
	if shots_dir == "":
		next_mood -= delta
		if next_mood <= 0.0:
			mood_i = (mood_i + 1) % MOOD_ORDER.size()
			_set_mood(MOOD_ORDER[mood_i])
			next_mood = 4.0
		# blink: 0.16 s close/open every 2.5–5 s
		next_blink -= delta
		if next_blink <= 0.0:
			blink_t = 0.0
			next_blink = randf_range(2.5, 5.0)
		var b := 0.0
		if blink_t >= 0.0:
			blink_t += delta
			b = sin(clampf(blink_t / 0.16, 0.0, 1.0) * PI)
			if blink_t > 0.16:
				blink_t = -1.0
		_set_shape("eyeBlink_L", b)
		_set_shape("eyeBlink_R", b)
		# gaze: small saccades around the camera
		next_saccade -= delta
		if next_saccade <= 0.0:
			gaze_target = Vector2(randf_range(-0.12, 0.12), randf_range(-0.06, 0.05))
			next_saccade = randf_range(0.6, 2.2)
	gaze = gaze.lerp(gaze_target, 1.0 - exp(-delta * 25.0))
	_eyes()
	# breathing: tiny chest/shoulder lift
	var sp := skel.find_bone("spine.002")
	if sp >= 0:
		skel.set_bone_pose_rotation(sp, skel.get_bone_rest(sp).basis.get_rotation_quaternion()
			* Quaternion(Vector3.RIGHT, sin(t * TAU / 4.2) * 0.012))


func _eyes() -> void:
	if OS.has_environment("HG_NOGAZE"):
		return
	# aim both eyeballs at a point near the camera, offset by the saccade
	var target := cam.global_position + cam.global_basis * Vector3(gaze.x, gaze.y, 0) * 1.2
	for side in ["eyeball.L", "eyeball.R"]:
		var i := skel.find_bone(side)
		if i < 0:
			continue
		var parent := skel.get_bone_parent(i)
		var pg := skel.global_transform * skel.get_bone_global_pose(parent)
		var rest := skel.get_bone_rest(i)
		var g := pg * rest
		var fwd := (g.basis * Vector3.UP).normalized()  # bone axis = Y, points out of the eye
		var want := (target - g.origin).normalized()
		var q := Quaternion(fwd, want)
		var local := (pg.basis.inverse() * Basis(q) * g.basis).get_rotation_quaternion()
		skel.set_bone_pose_rotation(i, local)


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(shots_dir)
	for m in MOOD_ORDER:
		_set_mood(m)
		for i in 40:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shots_dir.path_join("godot_%s_%s.png" % [light, m]))
	_set_mood("neutral")
	_medium()
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots_dir.path_join("godot_%s_medium.png" % light))
	get_tree().quit()


func _debug(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var shapes := []
		for i in mi.mesh.get_blend_shape_count():
			var v: float = mi.get_blend_shape_value(i)
			if absf(v) > 0.001:
				shapes.append("%s=%.2f" % [mi.mesh.get_blend_shape_name(i), v])
		print("MESH ", mi.name, " aabb=", mi.global_transform * mi.get_aabb(), " skin=", mi.skin != null, " shapes=", shapes)
	for c in n.get_children():
		_debug(c)
