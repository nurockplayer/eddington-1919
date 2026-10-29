extends Node
## The sea breeze in the palm crowns: every frond nods a few degrees on slow,
## overlapping waves. The crowns themselves stay put, so the pinhole crescents
## under them (sun_crescents.gd) keep their places.

const NOD := 2.5     # degrees, frond pitch
const TWIST := 1.5   # degrees, frond yaw

var fronds: Array[Node3D] = []
var _rest: Array[Vector3] = []
var _phase: Array[float] = []
var _t := 0.0


func add(frond: Node3D, palm: int, leaf: int) -> void:
	fronds.append(frond)
	_rest.append(frond.rotation)
	# Deterministic, so the world's shared RNG sequence is left untouched.
	_phase.append(palm * 1.7 + leaf * 0.9)


func _process(delta: float) -> void:
	_t += delta
	sway(_t)


func sway(t: float) -> void:
	for i in fronds.size():
		var p := _phase[i]
		var gust := sin(t * 0.9 + p) + 0.4 * sin(t * 2.3 + p * 1.3)
		fronds[i].rotation = _rest[i] + Vector3(deg_to_rad(NOD) * gust / 1.4, deg_to_rad(TWIST) * sin(t * 0.6 + p), 0.0)
