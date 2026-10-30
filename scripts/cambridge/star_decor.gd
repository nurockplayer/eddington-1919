extends RefCounted
## Astronomy set dressing for the Cambridge study: a brass celestial globe and a
## small clockwork orrery on the bookcase, and a framed Taurus chart above the mantel. Decoration only: no
## hotspots, no colliders, no game state. Star textures are drawn at build time.

## Bright stars: right ascension (deg), declination (deg), visual magnitude.
const BRIGHT := [
	[101.29, -16.72, -1.5], [95.99, -52.70, -0.7], [213.92, 19.18, 0.0], [279.23, 38.78, 0.0],
	[79.17, 46.00, 0.1], [78.63, -8.20, 0.1], [114.83, 5.22, 0.3], [88.79, 7.41, 0.5],
	[24.43, -57.24, 0.5], [210.96, -60.37, 0.6], [297.70, 8.87, 0.8], [186.65, -63.10, 0.8],
	[201.30, -11.16, 1.0], [247.35, -26.43, 1.0], [116.33, 28.03, 1.1], [344.41, -29.62, 1.2],
	[191.93, -59.69, 1.3], [310.36, 45.28, 1.3], [152.09, 11.97, 1.4], [113.65, 31.89, 1.6],
	[81.28, 6.35, 1.6], [84.05, -1.20, 1.7], [85.19, -1.94, 1.8], [83.00, -0.30, 2.2],
	[37.95, 89.26, 2.0], [165.93, 61.75, 1.8], [193.51, 55.96, 1.8], [206.89, 49.31, 1.9],
	[200.98, 54.93, 2.2], [165.46, 56.38, 2.4], [178.46, 53.69, 2.4], [183.86, 57.03, 3.3],
]
## Taurus, for the chart: Aldebaran, theta2, gamma, delta1, epsilon, Elnath, zeta,
## then the Pleiades (Alcyone, Atlas, Electra, Merope, Maia, Taygeta).
const TAURUS := [
	[68.98, 16.51, 0.9], [67.17, 15.87, 3.4], [64.95, 15.63, 3.6], [65.73, 17.54, 3.8],
	[67.15, 19.18, 3.5], [81.57, 28.61, 1.7], [84.41, 21.14, 3.0],
	[56.87, 24.11, 2.9], [57.29, 24.05, 3.6], [56.22, 24.11, 3.7], [56.58, 23.95, 4.2],
	[56.46, 24.37, 3.9], [56.30, 24.47, 4.3],
]
## The Hyades V and the two horns, as index pairs into TAURUS.
const FIGURE := [[2, 1], [1, 0], [2, 3], [3, 4], [4, 5], [0, 6]]
## The Sun at greatest eclipse, 1919 May 29 (NASA GSFC ephemeris), north of the Hyades.
const SUN_1919 := Vector2(65.28, 21.50)
const INK := Color(0.20, 0.15, 0.10)
const GOLD := Color(0.86, 0.70, 0.38)
## Orrery arms: name, arm radius (m), period (years), ball radius (m), colour.
## Mercury to Mars; arm lengths are a toy's, periods are the real ratios.
const PLANETS := [
	["Mercury", 0.034, 0.241, 0.0045, Color(0.62, 0.58, 0.52)],
	["Venus", 0.050, 0.615, 0.0065, Color(0.86, 0.80, 0.62)],
	["Earth", 0.068, 1.0, 0.0070, Color(0.30, 0.45, 0.62)],
	["Mars", 0.088, 1.881, 0.0055, Color(0.66, 0.32, 0.20)],
]
const ORRERY_YEAR := 40.0  # seconds per Earth year, so the inner arms visibly creep
const MOON_MONTH := 1.0 / 12.37  # sidereal months per year


static func build(w, brass: Color, dark_wood: Color) -> Dictionary:
	return {"globe": _globe(w, brass, dark_wood), "chart": _chart(w, dark_wood), "orrery": _orrery(w, brass, dark_wood)}


## Turn every arm to time t (seconds); the Moon circles the Earth on its own arm.
static func turn_orrery(orrery: Node3D, t: float) -> void:
	var years := t / ORRERY_YEAR
	for arm in orrery.get_meta("arms"):
		arm.rotation.y = float(arm.get_meta("phase")) + TAU * years / float(arm.get_meta("period"))
	var moon_arm: Node3D = orrery.get_meta("moon_arm")
	moon_arm.rotation.y = TAU * years / MOON_MONTH


