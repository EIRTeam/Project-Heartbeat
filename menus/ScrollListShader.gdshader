shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec2 pos;
uniform vec2 size;
uniform bool enabled;
uniform bool top_enabled = true;
uniform bool bottom_enabled = true;
uniform float fade_size;
float remap(float value, float low1, float low2, float high1, float high2) {
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

void fragment() {
    vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);

    if (c.a > 0.0001) {
        c.rgb /= c.a;
    }

	if (enabled) {
		vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
		float start = pos.y / res.y;
		float end = (pos.y + size.y) / res.y;

		float remapped_y = remap(SCREEN_UV.y, start, 0.0, end, 1.0);
		if (top_enabled) {
			COLOR.a = COLOR.a * smoothstep(0.0, fade_size, remapped_y);
		}
		if (bottom_enabled) {
			COLOR.a = COLOR.a * smoothstep(1.0, 1.0-fade_size, remapped_y);
		}
		if (COLOR.a == 0.0) {
			discard;
		}
	}

    COLOR *= c;
}