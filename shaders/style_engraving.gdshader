shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;
// Daylight surfaces print their own marks. This pass finishes them with paper
// grain and selective contours, and retains the night and totality plates.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, repeat_disable, filter_nearest;

uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);   // world, toward the Sun
uniform float sun_r = 0.02;                    // the Sun's angular radius in radians
uniform float darkness = 0.0;                  // 0 day … 1 totality
uniform float night = 0.0;
uniform float diamond_radius = 0.45; // core radius in solar radii
uniform float diamond_spikes = 4.0; // longest spike in solar radii
uniform float diamond_rays = 1.0; // corona lines reach the limb at peak
uniform float diamond_ray_floor = 0.70;
uniform float diamond = 0.0;
uniform float contact = 1.0;
// The sky's live cloud field, including the rehearsal override.
uniform sampler2D cloud_tex : repeat_enable, filter_linear;
uniform float cloud_time = 0.0;
uniform float third_contact_gap = 0.0;
uniform float practice_cloud = -1.0;
uniform vec2 wind = vec2(0.0042, 0.0026);
uniform float cloud_scale = 0.35;
// Reserve the existing field-star points in bright paper, in output pixels.
uniform vec2 star_pos[12];
uniform float star_keyline_px = 1.0;
uniform float star_keyline_all = 1.0;

#include "res://shaders/eclipse_cloud.gdshaderinc"

uniform vec3 paper : source_color = vec3(0.937, 0.902, 0.824);
uniform vec3 ink_col : source_color = vec3(0.133, 0.110, 0.094);

uniform float exposure = 2.2;
uniform float totality_gain = 1.5;    // exposure multiplier at totality
uniform float night_gain = 3.0;
uniform float resp_r = 0.60;          // channel mix of the tone (a "plate response")
uniform float resp_g = 0.55;
uniform float resp_b = -0.15;
uniform float tone_lo = 0.10;         // display tone that prints solid
uniform float tone_hi = 0.80;         // display tone that stays bare paper
uniform float sky_ink = 0.80;         // the sky never prints darker than this share
uniform float sky_gain = 0.4;         // exposure of the day sky alone (below 1 rules it)
uniform float line_px = 5.0;          // line spacing in pixels
uniform float ray_px = 5.0;           // corona ray spacing in pixels
uniform float ray_inner = 3.0;        // rays hold to this many solar radii …
uniform float ray_outer = 8.0;        // … and hand over to the ruling by this many
uniform float cross_at = 0.34;        // darkness of tone where the second family starts
uniform float third_at = 0.62;
uniform float solid_lo = 0.92;
uniform float solid_hi = 0.99;
uniform float flat_at = 0.92;         // |normal.y| above this is hatched in plan
uniform float outline = 1.0;
uniform float outline_px = 1.3;
uniform float edge_depth = 0.02;
uniform float edge_normal = 0.18;
uniform float far_outline = 0.35;     // outline strength beyond 45 m
uniform float wobble = 1.0;           // hand wobble of the lines
uniform float wobble_rel = 0.35;      // the wobble never exceeds this share of the line spacing
uniform float tone_lod = 0.0;         // blur (mip level at 720 lines) of the tone the hatching follows
// Distance: beyond far_start the land hands its surface lines over to one ruling of
// straight page lines, the sky's own, so that far things are quiet and lie behind near ones.
uniform float far_start = 25.0;
uniform float far_end = 70.0;
uniform float far_floor = 0.28;       // lightest tone of distant land (0 = bare paper)
uniform float far_cap = 0.55;         // darkest tone of distant land by day
uniform float far_tot = 0.75;         // lightest tone of distant land at totality: a silhouette
uniform float far_lod = 2.5;          // blur of the distant tone
uniform float far_edge = 0.35;        // relative depth step that still draws a contour far away
uniform float ground_rule = 1.0;      // at totality level ground is ruled in the sky's lines alone (0 = its plan hatching)
uniform float ground_mottle = 0.7;    // the ruled ground's lines swell and thin in patches fixed to the ground (0 = an even tint, 1 = up to the heaviest line)
uniform float ground_grain = 2.0;     // the smallest patch spans this many lines of the ruling, at any distance
uniform float ground_edge = 0.85;     // 0 the patches melt into each other … 1 they have an edge
uniform float far_line = 0.0;         // contour strength of distant land (0 = its tone alone carries it)
uniform float far_sky = 0.40;         // ink share of a clear day sky high up, the reference for far_step
uniform float far_step = 0.16;       // by day distant land prints at least this much darker than clear sky
uniform float far_in = 0.25;          // share of the way to far_end by which that floor is fully in
uniform float wash_far = 0.4;        // share of the wash left on distant land
uniform float sky_horizon = 0.5;      // share of the day sky's ruling left at the horizon (1 = even sky)
uniform float sky_horizon_h = 0.45;   // altitude in radians where the sky's ruling is back at full weight
uniform float ground_cap = 0.60;      // darkest tone of level ground at totality (1 = may print solid)
uniform float wash = 0.35;            // 0 ink only … 1 hand-coloured
uniform float wash_depth = 0.0;       // 0 the wash only tints … 1 it also carries the scene's value
uniform float wash_floor = 0.25;      // darkest value of the wash
uniform float paper_grain = 0.05;
// Totality as a drawing on blue paper: dark ink, the lights heightened in white.
uniform vec3 tot_paper : source_color = vec3(0.17, 0.21, 0.40);
uniform float tot_wash = 1.0;         // 0 the page stays cream … 1 it turns to blue paper at totality
uniform float heighten_lo = 0.55;     // tone where the white heightening starts
uniform float heighten_hi = 0.85;
// Night: a dark page; where red light falls (the safelight) the page is washed red.
uniform vec3 night_paper : source_color = vec3(0.07, 0.08, 0.16);
uniform vec3 safe_paper : source_color = vec3(0.42, 0.10, 0.07);
uniform vec3 safe_light : source_color = vec3(0.96, 0.62, 0.45);
uniform float night_wash = 1.0;       // 0 the page stays cream at night … 1 dark page and red wash
uniform float ink_strength = 0.94;
uniform float normal_from_depth = 0.0; // 1: normals from depth derivatives instead of the buffer

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Ground patches: four octaves of value noise, each turned against the last. lod is log2 of the
// smallest size wanted; an octave comes in as lod falls below it and lasts over three more, so a
// patch keeps its shape while the camera nears and finer ones arrive inside it.
float patch_n(vec2 p, float lod) {
	float l0 = floor(lod);
	float acc = 0.0;
	float nrm = 0.0;
	for (int i = 1; i <= 4; i++) {
		float j = l0 + float(i);
		float t = j - lod;
		float w = smoothstep(0.0, 1.5, t) * (1.0 - smoothstep(2.0, 3.5, t));
		float a = j * 2.4;
		vec2 r = vec2(cos(a) * p.x - sin(a) * p.y, sin(a) * p.x + cos(a) * p.y) / exp2(j);
		acc += (vnoise(r + vec2(j * 7.3, j * 3.1)) - 0.5) * w;
		nrm += w * w;
	}
	return 0.5 + acc / sqrt(max(nrm, 0.0001));
}

