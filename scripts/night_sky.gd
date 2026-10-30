extends RefCounted
## The real sky over Roça Sundy, Príncipe (1.66 N, 7.38 E) on the night after
## the eclipse, 1919 May 30 about 21:00 local (20:30 UT): the Southern Cross and
## the Centaurs low in the south, Scorpius rising in the south-east with the
## Milky Way's core, the Plough low in the north. Altitude/azimuth (degrees,
## azimuth from north through east) from J2000 positions and GMST; precession
## since 1919 (about 1 degree) is ignored. Decoration only.

## [name, altitude, azimuth, visual magnitude]
const STARS := [
	["Rigil Kentaurus", 26.0, 170.5, -0.3], ["Hadar", 27.6, 175.1, 0.6],
	["Acrux", 24.2, 187.6, 0.8], ["Mimosa", 28.1, 185.8, 1.3], ["Gacrux", 30.1, 189.0, 1.6], ["Imai", 27.9, 190.7, 2.8],
	["Antares", 38.2, 126.1, 1.0], ["Shaula", 21.5, 131.3, 1.6], ["Sargas", 18.8, 136.9, 1.9],
	["Dschubba", 45.8, 125.6, 2.3], ["Acrab", 46.0, 121.2, 2.6], ["Kaus Australis", 12.3, 125.8, 1.8], ["Nunki", 6.7, 116.7, 2.0],
	["Arcturus", 69.0, 32.5, 0.0], ["Spica", 77.2, 183.9, 1.0], ["Vega", 11.1, 50.7, 0.0],
	["Regulus", 39.3, 284.1, 1.4], ["Denebola", 62.2, 299.0, 2.1], ["Alphard", 29.1, 259.1, 2.0], ["Rasalhague", 28.1, 76.6, 2.1],
	["Dubhe", 24.0, 342.2, 1.8], ["Merak", 27.9, 338.0, 2.4], ["Phecda", 34.4, 343.2, 2.4], ["Megrez", 32.7, 348.3, 3.3],
	["Alioth", 35.3, 354.1, 1.8], ["Mizar", 36.7, 359.1, 2.2], ["Alkaid", 42.2, 4.1, 1.9],
]
const GALACTIC_POLE := Vector2(63.0, 341.5)  # altitude, azimuth
const GALACTIC_CENTRE := Vector2(21.5, 122.1)


## Same convention as the eclipse sim's sun_dir: north is -Z, east is -X.
static func direction(alt: float, az: float) -> Vector3:
	var a := deg_to_rad(alt)
	var z := deg_to_rad(az)
	return Vector3(-sin(z) * cos(a), sin(a), -cos(z) * cos(a))


## vec4 per star: direction and a brightness that halves about every 0.75 mag.
static func uniforms() -> PackedVector4Array:
	var out := PackedVector4Array()
	for s in STARS:
		var dir := direction(s[1], s[2])
		out.append(Vector4(dir.x, dir.y, dir.z, clampf(pow(10.0, -0.4 * (s[3] - 1.0)), 0.15, 3.0)))
	return out


static func apply(sky_mat: ShaderMaterial) -> void:
	sky_mat.set_shader_parameter("night_stars", uniforms())
	sky_mat.set_shader_parameter("gal_pole", direction(GALACTIC_POLE.x, GALACTIC_POLE.y))
	sky_mat.set_shader_parameter("gal_centre", direction(GALACTIC_CENTRE.x, GALACTIC_CENTRE.y))
