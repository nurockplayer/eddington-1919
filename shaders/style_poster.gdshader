shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;
// Style audition: poster (scripts/styles/poster.gd). A full-screen pass over a
// toon-lit frame. Geometry keeps its flat colours and steps back through a
// warm-then-cool haze. The sky is redrawn flat from the simulation's own cloud
// field (same maths as shaders/eclipse_sky.gdshader): bands of equal altitude,
// clouds cut in two tones, and at totality a corona in three flat tones.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D cloud_tex : repeat_enable, filter_linear;

uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);   // world, toward the Sun
uniform float sun_r = 0.02;                    // the Sun's angular radius in radians
uniform vec2 wind = vec2(0.0042, 0.0026);
uniform float cloud_scale = 0.35;
uniform float cloud_time = 0.0;
uniform float contact = 0.8;                   // 0 Moon far off the disc … 1 centred
uniform float darkness = 0.0;                  // 0 day … 1 totality
uniform float night = 0.0;
uniform float star_vis = 0.0;
uniform vec2 star_pos[12];                     // in solar radii about the Sun

// The inks. Set from scripts/styles/poster.gd (INKS).
uniform vec3 sky_top : source_color = vec3(0.24, 0.52, 0.66);
uniform vec3 sky_low : source_color = vec3(0.96, 0.87, 0.68);
uniform vec3 cloud_a : source_color = vec3(0.98, 0.94, 0.84);
uniform vec3 cloud_b : source_color = vec3(0.86, 0.82, 0.80);
uniform vec3 sun_ink : source_color = vec3(1.0, 0.96, 0.80);
uniform vec3 tot_top : source_color = vec3(0.055, 0.075, 0.20);
uniform vec3 tot_mid : source_color = vec3(0.16, 0.17, 0.38);
uniform vec3 tot_low : source_color = vec3(0.86, 0.47, 0.30);
uniform vec3 tot_cloud_a : source_color = vec3(0.13, 0.14, 0.30);
uniform vec3 tot_cloud_b : source_color = vec3(0.08, 0.09, 0.21);
uniform vec3 corona_a : source_color = vec3(1.0, 0.97, 0.88);
uniform vec3 corona_b : source_color = vec3(0.78, 0.82, 0.93);
uniform vec3 corona_c : source_color = vec3(0.36, 0.40, 0.68);
uniform vec3 moon_ink : source_color = vec3(0.03, 0.035, 0.09);
uniform vec3 prom_ink : source_color = vec3(0.89, 0.33, 0.25);
uniform vec3 haze_near : source_color = vec3(0.98, 0.80, 0.60);
uniform vec3 haze_far : source_color = vec3(0.62, 0.72, 0.82);
uniform vec3 tot_haze : source_color = vec3(0.10, 0.11, 0.26);

uniform float gain = 0.78;            // exposure of the lit geometry
uniform float sat = 1.15;             // saturation of the lit geometry
uniform float sky_bands = 5.0;        // flat bands from horizon to zenith
uniform float cloud_lo = 0.50;        // cloud density where the cloud shape starts
uniform float cloud_hi = 0.74;        // … and where its darker core starts
uniform float cloud_rough = 0.0;      // small-scale break-up of the cloud edge before it is cut
uniform float veil = 0.55;            // how far thin cloud lets the Sun or corona through
uniform float haze_k = 0.012;         // haze per metre
uniform float haze_max = 0.88;
uniform float haze_turn = 0.45;       // share of the haze where warm has turned cool
uniform float corona_fall = 3.2;
uniform float corona_base = 0.35;
uniform float streamer = 1.3;
uniform float streamer_reach = 0.25;
uniform float corona_1 = 0.30;        // the three cuts of the corona, inner to outer
uniform float corona_2 = 0.11;
uniform float corona_3 = 0.035;
uniform float star_px = 2.2;          // radius of a field star in pixels

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// An antialiased step: 0 below the edge, 1 above.
float cut(float edge, float x) {
	float w = max(fwidth(x) * 0.7, 0.0005);
	return smoothstep(edge - w, edge + w, x);
}

