// Shared presentation cloud: sky light, engraved burst and Moon ink.
float eclipse_cloud_texture(vec3 d, float time) {
	vec2 plane = d.xz / max(d.y, 0.06);
	return texture(cloud_tex, plane * cloud_scale - wind * time).r;
}

float third_contact_cloud_gap(vec3 d, float time) {
	vec3 tangent = normalize(cross(sun_dir, vec3(0.0, 1.0, 0.0)));
	vec2 local_sun = vec2(dot(d, tangent), dot(d, cross(tangent, sun_dir))) / sun_r;
	float elapsed = (time - third_contact_cloud_clock.x) / (time < third_contact_cloud_clock.x ? third_contact_cloud_clock.y : third_contact_cloud_clock.z);
	vec2 offset = local_sun - vec2(1.25 * elapsed - 0.86, 0.0);
	float pocket = 1.0 - smoothstep(1.1, 3.65, length(offset * vec2(1.0, 1.25)));
	return pocket * (1.0 - smoothstep(3.5, 5.0, length(local_sun)));
}

vec2 eclipse_cloud_sample_at(vec3 d, float time) {
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
	float gap = 0.0;
	if (practice_cloud < 0.0 && night < 0.5 && dot(d, sun_dir) > 0.98) {
		gap = third_contact_cloud_gap(d, time);
	}
	return vec2(mix(dens, dens * 0.55, night), gap);
}

float eclipse_cloud_density_from_sample(vec2 cloud) {
	return mix(cloud.x, min(cloud.x, 0.22), cloud.y);
}

float eclipse_cloud_density_at(vec3 d, float time) {
	return eclipse_cloud_density_from_sample(eclipse_cloud_sample_at(d, time));
}

float eclipse_cloud_density(vec3 d) {
	return eclipse_cloud_density_at(d, cloud_time);
}
