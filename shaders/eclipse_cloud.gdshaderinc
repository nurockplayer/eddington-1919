// Shared presentation cloud: sky light, engraved burst and Moon ink.
float eclipse_middle_band_distance(vec2 plane, float elapsed) {
	vec2 sun_plane = sun_dir.xz / sun_dir.y * cloud_scale;
	vec2 along = normalize(wind);
	vec2 across = vec2(-along.y, along.x);
	vec2 offset = plane - sun_plane - 2.25 * wind * elapsed;
	float side = dot(offset, across);
	float scallop = 0.005 * (sin(side * 96.0) + 0.5 * sin(side * 211.0))
		* smoothstep(0.010, 0.034, abs(side));
	vec2 island = vec2((dot(offset, along) + 0.006 + scallop) / 0.020, side / 0.048);
	return 0.020 * (length(island) - 1.0);
}

float eclipse_middle_band_cover(float distance_to_band, float elapsed) {
	return (1.0 - smoothstep(-0.001, 0.001, distance_to_band)) * (1.0 - smoothstep(7.0, 9.0, abs(elapsed)));
}

float eclipse_middle_band(vec2 plane, float time, float density) {
	float elapsed = time - middle_seam_time;
	if (practice_cloud >= 0.0 || before_second_contact || night > 0.5 || abs(elapsed) >= 9.0) {
		return density;
	}
	float cover = eclipse_middle_band_cover(eclipse_middle_band_distance(plane, elapsed), elapsed);
	return mix(density, max(density, 0.93), cover);
}

float eclipse_cloud_texture(vec3 d, float time) {
	vec2 plane = d.xz / max(d.y, 0.06) * cloud_scale;
	return texture(cloud_tex, plane - wind * time).r;
}

float third_contact_cloud_gap(vec3 d, float time) {
	vec3 tangent = normalize(cross(sun_dir, vec3(0.0, 1.0, 0.0)));
	vec2 local_sun = vec2(dot(d, tangent), dot(d, cross(tangent, sun_dir))) / sun_r;
	float elapsed = (time - third_contact_cloud_clock.x) / (time < third_contact_cloud_clock.x ? third_contact_cloud_clock.y : third_contact_cloud_clock.z);
	vec2 offset = local_sun - vec2(1.25 * elapsed - 0.86, 0.0);
	float pocket = 1.0 - smoothstep(1.1, 3.65, length(offset * vec2(1.0, 1.25)));
	return pocket * (1.0 - smoothstep(3.5, 5.0, length(local_sun)));
}

vec2 eclipse_cloud_sample_at(vec3 d, float time, bool include_middle_band) {
	float h = d.y;
	float dens = 0.0;
	if (h > 0.0) {
		dens = eclipse_cloud_texture(d, time);
		if (include_middle_band) {
			dens = eclipse_middle_band(d.xz / max(h, 0.06) * cloud_scale, time, dens);
		}
		dens = mix(dens, 0.97, smoothstep(0.35, 0.05, h));   // haze toward horizon
	} else {
		dens = 1.0;
	}
	if (practice_cloud >= 0.0 && h > 0.0) {
		// Rehearsal fixes the density at the Sun. The drifting field still
		// supplies the shape and density variation around it.
		float near_practice_sun = smoothstep(0.96, 0.999, dot(d, sun_dir));
		float variation = (dens - eclipse_cloud_texture(sun_dir, time)) * smoothstep(0.0, 0.12, practice_cloud);
		float rehearsal_density = clamp(practice_cloud + variation, 0.0, 1.0);
		dens = mix(dens, rehearsal_density, near_practice_sun);
	}
	float gap = 0.0;
	if (practice_cloud < 0.0 && night < 0.5 && dot(d, sun_dir) > 0.98) {
		gap = third_contact_cloud_gap(d, time);
	}
	return vec2(mix(dens, dens * 0.55, night), gap);
}

vec2 eclipse_cloud_sample_at(vec3 d, float time) {
	return eclipse_cloud_sample_at(d, time, true);
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
