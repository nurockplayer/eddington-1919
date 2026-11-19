// Shared presentation cloud: sky light, engraved burst and Moon ink.
float eclipse_cloud_density(vec3 d) {
	float h = d.y;
	float dens = 0.0;
	if (h > 0.0) {
		vec2 plane = d.xz / max(h, 0.06);
		vec2 uv = plane * cloud_scale - wind * cloud_time;
		dens = texture(cloud_tex, uv).r;
		dens = mix(dens, 0.97, smoothstep(0.35, 0.05, h));   // haze toward horizon
	} else {
		dens = 1.0;
	}
	if (practice_cloud >= 0.0 && h > 0.0) {
		float near_practice_sun = smoothstep(0.96, 0.995, dot(d, sun_dir));
		dens = mix(dens, practice_cloud, near_practice_sun);
	}
	// Keep a visible veil, opening only near the Sun for the final beads/ring.
	float near_contact_sun = smoothstep(0.96, 0.995, dot(d, sun_dir));
	dens = mix(dens, min(dens, 0.55), third_contact_gap * near_contact_sun);
	dens = mix(dens, dens * 0.55, night);
	return dens;
}
