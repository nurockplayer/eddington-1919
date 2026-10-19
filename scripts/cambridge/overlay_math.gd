extends RefCounted
## Geometry for the 1917 plate overlay. Coordinates are normalized around the
## plate centre; positive Y points down, as it does in Godot's 2D canvas.

const SOURCE_TILT_DEG := 3.2
const SPECK := Vector2(0.315, -0.295)


static func star_points() -> Array[Vector2]:
	return [
		Vector2(-0.365, -0.255), Vector2(-0.292, -0.105), Vector2(-0.238, 0.236),
		Vector2(-0.188, -0.322), Vector2(-0.142, 0.058), Vector2(-0.093, 0.324),
		Vector2(-0.044, -0.191), Vector2(0.018, 0.125), Vector2(0.067, -0.338),
		Vector2(0.108, 0.267), Vector2(0.157, -0.065), Vector2(0.203, 0.342),
		Vector2(0.246, -0.229), Vector2(0.284, 0.105), Vector2(0.328, -0.015),
		Vector2(-0.324, 0.332), Vector2(0.013, -0.018),
	]


static func copy_points() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for point in star_points():
		result.append(_source_copy_point(point))
	# The extra ink dot sits over the pale plate speck when the tracing is aligned.
	result.append(_source_copy_point(SPECK))
	return result


static func transformed_copy(flipped: bool, angle_deg: float, offset: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var angle := deg_to_rad(angle_deg)
	for source_point in copy_points():
		var point := source_point
		if flipped:
			point.x = -point.x
		point = point.rotated(angle) + offset
		result.append(point)
	return result


static func match_count(points: Array, tolerance: float = 0.008) -> int:
	var remaining := star_points()
	var matches := 0
	for point in points:
		var nearest_index := -1
		var nearest_distance := tolerance
		for i in remaining.size():
			var distance := (point as Vector2).distance_to(remaining[i])
			if distance <= nearest_distance:
				nearest_distance = distance
				nearest_index = i
		if nearest_index >= 0:
			remaining.remove_at(nearest_index)
			matches += 1
	return matches


static func alignment(flipped: bool, angle_deg: float, offset: Vector2) -> bool:
	var rotation_error := wrapf(angle_deg - SOURCE_TILT_DEG, -180.0, 180.0)
	if not flipped or absf(rotation_error) >= 0.6 or offset.length() > 0.025:
		return false
	return match_count(transformed_copy(flipped, angle_deg, offset), 0.03) == 17


static func speck_point() -> Vector2:
	return SPECK


static func _source_copy_point(plate_point: Vector2) -> Vector2:
	var mirrored := Vector2(-plate_point.x, plate_point.y)
	return mirrored.rotated(deg_to_rad(SOURCE_TILT_DEG))
