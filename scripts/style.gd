extends RefCounted
## The default Príncipe engraving look; --style-set overrides float parameters.
## Preserve main's existing --no-grade comparison interface.

const Engraving := preload("res://scripts/styles/engraving.gd")
const QUAD_GROUP := "style_quad"
const LookPost := preload("res://scripts/look_post.gd")

var id := "engraving"
var impl: RefCounted
var params := {}
var label_darkness := 0.0
var label_night := 0.0
var quad_material: ShaderMaterial


static func arg_errors(overrides: String) -> PackedStringArray:
	var defaults: Dictionary = Engraving.PARAMS
	var errors := PackedStringArray()
	for pair in overrides.split(",", false):
		var parts := pair.split("=")
		if parts.size() != 2 or not defaults.has(parts[0]) or not parts[1].is_valid_float():
			errors.append(pair)
	return errors


static func from_args(args: Dictionary) -> RefCounted:
	if args.has("no-grade"):
		return null
	var overrides := str(args.get("style-set", ""))
	var errors := arg_errors(overrides)
	for error in errors:
		printerr("STYLE ERROR: ignored ", error)
	var style = load("res://scripts/style.gd").new()
	style.impl = Engraving.new()
	style.params = style.impl.PARAMS.duplicate()
	for pair in overrides.split(",", false):
		if pair not in errors:
			var parts := pair.split("=")
			style.params[parts[0]] = parts[1].to_float()
	return style


func apply(main: Node) -> void:
	impl.apply(main, self)
	dress_dialogue(main.ui)
	for label in main.find_children("*", "Label3D", true, false):
		print_label(label)
	main.get_tree().node_added.connect(_node_added.bind(main))
	main.world.sun_crescents.material_override.shader = preload("res://shaders/sun_crescent_print.gdshader")
	main.world.sun_crescents.material_override.set_shader_parameter("print_paper", Engraving.PAPER)
	main.world.sun_crescents.material_override.set_shader_parameter("print_ink", Engraving.INK)
	var firefly_ramp: Gradient = main.world.fireflies.color_ramp
	for i in firefly_ramp.get_point_count():
		firefly_ramp.set_color(i, Color(Engraving.PAPER, firefly_ramp.get_color(i).a))


func _node_added(node: Node, main: Node) -> void:
	if node is Label3D and main.is_ancestor_of(node):
		print_label.call_deferred(node)


func print_label(label: Label3D) -> void:
	label.modulate = Engraving.INK.lerp(Color(0.16, 0.13, 0.11), maxf(label_darkness, label_night))
	label.outline_modulate = Engraving.PAPER.lerp(Color(0.17, 0.21, 0.40), label_darkness).lerp(Color(0.07, 0.08, 0.16), label_night)
	label.outline_size = maxi(label.outline_size, 4)


func light(main: Node, contact: float, darkness: float, night: float) -> void:
	impl.light(main, self, contact, darkness, night)
	label_darkness = darkness
	label_night = night
	for label in main.find_children("*", "Label3D", true, false):
		print_label(label)


func add_quad(main: Node, shader: Shader, uniforms := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.render_priority = RenderingServer.MATERIAL_RENDER_PRIORITY_MIN
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