// Coverage of one line of half-width h at distance d from its centre, for a
// pixel footprint aa (all in line-coordinate units). Hairlines fade, never alias.
float line_cov(float d, float h, float aa) {
	return clamp((h - d) / (2.0 * aa) + 0.5, 0.0, 1.0) * clamp(h / aa, 0.0, 1.0);
}

// One family of parallel lines. u: line coordinate. g: |du| per pixel.
// cover: share of ink wanted, 0..1. px: spacing in pixels. max_lod: cap on
// log2(spacing) for periodic coordinates (99.0 for none).
float hatch(float u, float g, float cover, float px, float max_lod) {
	float lod = min(log2(max(g, 0.0000001) * px), max_lod + 0.999);
	float s0 = exp2(floor(lod));
	float f = lod - floor(lod);
	float w_odd = 1.0 - smoothstep(0.15, 0.85, f);   // every second line tapers out toward the next octave
	float v = u / (2.0 * s0);
	float aa = 0.6 * g / (2.0 * s0);
	float h_even = 0.5 * cover / (1.0 + w_odd);
	float h_odd = h_even * w_odd;
	float d_even = abs(fract(v + 0.5) - 0.5);
	float d_odd = abs(fract(v) - 0.5);
	return max(line_cov(d_even, h_even, aa), line_cov(d_odd, h_odd, aa));
}

// Page ruling shared by sky, distant land and ridges. Each constant coordinate
// is a straight line in the perspective image. Pitch moves the phase; yaw does
// not. hatch receives the same k everywhere, so its octave never varies by pixel
// or camera orientation (and k * l_px is independent of viewport resolution).
vec2 page_ruling(vec3 ray, mat4 camera) {
	float pitch = asin(clamp(-camera[2].y, -1.0, 1.0));
	return vec2(atan(ray.y, -ray.z), atan(ray.y + 0.62 * ray.x, -ray.z)) + vec2(pitch);
}

// Engrave the live field's 0.35 contour; the second component retains density
// for line weights and solar veiling. No separate cloud geometry is invented.
vec2 print_cloud(vec3 direction, float print_darkness) {
	float density = eclipse_cloud_density(direction);
	float contour_density = mix(0.10, 0.35, print_darkness);
	return vec2(contour_density - density, density);
}

// |d(dot(P, a))| per pixel on the surface through the view-space point z * q
// (q.z = -1) with view-space normal n. k: view units per pixel at depth 1.
float grad_px(vec3 a_v, vec3 n_v, vec3 q, float z, float k) {
	float nq = dot(n_v, q);
	nq = (nq < 0.0 ? -1.0 : 1.0) * max(abs(nq), 0.06);
	float aq = dot(a_v, q);
	vec2 d = vec2(a_v.x - aq * n_v.x / nq, a_v.y - aq * n_v.y / nq);
	return z * k * length(d);
}

