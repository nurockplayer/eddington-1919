shader_type canvas_item;
uniform vec4 ink : source_color;

void fragment() {
	COLOR = vec4(ink.rgb, COLOR.a);
}
