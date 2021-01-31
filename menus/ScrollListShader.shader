shader_type canvas_item;

uniform vec2 pos;
uniform vec2 size;
uniform bool enabled;
uniform float fade_size;
float remap(float value, float low1, float low2, float high1, float high2) {
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

void fragment() {
	COLOR = COLOR * texture(TEXTURE, UV);
	if (enabled) {
		vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
		float start = pos.y / res.y;
		float end = (pos.y + size.y) / res.y;

		float remapped_y = remap(SCREEN_UV.y, start, 0.0, end, 1.0);

		COLOR.a = COLOR.a * smoothstep(0.0, fade_size, remapped_y);
		COLOR.a = COLOR.a * smoothstep(1.0, 1.0-fade_size, remapped_y);
		if (COLOR.a == 0.0) {
			discard;
		}
	}
}