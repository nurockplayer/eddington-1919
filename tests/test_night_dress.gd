extends SceneTree
## Príncipe linen stays darker than skin under the night safelight.
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _surfaces(figure: Node, material_name: String) -> Array:
	var found := []
	for mi in figure.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		for i in mesh.get_surface_count():
			var source := mesh.surface_get_material(i) as BaseMaterial3D
			if source != null and source.resource_name == material_name:
				found.append({"instance": mi, "index": i, "source": source, "active": mi.get_active_material(i)})
	return found


func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main.set_process(false)
	var figures := [main.world.eddington, main.world.cottingham]
	var linen_by_figure := []
	var skin_by_figure := []
	for figure in figures:
		var linens := _surfaces(figure, "E1919_linen")
		var skins := _surfaces(figure, "E1919_skin")
		check(not linens.is_empty(), "%s has E1919_linen" % figure.name)
		check(not skins.is_empty(), "%s has E1919_skin" % figure.name)
		for item in linens:
			check(item.active == item.source, "%s linen initially uses its mesh material" % figure.name)
			item["color"] = item.source.albedo_color
		for item in skins:
			item["color"] = item.active.albedo_color
		linen_by_figure.append(linens)
		skin_by_figure.append(skins)
	main._begin_night()
	for i in 600:
		if main.world.eddington.position == main.world.eddington_night:
			break
		await process_frame
	check(main.world.eddington.position == main.world.eddington_night, "night transition reaches Eddington's darkroom position")
	for figure_index in figures.size():
		var figure: Node = figures[figure_index]
		for item in linen_by_figure[figure_index]:
			var active := item.instance.get_active_material(item.index) as BaseMaterial3D
			check(active != null and active.albedo_color.r <= item.source.albedo_color.r * 0.6, "%s night linen is at most 60%% of source red" % figure.name)
			check(item.source.albedo_color == item.color, "%s source linen material is unchanged" % figure.name)
		for item in skin_by_figure[figure_index]:
			var active := item.instance.get_active_material(item.index) as BaseMaterial3D
			check(active == item.active and active.albedo_color == item.color, "%s skin surface is unchanged" % figure.name)
	print("%d night dress checks, %d failures" % [checks, failures])
	main.queue_free()
	await process_frame
	quit(1 if failures else 0)
