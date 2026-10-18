extends RefCounted
## Draws a developed plate (as a positive print, for readability) from what the
## exposure actually recorded: field stars above the plate's limit, scattered
## cloud light as fog, and trailing from coelostat drift. ILLUSTRATIVE images,
## not reproductions of the (lost) Príncipe plates.

const SIZE := 360
const SUN_PX := 34.0
const TRAIL_DIR := Vector2(0.83, 0.56)


static func render(sim, plate) -> ImageTexture:
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var buf := PackedFloat32Array()
	buf.resize(SIZE * SIZE)
	var r := RandomNumberGenerator.new()
	var comparison: bool = plate == null
	r.seed = hash([sim.run_seed, -1 if comparison else plate.index])
	var fog: float = 0.0 if comparison else plate.fog
	var stars: int = sim.STAR_COUNT if comparison else plate.stars
	var trail: float = 0.0 if comparison else plate.trail
	var blank: bool = not comparison and plate.duration < 0.5
	var c := Vector2(SIZE, SIZE) * 0.5
	# Cloud mottling + fog veil.
	var noise := FastNoiseLite.new()
	noise.seed = r.randi()
	noise.frequency = 0.012
	for y in SIZE:
		for x in SIZE:
			var v := 0.03 + fog * (0.38 + 0.22 * noise.get_noise_2d(x, y))
			v += r.randf() * 0.035  # emulsion grain
			buf[y * SIZE + x] = v
	if not comparison and not blank:
		# Eclipsed Sun: corona glow and the dark Moon.
		var corona := 0.9 * (1.0 - 0.5 * fog)
		if plate.sunlit:
			corona = 2.5
		for y in SIZE:
			for x in SIZE:
				var d := Vector2(x, y).distance_to(c) / SUN_PX
				var i := y * SIZE + x
				if d < 1.0:
					buf[i] = 0.02 + fog * 0.1
				else:
					buf[i] += corona * pow(1.0 / d, 2.6)
	if not blank:
		# Stars: brightest first, only those above the plate's limit.
		for s in stars:
			var p: Vector2 = c + sim.star_offsets[s] * SUN_PX
			var bright := 1.2 - s * 0.06
			var length := trail * 26.0
			var steps := maxi(1, int(length * 1.5))
			for k in steps:
				var off := TRAIL_DIR * (length * (float(k) / maxf(steps - 1, 1) - 0.5))
				_splat(buf, p + off, 1.6, bright / sqrt(steps) * (1.0 + 0.4 * minf(length, 3.0) / 3.0))
	for y in SIZE:
		for x in SIZE:
			var v := clampf(buf[y * SIZE + x], 0.0, 1.0)
			img.set_pixel(x, y, Color(v * 0.97, v * 0.95, v * 0.9))
	return ImageTexture.create_from_image(img)


static func _splat(buf: PackedFloat32Array, p: Vector2, radius: float, amount: float) -> void:
	var rr := int(ceil(radius * 3.0))
	for dy in range(-rr, rr + 1):
		for dx in range(-rr, rr + 1):
			var x := int(p.x) + dx
			var y := int(p.y) + dy
			if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
				continue
			var d2 := Vector2(x - p.x, y - p.y).length_squared()
			buf[y * SIZE + x] += amount * exp(-d2 / (2.0 * radius * radius))
