extends RefCounted
## Shared observation/decision state for one run of the slice.
##
## Owns the cloud field that drifts across the Sun, the exposures the player
## times, and what each developed plate records. It holds no nodes, so it can be
## tested headless and is the natural unit to share if co-op is ever added
## (presentation and input stay local; this state is what players would share).
##
## ALL numbers here are an illustrative game model, not the 1919 measurements.

const TOTALITY_S := 302.0        # HISTORICAL_RECORD: ~302 s of totality at Príncipe
const TIME_SCALE := 2.5          # game compresses totality ×2.5 (~2 real minutes)
const TEX_SIZE := 256
const CLOUD_SCALE := 0.35        # sky-plane → cloud texture scale (shared with sky shader)
const SUN_R := 0.03              # visual solar radius in radians (exaggerated ~6× for readability)
const STAR_COUNT := 12
const EINSTEIN := 1.75           # arcsec at the limb, full deflection
const HALF := 0.87               # arcsec, the "Newtonian" half value
const PLATE_CHANGE_S := 4.0      # game-seconds to change a plate holder
const BASE_PLATES := 4           # holders Eddington already loaded himself
const MAX_EXTRA_PLATES := 8      # holders the player can fetch from the darkroom
const FOG_FULL_S := 25.0         # cloud-seconds of scattered light that fully fogs a plate

var run_seed: int
var wind := Vector2(0.0042, 0.0026)   # cloud texture uv per game-second
var sun_dir: Vector3
var sun_uv: Vector2
var gaps: Array = []                  # [{t, d, depth}] scheduled thinning over the Sun
var star_offsets := PackedVector2Array()   # in solar radii, local to the Sun
var cloud_img: Image
var _dens := PackedFloat32Array()

# --- preparation state ------------------------------------------------------
var briefed := false
var read_plan := false
var plates_carried := 0
var plates_delivered := 0
var drive_wound := false
var drive_rate_checked := false

# --- totality state ---------------------------------------------------------
var plates: Array = []        # developed plate dictionaries, in exposure order
var _open: Dictionary = {}    # exposure in progress

# --- analysis/judgment state ------------------------------------------------
var measured := false
var reselected_after_seeing := false
var measured_selection = null    # plate numbers included at the last measurement


func _init(p_seed: int = 1919) -> void:
	run_seed = p_seed
	var alt := deg_to_rad(56.0)
	var az := deg_to_rad(38.0)
	sun_dir = Vector3(-sin(az) * cos(alt), sin(alt), -cos(az) * cos(alt)).normalized()
	sun_uv = Vector2(sun_dir.x, sun_dir.z) / sun_dir.y * CLOUD_SCALE
	_make_stars()
	_make_gaps()
	_make_clouds()


# ---------------------------------------------------------------------------
# Field stars (stylised Hyades-like group around the eclipsed Sun)

func _make_stars() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1919_0529  # same star field every run, like a real star field
	star_offsets.clear()
	for i in STAR_COUNT:
		var a := r.randf() * TAU
		var d := r.randf_range(1.7, 4.3)
		star_offsets.append(Vector2(cos(a), sin(a)) * d)


## Effective clear seconds needed to record star `i` (0 = brightest).
static func star_threshold(i: int) -> float:
	return 1.6 * pow(1.25, i)


# ---------------------------------------------------------------------------
# Cloud field

func _make_gaps() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = run_seed
	gaps.clear()
	# RECONSTRUCTION: cloud persisted through totality and thinned somewhat late.
	# One early, brief, partial thinning; one or two mid; one better window late.
	var plan := [
		[r.randf_range(22.0, 60.0), r.randf_range(6.0, 9.0), r.randf_range(0.50, 0.62)],
		[r.randf_range(95.0, 140.0), r.randf_range(7.0, 11.0), r.randf_range(0.32, 0.48)],
		[r.randf_range(205.0, 245.0), r.randf_range(11.0, 16.0), r.randf_range(0.04, 0.14)],
	]
	if r.randf() < 0.6:
		plan.append([r.randf_range(262.0, 282.0), r.randf_range(5.0, 8.0), r.randf_range(0.15, 0.30)])
	for g in plan:
		gaps.append({"t": g[0], "d": g[1], "depth": g[2]})