vec3 view_pos(sampler2D depth, vec2 uv, mat4 inv_proj) {
	float raw = texture(depth, uv).r;
	if (raw < 0.00001) {
		// Sky: a point far along the ray, so differences against it read as an edge.
		vec4 far4 = inv_proj * vec4(uv * 2.0 - 1.0, 0.5, 1.0);
		return normalize(far4.xyz / far4.w) * 4000.0;
	}
	vec4 p = inv_proj * vec4(uv * 2.0 - 1.0, raw, 1.0);
	return p.xyz / p.w;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float raw = texture(depth_tex, uv).r;
	bool sky = raw < 0.00001;
	vec3 pv = view_pos(depth_tex, uv, INV_PROJECTION_MATRIX);
	float z = max(-pv.z, 0.01);
	vec3 ray_v = normalize(pv);
	vec3 ray_w = normalize((INV_VIEW_MATRIX * vec4(ray_v, 0.0)).xyz);
	float print_darkness = darkness;
	float day_weight = night > 0.5 ? 0.0 : 1.0 - smoothstep(0.35, 1.0, print_darkness);
	float k = 2.0 / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y);
	// Line weights are given for a 720-line frame and follow the viewport height.
	float res_k = VIEWPORT_SIZE.y / 720.0;
	float l_px = line_px * res_k;
	vec2 ruling = page_ruling(ray_v, INV_VIEW_MATRIX);
	// 0 near … 1 distant land. By distance, not depth, so that turning the head changes nothing.
	float dist_f = sky ? 0.0 : smoothstep(far_start, far_end, length(pv));
	float elev = asin(clamp(ray_w.y, -1.0, 1.0));
	// By day the sky's ruling thins toward the horizon, so distant land can stand a tone darker against it.
	float lit = 1.0 - max(print_darkness, night);
	float hz = mix(1.0, mix(sky_horizon, 1.0, smoothstep(0.0, sky_horizon_h, elev)), lit);
	vec3 c = texture(screen_tex, uv).rgb;
	vec3 c_t = textureLod(screen_tex, uv, max(mix(tone_lod, far_lod, dist_f) + log2(res_k), 0.0)).rgb;

	// Tone: 1 = bare paper, 0 = solid ink.
	float ex = exposure * mix(1.0, totality_gain, print_darkness) * mix(1.0, night_gain, night);
	float lum = max(dot(c_t, vec3(resp_r, resp_g, resp_b)), 0.0) * ex * (sky ? mix(sky_gain, 1.0, print_darkness) : 1.0);
	float tone = pow(lum / (1.0 + lum), 0.4545);
	float tone_raw = tone;
	tone = clamp((tone - tone_lo) / max(tone_hi - tone_lo, 0.001), 0.0, 1.0);
	float dark = 1.0 - tone;

	// Outlines: second difference of depth (zero on any flat surface) and normal breaks.
	vec2 o = mix(outline_px, 0.5, day_weight) * res_k / VIEWPORT_SIZE;
	vec3 p_l = view_pos(depth_tex, uv - vec2(o.x, 0.0), INV_PROJECTION_MATRIX);
	vec3 p_r = view_pos(depth_tex, uv + vec2(o.x, 0.0), INV_PROJECTION_MATRIX);
	vec3 p_d = view_pos(depth_tex, uv - vec2(0.0, o.y), INV_PROJECTION_MATRIX);
	vec3 p_u = view_pos(depth_tex, uv + vec2(0.0, o.y), INV_PROJECTION_MATRIX);
	float lap = abs(p_l.z + p_r.z - 2.0 * pv.z) + abs(p_d.z + p_u.z - 2.0 * pv.z);
	float e_thr = mix(edge_depth, far_edge, dist_f);
	float edge = smoothstep(e_thr, e_thr * 2.5, lap / z);

	vec3 n_v = vec3(0.0, 0.0, 1.0);
	float ink = 0.0;
	float tone_p = tone;   // the tone the page's heightening follows
	float bead = 0.0;
	float moon_ink = 0.0;
	float box_reserve = 0.0;
	float case_solid = 0.0;
	float room_value = -1.0;
	bool measuring_paper = false;
	float paper_edge = 0.0;
	float ridge_totality = 0.0;
	float sky_white = 0.0;
	float corona_white = 0.0;
	float sun_rim = 0.0;
	bool surface_print = false;
	if (sky) {
		dark *= sky_ink;
		// A silhouette against the sky is drawn from the sky's side too: not for distant land.
		float d_near = min(min(length(p_l), length(p_r)), min(length(p_d), length(p_u)));
		edge *= mix(1.0, far_line, smoothstep(far_start, far_end, d_near));
		if (d_near > 75.0 && d_near < 1000.0) edge = mix(edge, 1.0, day_weight);
		vec2 cloud_field = vec2(10.0, 0.0);
		if (night <= 0.5 && (print_darkness > 0.0 || practice_cloud >= 0.0)) cloud_field = print_cloud(ray_w, print_darkness);
		vec2 cloud_gradient = vec2(dFdx(cloud_field.x), dFdy(cloud_field.x));
		float cloud_pixel = max(length(cloud_gradient), 0.00001);
		float cloud_body = 1.0 - smoothstep(-cloud_pixel, cloud_pixel, cloud_field.x);
		float cloud_weight = cloud_body * (0.4 + 0.3 * step(0.6, cloud_field.y) + 0.3 * step(0.85, cloud_field.y));
		float cloud_contour = 1.0 - smoothstep(0.35, 0.85, abs(cloud_field.x) / (cloud_pixel * res_k));
		float horizon = 1.0 - smoothstep(0.0, 0.16, abs(elev));
		float high_sky = smoothstep(0.0, 1.2, elev);
		float band_lines = smoothstep(0.015, 0.19, abs(elev));
		// One cloud stroke family by day, with the second family and open
		// sky ruling coming in as the paper cools.
		float cloud_tone = cloud_body * (0.10 + 0.34 * smoothstep(0.10, 0.80, cloud_field.y));
		float primary = mix(cloud_tone, 0.04 + 0.06 * high_sky + 0.65 * cloud_weight, print_darkness) * band_lines;
		float crossed = (0.02 * high_sky + 0.40 * cloud_weight) * band_lines * print_darkness;
		float contour_ink = mix(0.24 * smoothstep(0.0, 0.35, cloud_field.y), 0.8, print_darkness);
		float tilt = asin(clamp(dot(ray_w, normalize(vec3(0.62, 0.48, 0.62))), -1.0, 1.0));
		vec2 sky_ruling = ruling;
		if (night > 0.5) {
			sky_ruling = vec2(elev, tilt);
			primary = clamp((dark - 0.06) * 1.7, 0.0, 0.55) * hz;
			crossed = clamp((dark - cross_at) * 1.6, 0.0, 0.55) * hz;
		}
		float i1 = hatch(sky_ruling.x, k, primary, l_px, 99.0);
		float i2 = hatch(sky_ruling.y, k, crossed, l_px, 99.0);
		// At the band's edge, retain every fourth ruled line and thin the rest away.
		float sparse = hatch(ruling.x, k, primary, l_px * 4.0, 99.0);
		i1 = mix(i1, mix(sparse, i1, band_lines), print_darkness);
		ink = 1.0 - (1.0 - i1) * (1.0 - i2);
		ink = max(ink, cloud_contour * band_lines * contour_ink);
		sky_white = horizon * 0.85;
		// Corona: near the eclipsed Sun the ruling gives way to rays about its centre.
		vec3 t1 = normalize(cross(sun_dir, vec3(0.0, 1.0, 0.0)));
		vec3 t2 = cross(t1, sun_dir);
		vec2 lp = vec2(dot(ray_w, t1), dot(ray_w, t2)) / sun_r;   // in solar radii
		float r = length(lp);
		float front = step(0.0, dot(ray_w, sun_dir));
		vec2 moon_c = vec2((1.0 - contact) * 2.1, 0.12 * (1.0 - contact));
		if (practice_cloud >= 0.0) {
			float crescent = max(r - 1.0, 1.0 - length(lp - moon_c));
			float sun_pixel = max(fwidth(crescent), 0.00001);
			sun_rim = front * (1.0 - smoothstep(0.2, 0.9, abs(crescent) / (sun_pixel * res_k)));
		}
		vec2 bead_c = -normalize(moon_c + vec2(0.0001, 0.0));
		vec3 bead_dir = normalize(sun_dir + sun_r * (t1 * bead_c.x + t2 * bead_c.y));
		float dens = eclipse_cloud_density(bead_dir);
		// The sky composites solar light with this transmission. Carry it by
		// area on the page, keeping the burst bare paper rather than grey.
		float alpha = clamp(dens * 1.08, 0.0, 1.0);
		float transmission = (1.0 - alpha) * (1.0 + 0.15 * alpha);
		float visible_diamond = diamond * transmission;
		float size = sqrt(visible_diamond);
		vec2 bp = lp - bead_c;
		float bead_dist = length(bp);
		// Fixed unequal rays, each narrowing to a point as it leaves the core.
		float spikes = 0.0;
		for (int i = 0; i < 9; i++) {
			float fi = float(i);
			float direction = fi * 2.399963;
			vec2 spike_dir = vec2(cos(direction), sin(direction));
			float along = dot(bp, spike_dir);
			float across = abs(dot(bp, vec2(-sin(direction), cos(direction))));
			float reach = diamond_spikes * size * (0.45 + 0.55 * hash21(vec2(fi, 7.0)));
			float inward = -dot(spike_dir, bead_c);
			if (inward > 0.0) reach = min(reach, 0.333 / inward);
			spikes = max(spikes, step(0.0, along) * step(along, reach) * step(across, diamond_radius * size * 0.36 * (1.0 - along / max(reach, 0.00001))));
		}
		bead = front * step(0.000001, visible_diamond) * max(step(bead_dist, diamond_radius * size), spikes);
		// Cloud changes the weight of ruling across the whole Moon, never its
		// outline. The accepted thin gap and clearer skies keep solid ink.
		float moon_weight = 1.0 - smoothstep(0.15, 1.0 / 1.08, dens);
		// Totality and the diamond both retain the cloud-dependent Moon ruling.
		float moon_cover = moon_weight * max(diamond, print_darkness);
		float moon_lines = hatch(sky_ruling.x, k, moon_cover, l_px, 99.0);
		moon_lines = max(moon_lines, step(1.0, moon_weight) * smoothstep(0.95, 1.0, moon_cover));
		moon_ink = front * step(r, 1.0) * moon_lines;

		// 2026-11-23 JST: hairline cuts, with four unequal streamer bundles.
		// Pixel coverage keeps subpixel strokes continuous in the wide 720p view.
		if (print_darkness > 0.0 && front > 0.0) {
			float sector = (atan(lp.y, lp.x) / 6.2831853 + 0.5) * 240.0;
			float id = floor(sector);
			float seed = hash21(vec2(id, 19.0));
			float angle = ((id + 0.5) / 240.0 - 0.5) * 6.2831853;
			vec2 direction = vec2(cos(angle), sin(angle));
			float streamer = max(max(dot(direction, vec2(-0.9353, -0.3538)), dot(direction, vec2(0.5978, -0.8016))),
				max(dot(direction, vec2(0.8916, 0.4529)), dot(direction, vec2(0.3717, 0.9284))));
			streamer = smoothstep(0.991, 1.0, streamer);
			float reach = mix(1.5 + seed, 3.1 + 0.9 * hash21(vec2(id, 5.0)), streamer);
			float taper = sqrt(clamp((reach - r) / (reach - 1.0), 0.0, 1.0));
			float across = dot(lp, vec2(-direction.y, direction.x));
			float pixel = max(length(vec2(dot(dFdx(lp), vec2(-direction.y, direction.x)), dot(dFdy(lp), vec2(-direction.y, direction.x)))), 0.00001);
			// Leave paper between adjacent strokes even where their centres are subpixel.
			float half_width = min(0.55 * res_k * pixel * taper, 0.40 * 6.2831853 * r / 240.0);
			float rays = clamp((half_width + 0.5 * pixel - abs(across)) / pixel, 0.0, 1.0)
				- clamp((0.5 * pixel - half_width - abs(across)) / pixel, 0.0, 1.0);
			float limb_white = 1.0 - smoothstep(1.035, 1.065, r);
			// A clear Sun keeps the accepted complete starburst. Thin cloud uses
			// the very same contour and ruling as the drawn cloud, never shorter rays
			// or a white trace of the simulation's carved density levels.
			float sun_cloud = eclipse_cloud_density(sun_dir);
			float cloud_veil = max(ink, smoothstep(0.6, 0.85, cloud_field.y)) * smoothstep(0.35, 0.45, sun_cloud);
			corona_white = max(limb_white, rays) * step(1.0, r) * (1.0 - cloud_veil);
		}


	} else {
		vec3 q = pv / z;
		vec4 surface = texture(normal_tex, uv);
		// Forward+ normal/roughness reads decode the prepass's 7-bit roughness.
		surface_print = day_weight > 0.0 && abs(surface.w - 17.0 / 127.0) < 0.003;
		vec3 n_buf = normalize(surface.xyz * 2.0 - 1.0);
		vec3 n_dep = normalize(cross(dFdx(pv), dFdy(pv)));
		n_dep = dot(n_dep, pv) > 0.0 ? -n_dep : n_dep;
		n_v = normal_from_depth > 0.5 ? n_dep : n_buf;
		vec3 n_w = normalize((INV_VIEW_MATRIX * vec4(n_v, 0.0)).xyz);
		vec3 pw = (INV_VIEW_MATRIX * vec4(pv, 1.0)).xyz;
		ridge_totality = step(75.0, length(pw.xz)) * step(-0.39, pw.y) * print_darkness * (1.0 - night);
		// Local paper reserve on the plate box's top and door-facing edge.
		// Kept separate from tone/outline defaults and inactive at night/totality.
		vec3 box_delta = abs(pw - vec3(11.65, 1.18, 2.25));
		if (all(lessThan(box_delta, vec3(0.181, 0.151, 0.251)))) {
			float top = smoothstep(1.26, 1.29, pw.y);
			float side = (1.0 - smoothstep(11.49, 11.52, pw.x)) * smoothstep(2.42, 2.46, pw.z);
			box_reserve = max(top, side) * lit;
		}

		// The brass rim/handle catch the same doorway key; the glass stays dark.
		vec2 loupe_delta = pw.xz - vec2(11.0, 3.94);
		bool loupe_ring = length(loupe_delta) < 0.106 && pw.y > 0.849 && pw.y < 0.875;
		bool loupe_handle = abs(loupe_delta.x) < 0.028 && loupe_delta.y > 0.075 && loupe_delta.y < 0.271 && pw.y > 0.853 && pw.y < 0.879;
		if (loupe_ring || loupe_handle) {
			box_reserve = max(box_reserve, lit);
		}
		// The black Oxford case stands solid on the lantern's reserved bench.
		if (all(lessThan(abs(pw - vec3(-2.65, 0.95, -3.45)), vec3(0.201, 0.111, 0.161)))) {
			case_solid = night;
		}

		if (normal_from_depth < 0.5) {
			vec3 n_l = normalize(texture(normal_tex, uv - vec2(o.x, 0.0)).xyz * 2.0 - 1.0);
			vec3 n_r = normalize(texture(normal_tex, uv + vec2(o.x, 0.0)).xyz * 2.0 - 1.0);
			vec3 n_d = normalize(texture(normal_tex, uv - vec2(0.0, o.y)).xyz * 2.0 - 1.0);
			vec3 n_u = normalize(texture(normal_tex, uv + vec2(0.0, o.y)).xyz * 2.0 - 1.0);
			float n_break = 1.0 - min(min(dot(n_v, n_l), dot(n_v, n_r)), min(dot(n_v, n_d), dot(n_v, n_u)));
			edge = max(edge, smoothstep(edge_normal, edge_normal * 2.0, n_break) * (1.0 - dist_f));
		}

		float day_ink = 0.0;
		float day_edge = edge;
		if (day_weight > 0.0) {
			// The rest of the day frame carries flat tone and contours.
			float shade_side = 1.0 - smoothstep(0.0, 0.35, dot(n_w, sun_dir));
			day_ink = max(smoothstep(0.12, 0.72, dark), 0.88 * shade_side);
			day_edge *= mix(1.0, far_outline, smoothstep(10.0, 45.0, z)) * (1.0 - dist_f);
			if (length(pw.xz) > 75.0 && pw.y > -0.39) day_ink = 0.16;
		}
		if (print_darkness < 0.001 && night > 0.5) {
			bool foliage = c.g > c.r * 1.08 && c.g > c.b * 1.15 && pw.y > 0.08;
			bool room = all(lessThan(abs(pw - vec3(10.0, 1.3, 3.0)), vec3(2.1, 1.5, 1.8)));
			bool wall_board = room && (abs(pw.x - 8.0) < 0.07 || abs(pw.x - 12.0) < 0.07 || abs(pw.z - 1.3) < 0.07 || abs(pw.z - 4.7) < 0.07);
			bool floor_board = room && pw.y < 0.06;
			bool table_wood = room && abs(n_w.y) > flat_at && (abs(pw.y - 0.85) < 0.002 || abs(pw.y - 0.88) < 0.002 || abs(pw.y - 1.025) < 0.002);
			measuring_paper = all(lessThan(abs(pw - vec3(10.6, 0.86, 4.1)), vec3(0.251, 0.011, 0.201)));
			vec3 t_h = abs(n_w.x) > abs(n_w.z) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
			vec3 a1 = abs(n_w.y) > flat_at ? vec3(0.707107, 0.0, 0.707107) : t_h * 0.8 + vec3(0.0, 0.6, 0.0);
			vec3 a2 = abs(n_w.y) > flat_at ? vec3(0.707107, 0.0, -0.707107) : t_h * -0.6 + vec3(0.0, 0.8, 0.0);
			// Use the visible side of two-sided canvas, including its underside.
			vec3 facing = normalize((INV_VIEW_MATRIX * vec4(n_dep, 0.0)).xyz);
			float unlit_face = 1.0 - smoothstep(0.0, 0.25, dot(facing, sun_dir));
			dark = max(dark, 0.40 * unlit_face * (1.0 - night));
			// These three shallow dirt boxes are the site's trampled paths.
			if (n_w.y > flat_at && pw.y > 0.015 && pw.y < 0.027) dark = max(dark, 0.44);
			if ((wall_board || floor_board || table_wood) && night > 0.5) {
				// Level wall ruling, oblique floorboards, reverse-sloping bench wood.
				a1 = vec3(0.0, 1.0, 0.0);
				if (floor_board) a1 = vec3(0.940, 0.0, 0.342);
				if (table_wood) a1 = vec3(0.707107, 0.0, -0.707107);
				room_value = floor_board ? 0.14 : (table_wood ? 0.52 : 0.22);
			}
			if (foliage) {
				// One leaf-stroke field crosses the mesh facets, with short broken strokes.
				a1 = vec3(0.8, 0.6, 0.0);
				a2 = vec3(-0.6, 0.8, 0.0);
				dark = 0.48;
				edge = smoothstep(e_thr, e_thr * 2.5, lap / z);
			}
			float shadow = smoothstep(0.48, 0.72, dark);
			float first = clamp((dark - 0.20) * 0.85, 0.0, 0.32) + shadow * 0.28;
			first = mix(first, clamp((dark - 0.06) * 1.7, 0.18, 0.55), night);
			float weight = 1.0 - dist_f;
			float g1 = grad_px((VIEW_MATRIX * vec4(a1, 0.0)).xyz, n_v, q, z, k);
			float g2 = grad_px((VIEW_MATRIX * vec4(a2, 0.0)).xyz, n_v, q, z, k);
			float u1 = dot(pw, a1);
			if (foliage) {
				g1 = length(vec2(dFdx(u1), dFdy(u1)));
				first *= smoothstep(0.3, 0.6, vnoise(pw.xz * 5.0 + vec2(pw.y * 3.0)));
			}
			float spacing = l_px * mix(0.6, 1.0, night);
			float i1 = hatch(u1, g1, first * weight, spacing, 99.0);
			float i2 = hatch(dot(pw, a2), g2, shadow * mix(0.60, 0.20, night) * weight, spacing, 99.0);
			// At grazing angles only the better-resolved family remains.
			float grazing = smoothstep(0.15, 0.4, abs(dot(n_v, normalize(pv))));
			if (g1 > g2) i1 *= grazing;
			else i2 *= grazing;
			ink = 1.0 - (1.0 - i1) * (1.0 - i2);
			ink = max(ink, smoothstep(0.84, 0.98, dark) * weight);
			tone_p = mix(tone_p, tone_raw, night);
			if (measuring_paper) {
				vec2 margin = vec2(0.25, 0.20) - abs(pw.xz - vec2(10.6, 4.1));
				vec2 pixel = max(fwidth(pw.xz), vec2(0.0001));
				paper_edge = 1.0 - smoothstep(0.0, 1.0, min(margin.x / pixel.x, margin.y / pixel.y));
				room_value = 1.0;
			}
		} else if (day_weight < 1.0) {
			// Three line families per surface. Flat surfaces are hatched in plan; all
			// others carry level lines (constant height) crossed by two diagonals.
			vec3 a1;
			vec3 a2;
			vec3 a3;
			if (n_w.y > flat_at) {
				// At totality level ground stays open ruling; what stands on it prints solid.
				dark = min(dark, mix(1.0, ground_cap, print_darkness));
			}
			// At totality level ground gives up its plan hatching for the page's one ruling: seen at a
			// grazing angle the crossed families beat against each other and against the distant ruling.
			float g_rule = n_w.y > flat_at ? print_darkness * ground_rule : 0.0;
			if (abs(n_w.y) > flat_at) {
				a1 = vec3(0.940, 0.0, 0.342);
				a2 = vec3(0.087, 0.0, 0.996);
				a3 = vec3(0.766, 0.0, -0.643);
			} else {
				vec3 t_h = abs(n_w.x) > abs(n_w.z) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
				a1 = vec3(0.0, 1.0, 0.0);
				a2 = normalize(vec3(0.0, 0.8, 0.0) + t_h * 0.6);
				a3 = normalize(vec3(0.0, 0.8, 0.0) - t_h * 0.6);
			}
			vec3 a1_v = (VIEW_MATRIX * vec4(a1, 0.0)).xyz;
			vec3 a2_v = (VIEW_MATRIX * vec4(a2, 0.0)).xyz;
			vec3 a3_v = (VIEW_MATRIX * vec4(a3, 0.0)).xyz;
			float g1 = grad_px(a1_v, n_v, q, z, k);
			float wob = (vnoise(pw.xz * 1.7 + vec2(pw.y * 0.9)) - 0.5) * min(0.04, wobble_rel * g1 * l_px) * wobble;
			float w_base = (1.0 + (vnoise(pw.xz * 0.8 + vec2(pw.y * 1.3)) - 0.5) * 0.3 * wobble) * (1.0 - dist_f);
			float weight = w_base * (1.0 - g_rule);
			float i1 = hatch(dot(pw, a1) + wob, g1, clamp((dark - 0.06) * 1.7, 0.0, 0.55) * w_base * (1.0 - g_rule), l_px, 99.0);
			float i2 = hatch(dot(pw, a2) + wob, grad_px(a2_v, n_v, q, z, k), clamp((dark - cross_at) * 1.6, 0.0, 0.55) * weight, l_px, 99.0);
			float i3 = hatch(dot(pw, a3) - wob, grad_px(a3_v, n_v, q, z, k), clamp((dark - third_at) * 2.2, 0.0, 0.60) * weight, l_px, 99.0);
			ink = 1.0 - (1.0 - i1) * (1.0 - i2) * (1.0 - i3);
			ink = max(ink, smoothstep(solid_lo, solid_hi, dark) * (1.0 - dist_f));
			// Distant land: one ruling in the sky's own lines, between a floor and a cap of tone.
			float dark_far = clamp(max(dark, mix(far_floor, far_tot, print_darkness)), 0.0, mix(far_cap, 1.0, print_darkness));
			// The floor comes in early: a sunlit palm at 40 m has lost its own lines and must not print paler than the sky.
			float cov_floor = (far_sky * hz + far_step) * lit * smoothstep(0.0, far_in, dist_f);
			float cov_far = max(clamp((dark_far - 0.06) * 1.3, 0.0, 0.85) * dist_f, cov_floor);
			// The ruling is the page's and stays with the sky; its weight belongs to the ground, so a walk shows the ground passing under the lines.
			// The patches grow with distance (by distance, not depth), so that the smallest still spans ground_grain lines: a smaller one would flicker between the lines.
			float d_g = length(pv);
			float s_min = ground_grain * l_px * k * d_g * d_g / max(INV_VIEW_MATRIX[3].y - pw.y, 0.3);
			float lod_g = log2(max(s_min, 0.001));
			float n_g = patch_n(pw.xz, lod_g);
			float w_g = mix(0.5, 0.06, ground_edge);
			float g_mot = (smoothstep(0.5 - w_g, 0.5 + w_g, n_g) * 2.0 - 1.0) * ground_mottle * (1.0 - smoothstep(15.0, 45.0, d_g));
			float c_g = clamp((ground_cap - 0.06) * 1.3, 0.0, 0.85);
			cov_far = mix(cov_far, c_g + g_mot * min(c_g, 0.85 - c_g), g_rule);
			float i_far = hatch(elev, k, cov_far, l_px, 99.0);
			ink = 1.0 - (1.0 - ink) * (1.0 - i_far);
			tone_p = mix(tone, 1.0 - dark_far, dist_f);
			edge *= mix(1.0, far_outline, smoothstep(10.0, 45.0, z)) * mix(1.0, far_line, dist_f);
		}
		ink = mix(ink, day_ink, day_weight);
		edge = mix(edge, day_edge, day_weight);
		// Far land at totality is sparse ruling on the horizon's cream reserve.
		float ridge_distance = smoothstep(75.0, 550.0, length(pw.xz));
		float ridge_lines = hatch(elev, k, mix(0.24, 0.14, ridge_distance), l_px * mix(1.5, 2.5, ridge_distance), 99.0);
		ink = mix(ink, ridge_lines, ridge_totality);
	}
	ink = max(ink, edge * outline);
	if (measuring_paper) ink = paper_edge;
	ink = mix(ink, min(ink, 0.08), box_reserve);
	ink = max(ink, case_solid);

	// Paper: fibre grain fixed to the page; an optional thin wash of the scene's hue.
	vec2 fp = FRAGCOORD.xy / res_k;
	float fibre = (vnoise(fp * 0.35) * 0.6 + vnoise(fp * vec2(0.05, 0.9)) * 0.4) * (sky ? 1.0 - print_darkness : 1.0);
	vec3 hue = c / max(max(c.r, max(c.g, c.b)), 0.0001);
	vec3 page = paper * (1.0 - paper_grain * fibre) * mix(vec3(1.0), hue, wash * mix(1.0, wash_far, dist_f)) * mix(1.0, mix(wash_floor, 1.0, tone_raw), wash_depth);
	page = mix(page, paper * (1.0 - paper_grain * fibre), day_weight);
	if (print_darkness < 0.001 && night > 0.5) {
		page = paper * (1.0 - paper_grain * fibre) * mix(vec3(1.0), hue, wash * mix(1.0, wash_far, dist_f) * (sky ? 1.0 : max(print_darkness, night))) * mix(1.0, mix(wash_floor, 1.0, tone_raw), wash_depth);
	}
	float blue = print_darkness * tot_wash;
	page = mix(page, tot_paper * (1.0 - paper_grain * fibre), blue);
	page = mix(page, paper, (sky ? sky_white : smoothstep(heighten_lo, heighten_hi, tone_p)) * blue);
	page = mix(page, paper * (1.0 - paper_grain * fibre), ridge_totality);
	float nw = night * night_wash;
	float red = smoothstep(0.15, 0.5, clamp((c.r - max(c.g, c.b)) / max(c.r, 0.0001), 0.0, 1.0));
	page = mix(page, mix(night_paper, safe_paper, red) * (1.0 - paper_grain * fibre), nw);
	if (print_darkness < 0.001 && night > 0.5) {
		float night_value = sky ? smoothstep(heighten_lo, heighten_hi, tone_p) : smoothstep(0.25, 0.96, tone_raw);
		if (room_value >= 0.0) night_value = room_value;
		page = mix(page, mix(paper, safe_light, red), night_value * nw);
	} else {
		page = mix(page, mix(paper, safe_light, red), smoothstep(heighten_lo, heighten_hi, tone_p) * nw);
	}
	vec3 print_colour = mix(page, mix(ink_col, page, ridge_totality * 0.4), clamp(ink, 0.0, 1.0) * ink_strength);
	if (surface_print) {
		vec3 stock = mix(c, c * tot_paper / paper, blue);
		vec3 surface_colour = mix(stock * (1.0 - paper_grain * fibre), ink_col, edge * outline * ink_strength);
		print_colour = mix(print_colour, surface_colour, day_weight);
	}
	print_colour = mix(print_colour, ink_col, sun_rim * 0.42);
	print_colour = mix(print_colour, ink_col, moon_ink);
	print_colour = mix(print_colour, vec3(1.0), corona_white * print_darkness);
	// Only the sky around an optically visible field star gets a reserve.
	// Keep the original white core; the corona's ruling ends at its ink edge.
	float star_vis = clamp((print_darkness - 0.85) / 0.15, 0.0, 1.0) * (1.0 - night);
	if (sky && star_vis > 0.0 && star_keyline_px > 0.0) {
		vec3 t1 = normalize(cross(sun_dir, vec3(0.0, 1.0, 0.0)));
		vec3 t2 = cross(t1, sun_dir);
		for (int i = 0; i < 12; i++) {
			vec2 offset = star_pos[i] * sun_r;
			vec3 direction = sun_dir * sqrt(1.0 - dot(offset, offset)) + t1 * offset.x + t2 * offset.y;
			vec4 projected = PROJECTION_MATRIX * VIEW_MATRIX * vec4(direction, 0.0);
			vec2 star_uv = projected.xy / projected.w * 0.5 + 0.5;
			// Anchor the reserve to the output pixel grid. Every subpixel
			// star position therefore prints the same closed round sign.
			vec2 centre_px = floor(star_uv * VIEWPORT_SIZE) + vec2(0.5);
			float distance_px = length(uv * VIEWPORT_SIZE - centre_px);
			float inner_px = 1.5 * res_k;
			float outer_px = (1.5 + star_keyline_px) * res_k;
			if (projected.w > 0.0 && distance_px < outer_px + 0.3 * res_k) {
				float gate = (1.0 - smoothstep(0.35, 0.80, eclipse_cloud_density(direction))) * star_vis;
				float ring = step(inner_px, distance_px) * (1.0 - smoothstep(outer_px - 0.5 * res_k, outer_px + 0.3 * res_k, distance_px));
				// Read the field outside the point, so its white core cannot
				// turn on a keyline against otherwise dark paper.
				vec2 sample_px = vec2(4.0) / VIEWPORT_SIZE;
				vec3 response = vec3(resp_r, resp_g, resp_b);
				float field_lum = min(min(dot(textureLod(screen_tex, star_uv + vec2(sample_px.x, 0.0), 0.0).rgb, response), dot(textureLod(screen_tex, star_uv - vec2(sample_px.x, 0.0), 0.0).rgb, response)), min(dot(textureLod(screen_tex, star_uv + vec2(0.0, sample_px.y), 0.0).rgb, response), dot(textureLod(screen_tex, star_uv - vec2(0.0, sample_px.y), 0.0).rgb, response)));
				float field_ex = max(field_lum, 0.0) * ex;
				float field_tone = clamp((pow(field_ex / (1.0 + field_ex), 0.4545) - tone_lo) / (tone_hi - tone_lo), 0.0, 1.0);
				print_colour = mix(print_colour, paper, (1.0 - smoothstep(res_k, 1.5 * res_k, distance_px)) * gate);
				float bright = mix(smoothstep(0.72, 0.80, field_tone), 1.0, star_keyline_all);
				print_colour = mix(print_colour, ink_col, ring * bright * gate);
			}
		}
	}
	ALBEDO = mix(print_colour, paper, bead);
}
