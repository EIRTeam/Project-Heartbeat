shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec2 pos;
uniform vec2 size;
uniform bool enabled;
uniform float top_enabled = 1.0;
uniform float bottom_enabled = 1.0;
uniform float fade_size;
float remap(float value, float low1, float low2, float high1, float high2) {
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

void fragment() {
	COLOR = texture(screen_texture, SCREEN_UV);
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	float screen_pos_y = CANVAS_COORD.y;
	float remapped = clamp(remap(screen_pos_y, pos.y, 0, pos.y+size.y, 1.0), 0.0, 1.0);
	float fade_s = fade_size * (1.0 / float(size.y));
	COLOR.a = mix(COLOR.a, COLOR.a * smoothstep(0.0, fade_s, remapped), top_enabled);
	COLOR.a = mix(COLOR.a, COLOR.a * smoothstep(1.0, 1.0 - fade_s, remapped), bottom_enabled);
}