extends RefCounted
class_name TotalityCues
## Pure shaping for the M5 totality legibility layer (docs/design/M5_TOTALITY.md).
## Hindsight bands and strip data only: nothing here looks at the upcoming sky.

const CLEAR_FRACTION := 0.65   # f >= this reads "clear"
const MIXED_FRACTION := 0.30   # f >= this reads "mixed", below reads "cloud"
const BRIEF_S := 1.0           # shorter than this reads "brief" regardless of f


## Hindsight band for one closed exposure: clear | mixed | cloud | brief.
static func sky_band(clear: float, duration: float) -> String:
	if duration < BRIEF_S:
		return "brief"
	var f := clear / duration
	if f >= CLEAR_FRACTION:
		return "clear"
	if f >= MIXED_FRACTION:
		return "mixed"
	return "cloud"


## Everything the exposure strip draws, clamped to [0, total].
static func strip_model(t: float, total: float, plates: Array, open_start: float, plates_total: int) -> Dictionary:
	var span := maxf(total, 0.001)
	var tt := clampf(t, 0.0, span)
	var segments: Array = []
	for p in plates:
		var start := clampf(float(p.get("start", 0.0)), 0.0, span)
		var end := clampf(float(p.get("start", 0.0)) + float(p.get("duration", 0.0)), 0.0, span)
		if end > start:
			segments.append([start, end])
	var open_segment: Array = []
	var os := -1.0
	if open_start >= 0.0:
		os = clampf(open_start, 0.0, span)
		if tt > os:
			open_segment = [os, tt]
	return {
		"t": tt,
		"total": span,
		"segments": segments,
		"open_start": os,
		"open_segment": open_segment,
		"plates_total": plates_total,
		"plates_used": plates.size() + (1 if open_start >= 0.0 else 0),
	}


## Third contact over the 3 s return of daylight (v 0..1): Baily's beads for the
## first ~0.5 s, then the diamond ring flares and fades by ~1.2 s.
static func third_contact_glint(v: float) -> Vector2:
	var beads := sin(v / 0.18 * PI) if v > 0.0 and v < 0.18 else 0.0
	var diamond := sin((v - 0.08) / 0.32 * PI) if v > 0.08 and v < 0.40 else 0.0
	return Vector2(beads, diamond)


## Read the same L8 field and moving pocket as eclipse_cloud.gdshaderinc
## for the director's receipts. Plate exposure still samples the simulation.
static func third_contact_cloud_sample(sim, ray: Vector3, time: float, clock: Vector3) -> Vector2:
	var uv: Vector2 = Vector2(ray.x, ray.z) / ray.y * sim.CLOUD_SCALE - sim.wind * time
	var pixel: Vector2 = uv * sim.TEX_SIZE - Vector2(0.5, 0.5)
	var cell := Vector2i(pixel.floor())
	var fraction := pixel - Vector2(cell)
	var x0 := posmod(cell.x, sim.TEX_SIZE)
	var y0 := posmod(cell.y, sim.TEX_SIZE)
	var x1 := (x0 + 1) % int(sim.TEX_SIZE)
	var y1 := (y0 + 1) % int(sim.TEX_SIZE)
	var image: Image = sim.cloud_img
	var lower := lerpf(image.get_pixel(x0, y0).r, image.get_pixel(x1, y0).r, fraction.x)
	var upper := lerpf(image.get_pixel(x0, y1).r, image.get_pixel(x1, y1).r, fraction.x)
	var tangent: Vector3 = sim.sun_dir.cross(Vector3.UP).normalized()
	var local_sun := Vector2(ray.dot(tangent), ray.dot(tangent.cross(sim.sun_dir))) / float(sim.SUN_R)
	var elapsed := (time - clock.x) / (clock.y if time < clock.x else clock.z)
	return Vector2(lerpf(lower, upper, fraction.y), third_contact_cloud_gap(local_sun, elapsed))


static func third_contact_cloud_gap(local_sun: Vector2, elapsed: float) -> float:
	var offset := local_sun - Vector2(1.25 * elapsed - 0.86, 0.0)
	var pocket := 1.0 - smoothstep(1.1, 3.65, (offset * Vector2(1.0, 1.25)).length())
	return pocket * (1.0 - smoothstep(3.5, 5.0, local_sun.length()))


static func third_contact_cloud_density(cloud: Vector2) -> float:
	return lerpf(cloud.x, minf(cloud.x, 0.22), cloud.y)

