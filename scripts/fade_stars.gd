extends Control
## While the screen fades to black, a faint star field shows through: the V of
## the Hyades in Taurus, the field the 1919 eclipse plates measured, plus a few
## Pleiades and seeded background stars. Decoration only; no game state.

## Named stars: right ascension (deg), declination (deg), visual magnitude.
const NAMED := [
	[68.98, 16.51, 0.9],  # Aldebaran
	[67.17, 15.87, 3.4],  # theta2 Tau
	[64.95, 15.63, 3.6],  # gamma Tau
	[65.73, 17.54, 3.8],  # delta1 Tau
	[67.15, 19.18, 3.5],  # epsilon Tau
	[56.87, 24.11, 2.9],  # Alcyone (Pleiades)
	[57.29, 24.05, 3.6],  # Atlas
	[56.22, 24.11, 3.7],  # Electra
	[56.58, 23.95, 4.2],  # Merope
	[81.57, 28.61, 1.7],  # Elnath (beta Tau)
	[84.41, 21.14, 3.0],  # zeta Tau
]
const BACKGROUND := 70
const CENTRE := Vector2(68.0, 20.0)  # field centre (RA, Dec), degrees
const SPAN := 24.0  # degrees across the screen height

var target: ColorRect  # the UI fade rect whose alpha we follow
var _stars: Array = []  # [Vector2 unit position, radius, brightness, phase, speed, colour]
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modulate.a = 0.0
	for s in NAMED:
		# Sky east is to the left: larger RA draws further left.
		var p := Vector2(CENTRE.x - s[0], CENTRE.y - s[1]) / SPAN
		var mag: float = s[2]
		var colour := Color(1.0, 0.78, 0.55) if mag < 1.0 else Color(0.86, 0.9, 1.0)
		_add(p, lerpf(3.6, 1.7, mag / 4.2), lerpf(1.0, 0.7, mag / 4.2), colour)
	var r := RandomNumberGenerator.new()
	r.seed = 1919_0529  # the same sky every run
	for i in BACKGROUND:
		var p := Vector2(r.randf_range(-0.95, 0.95), r.randf_range(-0.5, 0.5))
		_add(p, r.randf_range(0.8, 1.4), r.randf_range(0.25, 0.55), Color(0.8, 0.84, 0.95), r)


func _add(p: Vector2, radius: float, brightness: float, colour: Color, r: RandomNumberGenerator = null) -> void:
	var phase := r.randf() * TAU if r else float(_stars.size()) * 1.7
	var speed := r.randf_range(0.6, 1.6) if r else 0.9 + 0.13 * _stars.size()
	_stars.append([p, radius, brightness, phase, speed, colour])


func _process(delta: float) -> void:
	var a := target.color.a if is_instance_valid(target) else 0.0
	# Stars only appear once the screen is nearly dark, and never over gameplay.
	modulate.a = smoothstep(0.6, 1.0, a) * 0.85
	if modulate.a <= 0.0:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	var h := size.y
	var c := size * 0.5
	for s in _stars:
		var twinkle := 0.72 + 0.28 * sin(_t * s[4] + s[3])
		var col: Color = s[5]
		col.a = s[2] * twinkle
		var pos: Vector2 = c + s[0] * h
		draw_circle(pos, s[1] * h / 720.0 * 1.4, col)
		if s[1] > 3.0:  # a soft halo on the brightest star
			col.a *= 0.22
			draw_circle(pos, s[1] * h / 720.0 * 4.0, col)
