// Shared presentation cloud: sky light, engraved burst and Moon ink.
float eclipse_cloud_texture(vec3 d) {
	vec2 plane = d.xz / max(d.y, 0.06);
	return texture(cloud_tex, plane * cloud_scale - wind * cloud_time).r;
}

float eclipse_cloud_density(vec3 d) {
	float h = d.y;
	float dens = 0.0;
	if (h > 0.0) {
		dens = eclipse_cloud_texture(d);
		dens = mix(dens, 0.97, smoothstep(0.35, 0.05, h));   // haze toward horizon
	} else {
		dens = 1.0;
	}
	if (practice_cloud >= 0.0 && h > 0.0) {
		// Rehearsal fixes the density at the Sun. The drifting field still
		// supplies the shape and density variation around it.
		float near_practice_sun = smoothstep(0.96, 0.999, dot(d, sun_dir));
		float variation = (dens - eclipse_cloud_texture(sun_dir)) * smoothstep(0.0, 0.12, practice_cloud);
		dens = clamp((practice_cloud + variation) * near_practice_sun, 0.0, 1.0);
	}
	// Keep a visible veil, opening only near the Sun for the final beads/ring.
	float near_contact_sun = smoothstep(0.96, 0.995, dot(d, sun_dir));
	dens = mix(dens, min(dens, 0.55), third_contact_gap * near_contact_sun);
	dens = mix(dens, dens * 0.55, night);
	return dens;
}
