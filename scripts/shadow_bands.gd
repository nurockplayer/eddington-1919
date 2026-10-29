extends MeshInstance3D
## Shadow bands: in the last moments before totality (and just after it) the
## thin crescent of sunlight, scintillating through the air, throws faint
## rippling light-and-dark bands across the ground. Decoration only.

const SHADER := preload("res://shaders/shadow_bands.gdshader")
const SIZE := 26.0  # metres of ground around the station
const FULL_AT := 0.025  # crescent fraction where the bands are strongest
const START_AT := 0.08  # crescent fraction where they begin
## Above the trampled earth (top 0.02 m) and the puddles (top 0.035 m).
const LIFT := 0.04


func setup(centre: Vector3, sun_dir: Vector3) -> void:
	name = "ShadowBands"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE, SIZE)
	mesh = plane
	position = Vector3(centre.x, LIFT, centre.z)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	# Bands lie across the Sun's azimuth and drift along it.
	var across := Vector2(sun_dir.x, sun_dir.z).normalized()
	mat.set_shader_parameter("band_dir", across)
	material_override = mat
	set_strength(0.0)


## How strong the bands are for this much uneclipsed Sun (0..1, the sky's
## crescent fraction) and this much direct light through cloud (0..1).
static func strength(crescent: float, through_cloud: float) -> float:
	if crescent <= 0.004:
		return 0.0  # totality: no crescent, no bands
	return (1.0 - smoothstep(FULL_AT, START_AT, crescent)) * through_cloud


func set_strength(s: float) -> void:
	(material_override as ShaderMaterial).set_shader_parameter("strength", s)
	visible = s > 0.002
