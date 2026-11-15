extends RefCounted
## Style audition (docs/design/SLICE_PRINCIPE.md, Owner direction 2026-11-16).
## --style=<id> selects a look; --style-set overrides its float parameters.

const STYLES := {"silver": "res://scripts/styles/silver.gd", "poster": "res://scripts/styles/poster.gd", "engraving": "res://scripts/styles/engraving.gd"}
const QUAD_GROUP := "style_quad"
const LookPost := preload("res://scripts/look_post.gd")

var id := ""
var impl: RefCounted
var params := {}
var quad_material: ShaderMaterial


static func arg_errors(style_id: String, overrides: String) -> PackedStringArray:
	if not STYLES.has(style_id):
		return PackedStringArray(["style=" + style_id])
	var defaults: Dictionary = load(STYLES[style_id]).PARAMS
	var errors := PackedStringArray()
	for pair in overrides.split(",", false):
		var parts := pair.split("=")
		if parts.size() != 2 or not defaults.has(parts[0]) or not parts[1].is_valid_float():
			errors.append(pair)
	return errors


static func from_args(args: Dictionary) -> RefCounted:
	if not args.has("style"):
		return null
	var style_id := str(args.style)
	var overrides := str(args.get("style-set", ""))
	var errors := arg_errors(style_id, overrides)
	for error in errors:
		printerr("STYLE ERROR: ignored ", error)
	if not STYLES.has(style_id):
		return null
	var style = load("res://scripts/style.gd").new()
	style.id = style_id
	style.impl = load(STYLES[style_id]).new()
	style.params = style.impl.PARAMS.duplicate()
	for pair in overrides.split(",", false):
		if pair not in errors:
			var parts := pair.split("=")
			style.params[parts[0]] = parts[1].to_float()
	return style


func apply(main: Node) -> void:
	impl.apply(main, self)
	dress_dialogue(main.ui)


func light(main: Node, contact: float, darkness: float, night: float) -> void:
	impl.light(main, self, contact, darkness, night)


func add_quad(main: Node, shader: Shader, uniforms := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.render_priority = RenderingServer.MATERIAL_RENDER_PRIORITY_MAX
	for k in params:
		m.set_shader_parameter(k, params[k])
	for k in uniforms:
		m.set_shader_parameter(k, uniforms[k])
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	var mi := MeshInstance3D.new()
	mi.name = "StyleQuad"
	mi.mesh = quad
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0
	mi.add_to_group(QUAD_GROUP)
	main.add_child(mi)
	quad_material = m
	return m


func each_material(root: Node, fn: Callable) -> void:
	var seen := {}
	var nodes: Array = [root]
	while not nodes.is_empty():
		var node: Node = nodes.pop_back()
		nodes.append_array(node.get_children())
		if node.is_in_group(QUAD_GROUP):
			continue
		var materials: Array = []
		if node is MeshInstance3D and node.mesh:
			for i in node.mesh.get_surface_count():
				materials.append(node.get_active_material(i))
		elif node is MultiMeshInstance3D:
			if node.material_override:
				materials.append(node.material_override)
			elif node.multimesh and node.multimesh.mesh:
				for i in node.multimesh.mesh.get_surface_count():
					materials.append(node.multimesh.mesh.surface_get_material(i))
		for material in materials:
			if material != null and not seen.has(material):
				seen[material] = true
				fn.call(material, node)


func set_post(main: Node, vignette: float, grain: float) -> void:
	var posts := main.find_children("*", "CanvasLayer", true, false)
	for post in posts:
		if post.is_in_group("look_post"):
			post.material.set_shader_parameter("vignette", vignette)
			post.material.set_shader_parameter("grain", grain)
			return
	var post := LookPost.new()
	post.setup(vignette, grain)
	main.add_child(post)


func dress_dialogue(ui: Node) -> void:
	var d: Dictionary = impl.DIALOGUE
	if d.has("panel") or d.has("border"):
		ui.dialog_panel.add_theme_stylebox_override("panel", ui._panel_style(d.get("panel", Color(0.07, 0.06, 0.05, 0.9)), d.get("border", Color(0.5, 0.4, 0.26))))
	if d.has("speaker"):
		ui.speaker_label.add_theme_color_override("font_color", d.speaker)
	if d.has("text"):
		ui.text_label.add_theme_color_override("default_color", d.text)
	if d.has("portrait"):
		ui.cambridge_portraits = true
		ui.dialogue_portrait.prints_override = {"Eddington": d.portrait}
	if d.has("mount") or d.has("mount_border"):
		var mount = ui.dialogue_portrait.get_theme_stylebox("panel").duplicate()
		if d.has("mount"):
			mount.bg_color = d.mount
		if d.has("mount_border"):
			mount.border_color = d.mount_border
		ui.dialogue_portrait.add_theme_stylebox_override("panel", mount)
