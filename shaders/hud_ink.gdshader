shader_type canvas_item;

uniform vec4 source_ink : source_color;
uniform vec4 light_ink : source_color;
uniform vec4 dark_ink : source_color;
uniform float progress;
varying vec3 draw_color;

void vertex() {
	draw_color = COLOR.rgb;
}

void fragment() {
	// Glyphs can share a draw item with the paper and its rules.
	if (all(lessThan(abs(draw_color - source_ink.rgb), vec3(0.001)))) {
		COLOR.rgb = SCREEN_UV.x < progress ? dark_ink.rgb : light_ink.rgb;
	}
}