func _make_clouds() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = run_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.011
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	var base := noise.get_seamless_image(TEX_SIZE, TEX_SIZE, false, false, 0.1, true)
	_dens.resize(TEX_SIZE * TEX_SIZE)
	for y in TEX_SIZE:
		for x in TEX_SIZE:
			var n := base.get_pixel(x, y).r
			_dens[y * TEX_SIZE + x] = 0.12 + 0.86 * smoothstep(0.28, 0.6, n)
	# A thick bank along the Sun's track for the whole of totality…
	var t := -30.0
	while t < TOTALITY_S + 30.0:
		_carve(sun_track(t), sun_track(t + 10.0), 0.05, 0.05, 0.93, true)
		t += 10.0
	# …with the scheduled thin patches cut into it.
	for g in gaps:
		_carve(sun_track(g.t), sun_track(g.t + g.d), 0.006, 0.03, g.depth, false)
	cloud_img = Image.create_empty(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_L8)
	var bytes := PackedByteArray()
	bytes.resize(TEX_SIZE * TEX_SIZE)
	for i in _dens.size():
		bytes[i] = int(clampf(_dens[i], 0.0, 1.0) * 255.0)
	cloud_img.set_data(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_L8, bytes)


## Where in cloud-texture space the Sun's line of sight is at game-time `t`
## (unwrapped; the sky shader draws uv = plane * CLOUD_SCALE - wind * t).
func sun_track(t: float) -> Vector2:
	return sun_uv - wind * t


func _carve(a: Vector2, b: Vector2, r_full: float, r_soft: float, target: float, thicken: bool) -> void:
	var reach := r_full + r_soft
	var x0 := int(floor((minf(a.x, b.x) - reach) * TEX_SIZE))
	var x1 := int(ceil((maxf(a.x, b.x) + reach) * TEX_SIZE))
	var y0 := int(floor((minf(a.y, b.y) - reach) * TEX_SIZE))
	var y1 := int(ceil((maxf(a.y, b.y) + reach) * TEX_SIZE))
	var ab := b - a
	var len2 := maxf(ab.length_squared(), 1e-9)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var p := Vector2((x + 0.5) / TEX_SIZE, (y + 0.5) / TEX_SIZE)
			var h := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
			var dist := (p - (a + ab * h)).length()
			if dist > reach:
				continue
			var w := 1.0 - smoothstep(r_full, reach, dist)
			var i := posmod(y, TEX_SIZE) * TEX_SIZE + posmod(x, TEX_SIZE)
			var cur := _dens[i]
			_dens[i] = lerpf(cur, maxf(cur, target) if thicken else minf(cur, target), w)


func _sample(uv: Vector2) -> float:
	var fx := uv.x * TEX_SIZE - 0.5
	var fy := uv.y * TEX_SIZE - 0.5
	var x0 := int(floor(fx))
	var y0 := int(floor(fy))
	var tx := fx - x0
	var ty := fy - y0
	var a := _dens[posmod(y0, TEX_SIZE) * TEX_SIZE + posmod(x0, TEX_SIZE)]
	var b := _dens[posmod(y0, TEX_SIZE) * TEX_SIZE + posmod(x0 + 1, TEX_SIZE)]
	var c := _dens[posmod(y0 + 1, TEX_SIZE) * TEX_SIZE + posmod(x0, TEX_SIZE)]
	var d := _dens[posmod(y0 + 1, TEX_SIZE) * TEX_SIZE + posmod(x0 + 1, TEX_SIZE)]
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)


## Cloud density over the Sun's disc at game-time `t` (0 clear … 1 opaque).
func cloud_over_sun(t: float) -> float:
	var c := sun_track(t)
	var k := 0.01
	return (_sample(c) * 2.0 + _sample(c + Vector2(k, 0)) + _sample(c - Vector2(k, 0))
		+ _sample(c + Vector2(0, k)) + _sample(c - Vector2(0, k))) / 6.0


# ---------------------------------------------------------------------------
# Preparation consequences

func plates_available() -> int:
	return BASE_PLATES + mini(plates_delivered, MAX_EXTRA_PLATES)


