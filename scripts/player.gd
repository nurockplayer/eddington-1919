extends CharacterBody3D
## First-person player: walk, look, and aim at interactables.

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


func _ready() -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and can_look:
		# The headless display server cannot capture the mouse, so Input.mouse_mode
		# stays VISIBLE there; synthetic motion from the headless E2E bots is still
		# real input and must turn the view.
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless":
			return
		yaw -= event.relative.x * MOUSE_SENS
		pitch = clampf(pitch - event.relative.y * MOUSE_SENS, -1.45, 1.45)


func look_at_point(target: Vector3) -> void:
	var to := target - camera.global_position
	yaw = atan2(-to.x, -to.z)
	pitch = clampf(atan2(to.y, Vector2(to.x, to.z).length()), -1.45, 1.45)


func _physics_process(delta: float) -> void:
	# Keyboard look (arrow keys) as an alternative to the mouse.
	if can_look:
		yaw -= Input.get_axis("look_left", "look_right") * 1.9 * delta
		pitch = clampf(pitch + Input.get_axis("look_down", "look_up") * 1.5 * delta, -1.45, 1.45)
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
		_bob += delta * speed * 2.2
		camera.position.y = 1.62 + sin(_bob) * 0.035
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
