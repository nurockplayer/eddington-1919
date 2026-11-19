extends RefCounted
## Style audition: engraving (docs/design/SLICE_PRINCIPE.md, 2026-11-16 JST).
## Ink on paper. The pass in shaders/style_engraving.gdshader draws everything;
## this script gives it a frame with a clear key, hard shadows and no grade.

const SHADER := preload("res://shaders/style_engraving.gdshader")

## Every key is a float and can be overridden with --style-set. Keys listed in
## UNIFORMS are shader uniforms of the same name; the others are read here.
const PARAMS := {
	"exposure": 2.2, "totality_gain": 1.5, "night_gain": 3.0,
	"resp_r": 0.60, "resp_g": 0.55, "resp_b": -0.15,
	"tone_lo": 0.10, "tone_hi": 0.80, "sky_ink": 0.80, "sky_gain": 0.4,
	"diamond_radius": 0.45, "diamond_spikes": 4.0, "diamond_rays": 1.0, "diamond_ray_floor": 0.70,
	"line_px": 5.0, "ray_px": 5.0, "ray_inner": 3.0, "ray_outer": 8.0,
	"cross_at": 0.34, "third_at": 0.62, "solid_lo": 0.92, "solid_hi": 0.99, "flat_at": 0.92,
	"outline": 1.0, "outline_px": 1.3, "edge_depth": 0.02, "edge_normal": 0.18, "far_outline": 0.35,
	"wobble": 1.0, "wobble_rel": 0.35, "tone_lod": 0.0,
	"far_start": 25.0, "far_end": 70.0, "far_floor": 0.28, "far_cap": 0.55, "far_tot": 0.75, "far_lod": 2.5, "far_edge": 0.35, "ground_cap": 0.60, "ground_rule": 1.0, "ground_mottle": 0.7, "ground_grain": 2.0, "ground_edge": 0.85,
	"far_line": 0.0, "far_sky": 0.40, "far_step": 0.16, "far_in": 0.25, "wash_far": 0.4, "sky_horizon": 0.5, "sky_horizon_h": 0.45,
	"wash": 0.35, "wash_depth": 0.0, "wash_floor": 0.25, "tot_wash": 1.0, "heighten_lo": 0.55, "heighten_hi": 0.85, "night_wash": 1.0, "paper_grain": 0.05, "ink_strength": 0.94, "normal_from_depth": 0.0,
	"sun_floor": 0.9, "sun_gain": 1.8, "ambient": 0.45, "shadow_blur": 0.4, "sun_angle": 0.3,
	"ssao": 1.0, "fog_density": 0.006, "vignette": 0.12, "fov": 60.0,
}
const UNIFORMS := [
	"exposure", "totality_gain", "night_gain", "resp_r", "resp_g", "resp_b", "tone_lo", "tone_hi",
	"sky_ink", "sky_gain", "diamond_radius", "diamond_spikes", "diamond_rays", "diamond_ray_floor", "line_px", "ray_px", "ray_inner", "ray_outer", "cross_at", "third_at", "solid_lo",
	"solid_hi", "flat_at", "outline", "outline_px", "edge_depth", "edge_normal", "far_outline",
	"wobble", "wobble_rel", "tone_lod", "far_start", "far_end", "far_floor", "far_cap", "far_tot", "far_lod", "far_edge", "ground_cap", "ground_rule", "ground_mottle", "ground_grain", "ground_edge",
	"far_line", "far_sky", "far_step", "far_in", "wash_far", "sky_horizon", "sky_horizon_h",
	"wash", "wash_depth", "wash_floor", "tot_wash", "heighten_lo", "heighten_hi", "night_wash", "paper_grain", "ink_strength", "normal_from_depth",
]
const PAPER := Color("efe6d2")
const INK := Color("221c18")
# The shader's existing page colours, shared with in-play print furniture.
const PAGES := {
	"paper": PAPER, "ink_col": INK,
	"tot_paper": Color(0.17, 0.21, 0.40),
	"night_paper": Color(0.07, 0.08, 0.16),
	"safe_paper": Color(0.42, 0.10, 0.07),
	"safe_light": Color(0.96, 0.62, 0.45),
}
const HudPaper := preload("res://scripts/hud_paper.gd")
var hud_paper := HudPaper.new()

const DIALOGUE := {
	"portrait": "res://assets/portraits/eddington_engraving.jpg",
	"panel": Color(0.937, 0.902, 0.824, 0.97), "border": INK,
	"speaker": INK, "text": INK,
	"mount": PAPER, "mount_border": INK,
}


func apply(main: Node, style: RefCounted) -> void:
	var p: Dictionary = style.params
	var env: Environment = main.env
	# The pass writes final colours: nothing may grade or bloom them afterwards.
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = false
	env.glow_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false
	env.ssao_enabled = p.ssao > 0.5
	env.fog_density = p.fog_density
	# Settings.apply_quality() restores these three from the node's metas.
	for we in main.get_tree().get_nodes_in_group("quality_env"):
		we.set_meta("standard_ssao", env.ssao_enabled)
		we.set_meta("standard_sdfgi", false)
		we.set_meta("standard_volumetric_fog", false)
	main.sun.light_angular_distance = p.sun_angle
	main.sun.shadow_blur = p.shadow_blur
	if not main._look.is_empty():
		main._look["sun_floor"] = p.sun_floor
	main._look_sun = p.sun_gain
	main._look_ambient = p.ambient
	main.player.camera.fov = p.fov
	var uniforms := PAGES.duplicate()
	uniforms.merge({"sun_dir": main.sim.sun_dir, "sun_r": main.sim.SUN_R})
	style.add_quad(main, SHADER, uniforms)
	hud_paper.setup(main.ui, PAGES)
	style.set_post(main, p.vignette, 0.0)


func light(_main: Node, style: RefCounted, _contact: float, darkness: float, night: float) -> void:
	if style.quad_material == null:
		return
	hud_paper.light(darkness, night, style.params)
	style.quad_material.set_shader_parameter("darkness", darkness)
	style.quad_material.set_shader_parameter("night", night)