// x cut into whole steps with antialiased risers at the half steps.
float stairs(float x) {
	float w = max(fwidth(x) * 0.7, 0.0005);
	return floor(x) + smoothstep(0.5 - w, 0.5 + w, fract(x));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;
	float raw = texture(depth_tex, uv).r;
	vec4 p4 = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, max(raw, 0.00001), 1.0);
	vec3 pv = p4.xyz / p4.w;
	vec3 d = normalize((INV_VIEW_MATRIX * vec4(normalize(pv), 0.0)).xyz);
	float is_sky = raw < 0.00001 ? 1.0 : 0.0;

	// --- Sky, computed for every pixel (no derivative calls inside branches).
	float h = d.y;
	float e = clamp(h, 0.0, 1.0);
	float bq = stairs(pow(e, 0.6) * sky_bands) / sky_bands;
	float gq = stairs(exp(-e * 6.0) * 4.0) / 4.0;
	vec3 day = mix(sky_low, sky_top, clamp(bq, 0.0, 1.0));
	vec3 tot = mix(mix(tot_mid, tot_top, clamp(bq, 0.0, 1.0)), tot_low, clamp(gq, 0.0, 1.0));
	vec3 sky = mix(day, tot, darkness);

	vec2 plane = d.xz / max(h, 0.06);
	vec2 cloud_uv = plane * cloud_scale - wind * cloud_time;
	float dens = textureLod(cloud_tex, cloud_uv, 0.0).r;
	dens += (textureLod(cloud_tex, cloud_uv * 4.7 + vec2(0.31, 0.67), 0.0).r - 0.5) * cloud_rough;
	dens = mix(dens, 0.97, smoothstep(0.35, 0.05, h));
	dens = h > 0.0 ? dens : 1.0;
	float body = cut(cloud_lo, dens);
	float core = cut(cloud_hi, dens);
	vec3 cloud = mix(mix(cloud_a, cloud_b, core), mix(tot_cloud_a, tot_cloud_b, core), darkness);

	// Sun, Moon and corona, in solar radii about the Sun's centre.
	vec3 t1 = normalize(cross(sun_dir, vec3(0.0, 1.0, 0.0)));
	vec3 t2 = cross(t1, sun_dir);
	vec2 lp = vec2(dot(d, t1), dot(d, t2)) / sun_r;
	float r = length(lp);
	float front = step(0.0, dot(d, sun_dir));
	vec2 moon_c = vec2((1.0 - contact) * 2.1, 0.12 * (1.0 - contact));
	float in_sun = 1.0 - cut(1.0, r);
	float in_moon = 1.0 - cut(1.0, length(lp - moon_c));
	float a = atan(lp.y, lp.x);
	float lobes = 0.55 + 0.45 * sin(a * 3.0 + 1.3) * sin(a * 7.0 - 0.4);
	float rr = max(r, 1.0);
	float corona = pow(1.0 / rr, corona_fall) * (corona_base + streamer * lobes * exp(-(rr - 1.0) * streamer_reach));
	float k_c3 = cut(corona_3, corona);
	float k_c2 = cut(corona_2, corona);
	float k_c1 = cut(corona_1, corona);
	float spike = pow(max(sin(a * 5.0 + 2.0), 0.0), 8.0);
	float prom = (1.0 - cut(1.07, r)) * cut(0.75, spike);
	vec3 solar = sky;
	solar = mix(solar, corona_c, k_c3 * darkness);
	solar = mix(solar, corona_b, k_c2 * darkness);
	solar = mix(solar, corona_a, k_c1 * darkness);
	solar = mix(solar, prom_ink, prom * darkness);
	solar = mix(solar, sun_ink, in_sun * (1.0 - darkness));
	solar = mix(solar, mix(sky, moon_ink, darkness), in_moon);
	// Field stars: the same twelve the plates record.
	float px = 2.0 / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y);   // radians per pixel
	float stars = 0.0;
	for (int i = 0; i < 12; i++) {
		float sd = length(lp - star_pos[i]) * sun_r;
		stars = max(stars, 1.0 - smoothstep(0.6, 1.0, sd / (star_px * px)));
	}
	solar = mix(solar, corona_a, stars * star_vis);
	// Thin cloud lets the lit things through as a veil; a cloud's core hides them.
	float lit = max(max(k_c3 * darkness, in_sun * (1.0 - darkness)), stars * star_vis) * front;
	vec3 sky_col = mix(sky, solar, front);
	sky_col = mix(sky_col, cloud, body * (1.0 - veil * lit * (1.0 - core)));

	// --- Geometry: the toon-lit frame, stepped back through the haze.
	float z = max(-pv.z, 0.0);
	vec3 geo = c * gain;
	float lum = dot(geo, vec3(0.2126, 0.7152, 0.0722));
	geo = max(mix(vec3(lum), geo, sat), vec3(0.0));
	float t = 1.0 - exp(-z * haze_k);
	vec3 hz = mix(mix(haze_near, haze_far, smoothstep(0.0, haze_turn, t)), tot_haze, max(darkness, night));
	geo = mix(geo, hz, t * haze_max);

	// The night sky (the darkroom chapter) is left as rendered.
	vec3 sky_out = mix(sky_col, c, step(0.5, night));
	ALBEDO = mix(geo, sky_out, is_sky);
}
