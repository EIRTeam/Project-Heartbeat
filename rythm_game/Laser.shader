shader_type canvas_item;

const float fade_distance = 0.30;

float remap(float value, float low1, float low2, float high1, float high2) {
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

void fragment() {
	vec2 uv = UV;
	uv.x = uv.x + TIME;
	COLOR = texture(TEXTURE, uv);
	
	float fade_distance_inv = 1.0 - fade_distance;
	
	float remapped_a = remap(1.0 - UV.x, fade_distance_inv, 0.0, 1.0, 1.0);
	float remapped_a_end = remap(UV.x, fade_distance_inv, 0.0, 1.0, 1.0);
	
	COLOR.a -= step(UV.x, fade_distance) * remapped_a;
	COLOR.a -= step(fade_distance_inv, UV.x) * remapped_a_end;
	COLOR.a = clamp(COLOR.a, 0.0, 1.0);
}