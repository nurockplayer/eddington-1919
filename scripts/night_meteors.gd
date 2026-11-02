extends Node
## Now and then a shooting star on the night after the eclipse: a short streak
## drawn by the sky shader (meteor_head / meteor_tail / meteor_glow).
## Decoration only; no game state. Idle until night.

const GAP_MIN := 6.0  # seconds of quiet between meteors
const GAP_MAX := 14.0
const DURATION := 0.8
const LENGTH := 0.2  # radians of sky the head crosses (about 11 degrees)
const TRAIL := 0.4  # share of the path the tail lags behind the head
const MIN_ALT := 25.0  # degrees; low ones would sit in the horizon haze

var sky_mat: ShaderMaterial
var active := false
var wait := 3.0  # the first one comes soon after dark
var age := -1.0  # < 0: no meteor in flight
var start := Vector3.UP
var finish := Vector3.UP
var head := Vector3.UP
var tail := Vector3.UP
var glow := 0.0
var count := 0
var _rng := RandomNumberGenerator.new()


func setup(mat: ShaderMaterial) -> void:
	name = "NightMeteors"
	sky_mat = mat
	_rng.seed = 530  # 1919 May 30
	_push()


func set_night(on: bool) -> void:
	if on == active:
		return
	active = on
	age = -1.0
	wait = 3.0
	glow = 0.0
	_push()


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if not active:
		return
	if age < 0.0:
		wait -= delta
		if wait <= 0.0:
			_launch()
		return
	age += delta
	var p := age / DURATION
	if p >= 1.0:
		age = -1.0
		glow = 0.0
		wait = _rng.randf_range(GAP_MIN, GAP_MAX)
	else:
		head = start.slerp(finish, p)
		tail = start.slerp(finish, maxf(p - TRAIL, 0.0))
		glow = sin(PI * p)
	_push()


func _launch() -> void:
	var alt := deg_to_rad(_rng.randf_range(MIN_ALT + 15.0, 75.0))
	var az := _rng.randf() * TAU
	start = Vector3(-sin(az) * cos(alt), sin(alt), -cos(az) * cos(alt))
	# Travel mostly downward along the sky, tilted a random amount sideways.
	var down := (Vector3.DOWN - start * start.dot(Vector3.DOWN)).normalized()
	var side := start.cross(down).normalized()
	var tilt := _rng.randf_range(-1.1, 1.1)
	var way := (down * cos(tilt) + side * sin(tilt)).normalized()
	finish = (start * cos(LENGTH) + way * sin(LENGTH)).normalized()
	if finish.y < sin(deg_to_rad(MIN_ALT)):
		finish = (start * cos(LENGTH) - way * sin(LENGTH)).normalized()  # turn it back up the sky
	age = 0.0
	head = start
	tail = start
	glow = 0.0
	count += 1


func _push() -> void:
	if sky_mat == null:
		return
	sky_mat.set_shader_parameter("meteor_head", head)
	sky_mat.set_shader_parameter("meteor_tail", tail)
	sky_mat.set_shader_parameter("meteor_glow", glow)
