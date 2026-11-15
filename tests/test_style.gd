extends SceneTree

const Style := preload("res://scripts/style.gd")
const Bench := preload("res://tests/benchmark.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func _run() -> void:
	check(Style.arg_errors("nope", "")[0] == "style=nope", "unknown style")
	check(Style.arg_errors("silver", "bogus=1,vignette=abc,novalue").size() == 3, "bad pairs")
	check(Style.arg_errors("silver", "vignette=0.4").is_empty(), "valid pair")
	check(Style.arg_errors("silver", "").is_empty(), "empty pairs")
	check(Style.from_args({}) == null, "no style")
	var style = Style.from_args({"style": "silver", "style-set": "vignette=0.4"})
	check(style.id == "silver" and style.params.vignette is float and is_equal_approx(style.params.vignette, 0.4) and style.params.grain == 0.03, "overrides")
	check(Style.from_args({"style": "nope"}) == null, "unknown returns null")
	for id in Style.STYLES:
		var impl = load(Style.STYLES[id]).new()
		check(impl.PARAMS is Dictionary and impl.DIALOGUE is Dictionary and impl.has_method("apply") and impl.has_method("light"), id + " interface")
	var tree := Node3D.new()
	root.add_child(tree)
	var material := style.add_quad(tree, load("res://shaders/look_post.gdshader"), {"grain": 0.6})
	var quad := tree.get_node("StyleQuad") as MeshInstance3D
	check(quad.is_in_group(Style.QUAD_GROUP) and material.render_priority == RenderingServer.MATERIAL_RENDER_PRIORITY_MAX, "quad")
	check(is_equal_approx(material.get_shader_parameter("vignette"), 0.4) and is_equal_approx(material.get_shader_parameter("grain"), 0.6), "quad uniforms")
	var shared := StandardMaterial3D.new()
	var override := StandardMaterial3D.new()
	var multi_mat := StandardMaterial3D.new()
	for i in 3:
		var mesh := BoxMesh.new()
		mesh.material = shared
		var node := MeshInstance3D.new()
		node.mesh = mesh
		if i == 2:
			node.set_surface_override_material(0, override)
		tree.add_child(node)
	var multi := MultiMeshInstance3D.new()
	multi.multimesh = MultiMesh.new()
	multi.multimesh.mesh = BoxMesh.new()
	multi.material_override = multi_mat
	tree.add_child(multi)
	var visited := []
	style.each_material(tree, func(m, _n): visited.append(m))
	check(visited.size() == 3 and shared in visited and override in visited and multi_mat in visited, "distinct materials and quad skipped")
	tree.free()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game._style == null and get_nodes_in_group(Style.QUAD_GROUP).is_empty(), "default unchanged")
	game._style = Style.from_args({"style": "silver"})
	game._style.apply(game)
	var posts := get_nodes_in_group("look_post")
	check(posts.size() == 1 and is_equal_approx(posts[0].material.get_shader_parameter("vignette"), 0.22), "post")
	game._apply_light(0.62, 0.0, -150.0, 0.0)
	check(game.ui.dialogue_portrait.prints_override.has("Eddington"), "portrait")
	check(get_nodes_in_group("ground").size() == 1 and get_nodes_in_group("npc").size() == 2, "world groups")
	game.free()
	var bench = Bench.new()
	bench.only = PackedStringArray(["arrival", "dialogue"])
	var shots: Array = bench._shots(Bench.BOOKMARKS)
	check(shots.size() == 2 and shots[0][0] == "arrival" and shots[1][0] == "dialogue", "audition selection")
	bench.only = PackedStringArray()
	check(bench._shots(Bench.BOOKMARKS) == Bench.BOOKMARKS, "default selection")
	bench.free()
	print("test_style: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