static func _orrery(w, brass: Color, dark_wood: Color) -> Node3D:
	# On the bookcase's top board (y 2.185), in the front bay between the top-row
	# books (they end at z -1.245) and the globe (its ring reaches -0.97), toward
	# the room so nothing stands between it and the study.
	var orrery := Node3D.new()
	orrery.name = "Orrery"
	orrery.position = Vector3(3.52, 2.185, -1.108)
	w.root.add_child(orrery)
	w.cyl(0.05, 0.02, Vector3(0, 0.01, 0), dark_wood, orrery)
	w.cyl(0.006, 0.08, Vector3(0, 0.06, 0), brass, orrery)
	var sun := _ball(0.016, Color(1.0, 0.78, 0.36), Vector3(0, 0.11, 0))
	var glow := sun.material_override as StandardMaterial3D
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.70, 0.30)
	glow.emission_energy_multiplier = 0.6
	sun.name = "Sun"
	orrery.add_child(sun)
	var arms: Array[Node3D] = []
	for i in PLANETS.size():
		var p: Array = PLANETS[i]
		var arm := Node3D.new()
		arm.name = p[0]
		arm.position = Vector3(0, 0.07 + i * 0.008, 0)
		arm.set_meta("phase", i * 1.7)  # not lined up at the start
		arm.set_meta("period", p[2])
		orrery.add_child(arm)
		w.box(Vector3(p[1], 0.002, 0.003), Vector3(p[1] * 0.5, 0, 0), brass, arm, false)
		w.cyl(0.0012, 0.11 - arm.position.y, Vector3(p[1], (0.11 - arm.position.y) * 0.5, 0), brass, arm)
		var planet := _ball(p[3], p[4], Vector3(p[1], 0.11 - arm.position.y, 0))
		planet.name = "Ball"
		arm.add_child(planet)
		arms.append(arm)
		if p[0] == "Earth":
			var moon_arm := Node3D.new()
			moon_arm.name = "MoonArm"
			moon_arm.position = planet.position
			arm.add_child(moon_arm)
			var moon := _ball(0.0025, Color(0.78, 0.77, 0.74), Vector3(0.014, 0, 0))
			moon.name = "Moon"
			moon_arm.add_child(moon)
			orrery.set_meta("moon_arm", moon_arm)
	orrery.set_meta("arms", arms)
	turn_orrery(orrery, 0.0)
	return orrery


static func _ball(radius: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	ball.mesh = sphere
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.4
	m.metallic = 0.3
	ball.material_override = m
	ball.position = pos
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ball


static func _globe(w, brass: Color, dark_wood: Color) -> Node3D:
	# On the bookcase's top board (y 2.15, half-thickness 0.035), in its empty front bay.
	var globe := Node3D.new()
	globe.name = "CelestialGlobe"
	globe.position = Vector3(3.62, 2.185, -0.82)
	w.root.add_child(globe)
	w.cyl(0.075, 0.03, Vector3(0, 0.015, 0), dark_wood, globe)
	w.cyl(0.012, 0.09, Vector3(0, 0.075, 0), brass, globe)
	# The axis leans to Cambridge's latitude (52 N): the pole sits 38 degrees off vertical.
	var tilt := Node3D.new()
	tilt.position = Vector3(0, 0.25, 0)
	tilt.rotation.x = deg_to_rad(38.0)
	globe.add_child(tilt)
	var ball := MeshInstance3D.new()
	ball.name = "Sky"
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.26
	ball.mesh = sphere
	var sky := StandardMaterial3D.new()
	sky.albedo_texture = ImageTexture.create_from_image(_globe_image())
	sky.roughness = 0.45
	sky.emission_enabled = true  # the gilt stars catch a little lamp light
	sky.emission_texture = sky.albedo_texture
	sky.emission_energy_multiplier = 0.12
	ball.material_override = sky
	tilt.add_child(ball)
	var meridian := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.142
	ring.outer_radius = 0.152
	meridian.mesh = ring
	meridian.material_override = w.mat(brass, 0.35, 0.8)
	meridian.rotation.z = PI * 0.5
	tilt.add_child(meridian)
	return globe


static func _globe_image() -> Image:
	# Equirectangular. SphereMesh U runs to the viewer's right, and seen from outside
	# a celestial globe shows RA increasing to the right (the sky mirrored).
	var img := Image.create(512, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.07, 0.10, 0.20))
	for i in 512:
		var ra := float(i) / 512.0 * 360.0
		var ecl := rad_to_deg(atan(tan(deg_to_rad(23.44)) * sin(deg_to_rad(ra))))
		_dot(img, _globe_uv(ra, ecl), 0.8, GOLD * Color(1, 1, 1, 0.55))
		_dot(img, _globe_uv(ra, 0.0), 0.6, GOLD * Color(1, 1, 1, 0.3))
	var r := RandomNumberGenerator.new()
	r.seed = 1919_0529
	for i in 500:
		var dec := rad_to_deg(asin(r.randf_range(-1.0, 1.0)))
		_dot(img, _globe_uv(r.randf() * 360.0, dec), 0.7, GOLD * Color(1, 1, 1, r.randf_range(0.3, 0.7)))
	for s in BRIGHT + TAURUS:
		_dot(img, _globe_uv(s[0], s[1]), lerpf(2.6, 1.0, clampf(s[2] / 4.0, 0.0, 1.0)), GOLD)
	_ring(img, _globe_uv(SUN_1919.x, SUN_1919.y), 3.5, Color(0.95, 0.55, 0.30))
	return img


