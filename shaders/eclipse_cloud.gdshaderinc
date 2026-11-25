// Shared presentation cloud: sky light, engraved burst and Moon ink.
float eclipse_cloud_texture(vec3 d, float time) {
	vec2 plane = d.xz / max(d.y, 0.06);
	return texture(cloud_tex, plane * cloud_scale - wind * time).r;
}

float eclipse_cloud_density_at(vec3 d, float time) {
	float h = d.y;
	float dens = 0.0;
	if (h > 0.0) {
		dens = eclipse_cloud_texture(d, time);
		dens = mix(dens, 0.97, smoothstep(0.35, 0.05, h));   // haze toward horizon
	} else {
		dens = 1.0;
	}
	if (practice_cloud >= 0.0 && h > 0.0) {
		// Rehearsal fixes the density at the Sun. The drifting field still
		// supplies the shape and density variation around it.
		float near_practice_sun = smoothstep(0.96, 0.999, dot(d, sun_dir));
		float variation = (dens - eclipse_cloud_texture(sun_dir, time)) * smoothstep(0.0, 0.12, practice_cloud);
		dens = clamp((practice_cloud + variation) * near_practice_sun, 0.0, 1.0);
	}
	return mix(dens, dens * 0.55, night);
}

float eclipse_cloud_density(vec3 d) {
	return eclipse_cloud_density_at(d, cloud_time);
}
