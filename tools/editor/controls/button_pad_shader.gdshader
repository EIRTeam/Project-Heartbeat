shader_type canvas_item;

uniform bool hover = false;
uniform vec2 highlight_pos = vec2(1, 1);

void fragment() {
	if (hover) {
		float blending_factor = pow(UV.x - highlight_pos.x, 2.0) + pow(UV.y - highlight_pos.y, 2.0);
		
		COLOR = COLOR + vec4(1, 1, 1, 1) * max(0.15 - blending_factor, 0.0);
	}
}