static func _globe_uv(ra: float, dec: float) -> Vector2:
	return Vector2(ra / 360.0 * 512.0, (90.0 - dec) / 180.0 * 256.0)


static func _chart(w, dark_wood: Color) -> Node3D:
	# Above the mantel (top 1.565) on the east plaster (x 4.3275), facing the room.
	var chart := Node3D.new()
	chart.name = "TaurusChart"
	chart.position = Vector3(4.30, 2.20, 1.35)
	chart.rotation.y = -PI * 0.5
	w.root.add_child(chart)
	w.box(Vector3(0.78, 0.58, 0.02), Vector3(0, 0, -0.012), dark_wood, chart, false)
	var paper := MeshInstance3D.new()
	paper.name = "Paper"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.70, 0.50)
	paper.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(_chart_image())
	mat.roughness = 0.9
	paper.material_override = mat
	chart.add_child(paper)
	return chart


static func _chart_image() -> Image:
	# RA 90..48 deg left to right (east on the left, as on a sky chart), Dec 6..36.
	var img := Image.create(560, 400, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.84, 0.78, 0.64))
	var grid := INK * Color(1, 1, 1, 0.18)
	for ra in range(50, 91, 10):
		_line(img, _chart_xy(ra, 6), _chart_xy(ra, 36), grid, 0.5)
	for dec in range(10, 36, 10):
		_line(img, _chart_xy(48, dec), _chart_xy(90, dec), grid, 0.5)
	for pair in FIGURE:
		var a: Array = TAURUS[pair[0]]
		var b: Array = TAURUS[pair[1]]
		_line(img, _chart_xy(a[0], a[1]), _chart_xy(b[0], b[1]), INK * Color(1, 1, 1, 0.45), 0.8)
	for s in TAURUS:
		_dot(img, _chart_xy(s[0], s[1]), lerpf(9.0, 2.5, clampf(s[2] / 4.3, 0.0, 1.0)), INK)
	_ring(img, _chart_xy(SUN_1919.x, SUN_1919.y), 15.0, Color(0.55, 0.16, 0.08))
	return img


static func _chart_xy(ra: float, dec: float) -> Vector2:
	return Vector2((90.0 - ra) / 42.0 * 520.0 + 20.0, (36.0 - dec) / 30.0 * 360.0 + 20.0)


static func _dot(img: Image, c: Vector2, radius: float, col: Color) -> void:
	var r := int(ceil(radius + 1.0))
	for y in range(int(c.y) - r, int(c.y) + r + 1):
		for x in range(int(c.x) - r, int(c.x) + r + 1):
			var px := posmod(x, img.get_width())  # wraps around the globe seam
			if y < 0 or y >= img.get_height():
				continue
			var cover := clampf(radius + 0.5 - c.distance_to(Vector2(x, y)), 0.0, 1.0)
			if cover > 0.0:
				img.set_pixel(px, y, img.get_pixel(px, y).lerp(Color(col, 1.0), cover * col.a))


static func _ring(img: Image, c: Vector2, radius: float, col: Color) -> void:
	for i in 96:
		var a := TAU * float(i) / 96.0
		_dot(img, c + Vector2(cos(a), sin(a)) * radius, 0.9, col)


static func _line(img: Image, a: Vector2, b: Vector2, col: Color, width: float) -> void:
	var steps := int(a.distance_to(b))
	for i in steps + 1:
		_dot(img, a.lerp(b, float(i) / maxf(steps, 1)), width, col)
