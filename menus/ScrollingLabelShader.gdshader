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
		float start = pos.x / res.x;
		float end = (pos.x + size.x) / res.x;

		float remapped_x = remap(POINT_COORD.x, start, 0.0, end, 1.0);

		COLOR.a = COLOR.a * smoothstep(0.0, fade_size, remapped_x);
		COLOR.a = COLOR.a * smoothstep(1.0, 1.0-fade_size, remapped_x);
	}

}