shader_type sky;
// Overcast tropical sky with a drifting cloud field, the partially / totally
// eclipsed Sun, corona and the field stars. The cloud texture and its motion are
// the same data the simulation samples, so what the player sees over the Sun is
// what the plate receives.

uniform sampler2D cloud_tex : repeat_enable, filter_linear;
uniform float cloud_time = 0.0;
uniform vec2 wind = vec2(0.0042, 0.0026);
uniform float cloud_scale = 0.35;
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);
uniform float sun_r = 0.02;
uniform float contact = 0.8;      // 0 moon far off the disc … 1 centred (totality)
uniform float darkness = 0.0;     // 0 daylight … 1 totality
uniform float star_vis = 0.0;
uniform float night = 0.0;        // 1 = the night after, for the darkroom scene
uniform float cloud_shade = 0.22;  // daytime darkening of thick cloud (art look; 0.22 = v0.1)
uniform float day_gain = 1.0;      // daytime sky brightness (art look; fades out with darkness)
uniform vec2 star_pos[12];
uniform float star_mag[12];
// The night after: the real Príncipe sky (scripts/night_sky.gd) and the Milky Way.
uniform vec4 night_stars[27];
uniform vec3 gal_pole = vec3(0.0, 1.0, 0.0);
uniform vec3 gal_centre = vec3(1.0, 0.0, 0.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = d.y;

	// Base gradient: humid grey-blue day → deep twilight blue during totality.
	vec3 day = mix(vec3(0.70, 0.74, 0.78), vec3(0.42, 0.55, 0.70), clamp(h, 0.0, 1.0));
	vec3 tot = mix(vec3(0.07, 0.08, 0.15), vec3(0.012, 0.016, 0.045), clamp(h, 0.0, 1.0));
	// A restrained extra step toward the deep twilight described by observers.
	tot *= 0.88;
	// Art gains apply only to the plain daytime sky: they fade out completely by
	// darkness 0.15, long before the near-totality and totality reads (r05 review).
	float art_k = 1.0 - smoothstep(0.0, 0.15, darkness);
	float gain = mix(1.0, day_gain, art_k);
	vec3 col = mix(day * gain, tot, darkness);
	// 360° "sunset" glow on the horizon during totality.
	col += darkness * vec3(0.55, 0.30, 0.12) * exp(-max(h, 0.0) * 9.0);
	vec3 nightc = mix(vec3(0.03, 0.04, 0.07), vec3(0.005, 0.008, 0.02), clamp(h, 0.0, 1.0));
	col = mix(col, nightc, night);
	if (h < 0.0) {
		col = mix(col, col * 0.35, clamp(-h * 4.0, 0.0, 1.0));
	}

	// Clouds are sampled once from the same drifting field used by the plate
	// simulation. This optical visibility gates all eclipse/night stars and the
	// corona together, so a clear gap opens the whole view at once.
	float dens = 0.0;
	if (h > 0.0) {
		vec2 plane = d.xz / max(h, 0.06);
		vec2 uv = plane * cloud_scale - wind * cloud_time;
		dens = texture(cloud_tex, uv).r;
		dens = mix(dens, 0.97, smoothstep(0.35, 0.05, h));   // haze toward horizon
	} else {
		dens = 1.0;
	}
	dens = mix(dens, dens * 0.55, night);
	float cloud_visibility = 1.0 - smoothstep(0.35, 0.80, dens);
	float background_stars = 0.0;
	if (h > 0.0) {
		// One randomly placed, soft circular point per rare grid cell. The
		// Gaussian falloff avoids the square-cell look of the old step stars.
		vec2 star_grid = d.xz / (h + 0.4) * 220.0;
		vec2 star_cell = floor(star_grid);
		float chance = hash(star_cell);
		vec2 random_offset = vec2(hash(star_cell + vec2(19.1, 3.7)), hash(star_cell + vec2(7.3, 41.9)));
		vec2 offset = mix(vec2(0.25), vec2(0.75), random_offset);
		vec2 delta = fract(star_grid) - offset;
		float soft_star = exp(-dot(delta, delta) * 90.0);
		background_stars = step(0.9965, chance) * (chance - 0.9965) * 280.0 * soft_star;
	}

	// Local frame around the Sun.
	vec3 t1 = normalize(cross(sun_dir, vec3(0.0, 1.0, 0.0)));
	vec3 t2 = cross(t1, sun_dir);
	float cosang = dot(d, sun_dir);
	vec2 lp = vec2(dot(d, t1), dot(d, t2)) / sun_r;   // in solar radii
	float r = length(lp);
	vec3 solar = vec3(0.0);
	if (cosang > 0.0 && night < 0.5) {
		vec2 moon_c = vec2((1.0 - contact) * 2.1, 0.12 * (1.0 - contact));
		float in_sun = 1.0 - smoothstep(0.96, 1.0, r);
		float in_moon = 1.0 - smoothstep(1.0, 1.04, length(lp - moon_c));
		float photosphere = in_sun * (1.0 - in_moon);
		solar += photosphere * vec3(6.0, 5.6, 4.8) * (1.0 - darkness * 0.98);
		// Daylight glare around the Sun.
		solar += (1.0 - darkness) * vec3(1.0, 0.95, 0.85) * 0.8 * exp(-max(r - 1.0, 0.0) * 0.45);
		// Corona with streamers.
		float a = atan(lp.y, lp.x);
		float streamers = 0.55 + 0.45 * sin(a * 3.0 + 1.3) * sin(a * 7.0 - 0.4);
		float corona = (r > 1.0) ? pow(1.0 / r, 3.2) * (0.6 + 0.8 * streamers * exp(-(r - 1.0) * 0.6)) : 0.0;
		solar += darkness * cloud_visibility * corona * vec3(1.6, 1.65, 1.8);
		// Faint prominences at the limb.
		float prom = smoothstep(1.06, 1.0, r) * step(1.0, r) * pow(max(sin(a * 5.0 + 2.0), 0.0), 8.0);
		solar += darkness * cloud_visibility * prom * vec3(2.5, 0.6, 0.7);
		// The moon disc stays black against the corona.
		solar *= mix(1.0, 1.0 - in_moon, darkness);
		col *= mix(1.0, 1.0 - in_moon * 0.9, darkness);
		// Field stars, only visible near totality.
		for (int i = 0; i < 12; i++) {
			float sd = length(lp - star_pos[i]) * sun_r;
			solar += star_vis * cloud_visibility * star_mag[i] * vec3(1.4, 1.45, 1.6) * exp(-sd * sd / 0.0000045);
		}
	}
	// Keep background stars on the same cloud-compositing path as corona and
	// field stars, so all eclipse detail has the same final transmittance.
	solar += max(star_vis * 0.5, night) * cloud_visibility * background_stars * vec3(0.8, 0.85, 1.0);
	if (night > 0.0 && h > 0.0) {
		float named = 0.0;
		for (int i = 0; i < 27; i++) {
			float ang2 = 2.0 * (1.0 - dot(d, night_stars[i].xyz));
			named += night_stars[i].w * exp(-ang2 / 0.0000035);
		}
		// Milky Way: a soft band about the galactic equator, brightest toward the
		// core in Sagittarius, mottled by the cloud field, with a darker rift.
		float b = dot(d, gal_pole);
		float core = pow(max(dot(d, gal_centre), 0.0), 6.0);
		float mottle = texture(cloud_tex, d.xz / (h + 0.4) * 1.7 + vec2(0.37, 0.11)).r;
		float band = exp(-b * b / 0.012) * (0.35 + 1.2 * core) * mix(0.55, 1.1, mottle);
		band *= 1.0 - 0.6 * exp(-b * b / 0.0006) * core;
		solar += night * cloud_visibility * (named * vec3(1.3, 1.35, 1.5) + band * vec3(0.10, 0.105, 0.12));
	}

	// Clouds: the same sampled density shades the sky and hides luminous detail.
	float shade = mix(0.22, cloud_shade, 1.0 - smoothstep(0.0, 0.15, darkness));
	vec3 cloud_day = vec3(0.80, 0.82, 0.84) - dens * vec3(shade, shade, shade - 0.02);  // 0.22 → exactly v0.1
	vec3 cloud_tot = (vec3(0.11, 0.115, 0.15) + vec3(0.14, 0.11, 0.08) * exp(-max(h, 0.0) * 5.0)) * 0.92;
	vec3 cloud_col = mix(cloud_day * gain, cloud_tot, darkness);
	cloud_col = mix(cloud_col, vec3(0.02, 0.025, 0.04), night);
	// Light scattering through thin cloud near the Sun (silver lining / lit veil).
	float near_sun = exp(-max(r - 1.0, 0.0) * 0.25) * step(0.0, cosang);
	cloud_col += near_sun * (1.0 - night) * mix(vec3(1.2, 1.1, 0.9) * (1.0 - dens), vec3(0.35, 0.36, 0.42) * (1.0 - dens * 0.6), darkness);
	float alpha = clamp(dens * 1.08, 0.0, 1.0);
	col = mix(col + solar, cloud_col + solar * (1.0 - alpha) * 0.15, alpha);
	if (AT_CUBEMAP_PASS) {
		col = min(col, vec3(1.5));
	}
	COLOR = col;
}
