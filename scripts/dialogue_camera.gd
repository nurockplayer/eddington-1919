extends Camera3D

const DIST := 2.2
const ANGLE_DEG := 30.0
const FOV_V := 28.0
const EYE_UP := 0.0
const DOF_FAR := true

var other_npc: Node3D
var eye_point: Vector3

func frame(npc: Node3D, player_cam: Camera3D) -> void:
	eye_point = npc.global_position + Vector3(0, 1.55 + EYE_UP, 0)
	for node in npc.find_children("*", "Skeleton3D", true, false):
		var skeleton := node as Skeleton3D
		var head := skeleton.find_bone("head")
		if head >= 0:
			eye_point = skeleton.to_global(skeleton.get_bone_global_pose(head).origin) + Vector3.UP * EYE_UP
			break
	var direction := player_cam.global_position - eye_point
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		direction = -npc.global_basis.z
	direction = direction.normalized()
	var left := direction.rotated(Vector3.UP, deg_to_rad(ANGLE_DEG))
	var right := direction.rotated(Vector3.UP, -deg_to_rad(ANGLE_DEG))
	if other_npc and left.dot(other_npc.global_position - npc.global_position) > right.dot(other_npc.global_position - npc.global_position):
		var swap := left
		left = right
		right = swap
	var hit := _obstruction(npc, player_cam, left)
	if not hit.is_empty():
		var mirror_hit := _obstruction(npc, player_cam, right)
		if mirror_hit.is_empty():
			left = right
			hit = mirror_hit
	var distance := DIST
	if not hit.is_empty():
		distance = maxf(1.6, eye_point.distance_to(hit.position) - 0.2)
	global_position = eye_point + left * distance
	fov = FOV_V
	look_at(eye_point - Vector3.UP * (distance * tan(deg_to_rad(FOV_V / 2.0)) * 0.4), Vector3.UP)
	var lens := CameraAttributesPractical.new()
	lens.dof_blur_far_enabled = DOF_FAR
	lens.dof_blur_far_distance = distance + 0.6
	lens.dof_blur_far_transition = 1.0
	lens.dof_blur_near_enabled = false
	attributes = lens

func _obstruction(npc: Node3D, player_cam: Camera3D, direction: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(eye_point, eye_point + direction * DIST)
	var exclude: Array[RID] = []
	if npc is CollisionObject3D:
		exclude.append(npc.get_rid())
	if player_cam.get_parent() is CollisionObject3D:
		exclude.append(player_cam.get_parent().get_rid())
	query.exclude = exclude
	return get_world_3d().direct_space_state.intersect_ray(query)
