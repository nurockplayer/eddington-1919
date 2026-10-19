extends RefCounted
## Era look (art/BIBLE.md §5): the 1919 "plate grade". The Painted Diorama
## forms carry the series identity; this grade carries the era. It nudges the
## image toward a toned glass-plate print by slightly desaturating, warming the
## shadows (sepia) and leaving highlights neutral-cool, so the evidence whites
## (Sun, corona, plates) stay clean. Kept subtle on purpose: totality must stay
## readable.
##
## Disable for A/B comparisons with the user arg --no-grade.

const SATURATION := 0.86
const CONTRAST := 1.04


static func apply_grade(env: Environment) -> void:
	env.adjustment_enabled = true
	env.adjustment_saturation = SATURATION
	env.adjustment_contrast = CONTRAST
	# Per-channel 1D LUT (input value → output value for R, G, B independently).
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.18, 0.5, 0.85, 1.0])
	g.colors = PackedColorArray([
		Color(0.015, 0.008, 0.0),
		Color(0.200, 0.176, 0.150),   # sepia-warm shadows
		Color(0.510, 0.497, 0.474),   # warm midtones
		Color(0.850, 0.850, 0.856),   # neutral-cool highlights
		Color(1.0, 1.0, 1.0),
	])
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 256
	env.adjustment_color_correction = tex
