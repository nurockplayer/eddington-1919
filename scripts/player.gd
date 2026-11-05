extends CharacterBody3D
## First-person player: walk, look, and aim at interactables.

const Settings := preload("res://scripts/settings.gd")
const WALK := 3.4
const RUN := 5.8
const MOUSE_SENS := 0.0022
const REACH := 3.2

var camera: Camera3D
var can_move := true
var can_look := true
var yaw := 0.0
var pitch := 0.0
var _bob := 0.0
var step_surface := "wood"
var steps_taken := 0
var _steps := {}
var _step_player: AudioStreamPlayer
var _step_rng := RandomNumberGenerator.new()


func _ready() -> void:
	preload("res://scripts/settings.gd").ensure_sfx_bus()
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.75
	shape.shape = cap
	shape.position.y = 0.875
	add_child(shape)
	camera = Camera3D.new()
	camera.position.y = 1.62
	camera.fov = 72.0
	camera.near = 0.05
	add_child(camera)
	camera.make_current()
	_step_rng.seed = 1919
	for surface in ["wood", "earth"]:
		_steps[surface] = []
		for variant in 3:
			_steps[surface].append(_synth_step(surface))
	_step_player = AudioStreamPlayer.new()
	_step_player.bus = "SFX"
	_step_player.volume_db = -24.0
	add_child(_step_player)


func _synth_step(surface: String) -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.14 if surface == "wood" else 0.18
	var samples := PackedFloat32Array()
	samples.resize(int(duration * rate))
	var pitch := 97.5 * _step_rng.randf_range(0.92, 1.08)
	var level := db_to_linear(_step_rng.randf_range(-2.0, 2.0))
	var grain := _step_rng.randf_range(0.08, 0.16)
	var noise := 0.0
	for i in samples.size():
		var t := float(i) / rate
		var white := _step_rng.randf_range(-1.0, 1.0)
		var sample: float
		if surface == "wood":
			# Low knock with a brighter, band-limited tap at the attack.
			noise += 0.55 * (white - noise)
			sample = level * (0.5 * sin(TAU * pitch * t) * exp(-30.0 * t)
				+ 0.22 * noise * exp(-120.0 * t))
		else:
			noise += grain * (white - noise)
			var envelope := 0.5 - 0.5 * cos(TAU * i / (samples.size() - 1))
			sample = 0.7 * noise * envelope + 0.1 * sin(TAU * 70.0 * t) * exp(-35.0 * t)
		samples[i] = clampf(sample, -0.8, 0.8)
	return _wav(samples, rate)


static func _wav(samples: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(samples[i] * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav


func _exit_tree() -> void:
	_step_player.stop()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and can_look:
		# The headless display server cannot capture the mouse, so Input.mouse_mode
		# stays VISIBLE there; synthetic motion from the headless E2E bots is still
		# real input and must turn the view.
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless":
			return
		yaw -= event.relative.x * MOUSE_SENS * Settings.look_speed
		var dy: float = event.relative.y * (-1.0 if Settings.invert_y else 1.0)
		pitch = clampf(pitch - dy * MOUSE_SENS * Settings.look_speed, -1.45, 1.45)


func look_at_point(target: Vector3) -> void:
	var to := target - camera.global_position
	yaw = atan2(-to.x, -to.z)
	pitch = clampf(atan2(to.y, Vector2(to.x, to.z).length()), -1.45, 1.45)


func _physics_process(delta: float) -> void:
	# Keyboard look (arrow keys) as an alternative to the mouse.
	if can_look:
		yaw -= Input.get_axis("look_left", "look_right") * 1.9 * delta * Settings.look_speed
		pitch = clampf(pitch + Input.get_axis("look_down", "look_up") * 1.5 * delta * Settings.look_speed * (-1.0 if Settings.invert_y else 1.0), -1.45, 1.45)
	rotation.y = yaw
	camera.rotation.x = pitch
	var input := Vector2.ZERO
	if can_move:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var speed := RUN if Input.is_action_pressed("run") else WALK
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	if input.length() > 0.1 and is_on_floor():
		var previous_step := floori(_bob / PI)
		_bob += delta * speed * 2.2
		camera.position.y = 1.62 + (0.0 if Settings.reduced_motion else sin(_bob) * 0.035)
		if floori(_bob / PI) > previous_step:
			_step_player.stream = _steps[step_surface][_step_rng.randi_range(0, 2)]
			_step_player.play()
			steps_taken += 1
	else:
		camera.position.y = lerpf(camera.position.y, 1.62, delta * 8.0)


## The interactable node under the crosshair, or null.
func aimed_interactable() -> Node:
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * REACH
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return null
	var n: Node = hit.collider
	while n and not n.has_meta("interact_id"):
		n = n.get_parent()
	return n