## Image drift of the coelostat drive (trail units per exposure second).
## FICTION: after the morning's rain the drive needs re-winding and its rate
## checked against the chronometer; Cottingham manages alone if not helped.
func drift_rate() -> float:
	if drive_rate_checked:
		return 0.012
	if drive_wound:
		return 0.05
	return 0.075


# ---------------------------------------------------------------------------
# Exposures

func is_exposing() -> bool:
	return not _open.is_empty()


func open_shutter(t: float) -> void:
	_open = {"start": t, "duration": 0.0, "clear": 0.0, "cloudy": 0.0, "sunlit": false}


func accumulate(dt: float, density: float) -> void:
	if _open.is_empty():
		return
	_open.duration += dt
	_open.clear += (1.0 - density) * dt
	_open.cloudy += density * dt


func close_shutter(sunlit := false) -> Dictionary:
	if _open.is_empty():
		return {}
	_open.sunlit = sunlit
	var p := develop(_open, plates.size())
	plates.append(p)
	_open = {}
	return p


## Turns a raw exposure record into what the developed plate shows.
func develop(raw: Dictionary, index: int) -> Dictionary:
	var p := raw.duplicate()
	p.index = index
	p.number = index + 1
	var fog := clampf(p.cloudy / FOG_FULL_S, 0.0, 1.0)
	if p.sunlit:
		fog = 1.0
	var eff: float = p.clear * (1.0 - 0.6 * fog)
	var stars := 0
	if not p.sunlit:
		for i in STAR_COUNT:
			if eff >= star_threshold(i):
				stars += 1
	var trail: float = drift_rate() * p.duration
	p.fog = fog
	p.stars = stars
	p.trail = trail
	p.usable = stars >= 5
	if not p.usable:
		p.quality = "unusable"
	elif trail < 0.35 and fog < 0.6:
		p.quality = "good"
	else:
		p.quality = "poor"
	# Illustrative measurement model. Truth is the full deflection; visible trailing
	# smears images and (in this simplified model) biases the fit low; fog and few
	# stars widen the error.
	var r := RandomNumberGenerator.new()
	r.seed = hash([run_seed, index])
	var z := clampf(r.randfn(), -1.3, 1.3)
	var sigma := 0.25 * sqrt(5.0 / maxf(stars, 1)) * (1.0 + 0.9 * fog) * (1.0 + 2.0 * trail)
	p.sigma = sigma
	p.value = EINSTEIN - 0.9 * clampf(trail - 0.2, 0.0, 1.0) + sigma * z
	p.included = false
	return p


# ---------------------------------------------------------------------------
# Analysis

func included_usable() -> Array:
	return plates.filter(func(p): return p.included and p.usable)


func combined() -> Dictionary:
	var sel := included_usable()
	if sel.is_empty():
		return {"n": 0}
	var wsum := 0.0
	var vsum := 0.0
	for p in sel:
		var w: float = 1.0 / (p.sigma * p.sigma)
		wsum += w
		vsum += w * p.value
	return {"n": sel.size(), "value": vsum / wsum, "sigma": 1.0 / sqrt(wsum)}


## What the measured plates actually support: none / favors_e / favors_half / ambiguous.
func evidence_class() -> String:
	var c := combined()
	if c.n == 0:
		return "none"
	var de: float = absf(c.value - EINSTEIN) / c.sigma
	var dh: float = absf(c.value - HALF) / c.sigma
	if de <= 2.0 and dh > 2.0:
		return "favors_e"
	if dh <= 2.0 and de > 2.0:
		return "favors_half"
	return "ambiguous"


func count_quality(q: String) -> int:
	return plates.filter(func(p): return p.quality == q).size()


func selection_report() -> Dictionary:
	var omitted_good := plates.filter(func(p): return p.quality == "good" and not p.included)
	var included_poor := plates.filter(func(p): return p.quality == "poor" and p.included)
	var included_unusable := plates.filter(func(p): return p.quality == "unusable" and p.included)
	return {
		"omitted_good": omitted_good.map(func(p): return p.number),
		"included_poor": included_poor.map(func(p): return p.number),
		"included_unusable": included_unusable.map(func(p): return p.number),
		"reselected": reselected_after_seeing,
	}
