shader_type canvas_item;

uniform float antialias_amount = 0.5;

uniform vec4 color_start : source_color;
uniform vec4 color_end : source_color;
uniform float leading = 0.0;
uniform float time = 0.5;
uniform float trail_margin = 0.0;
uniform float texture_scale = 1.0;
//uniform  wave_duration;

vec4 get_color(float t) {
	return mix(color_start, color_end, clamp(t, 0.0, 1.0));
}

float remap(float value, float low1, float low2, float high1, float high2) {
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

void fragment() {
	// 0.8 is calculated diving how much of the trail is used before the timing point time
	// and how much tim there is in total in the tail, so if the tail is 2.0 + 0.5 of late
	// tail then it's 0.8.....
	float t = remap(time / 2.0, 0.0, 0.0, 1.0, 0.888) + (0.888 / 2.0);
	float t_m = remap((time + (trail_margin * 2.0)) / 2.0, 0.0, 0.0, 1.0, 0.888) + (0.888 / 2.0);
	float tail_length = 0.444 * 0.5;
	vec2 u = UV;
	u.x = u.x * texture_scale;
	vec4 color = texture(TEXTURE, u) * get_color(remap(UV.x, t, 0.0, t-tail_length, 1.0));
	vec4 col = color;
	COLOR = col * mix(0.0, 1.0, step(UV.x, t));
	col.a = col.a * 0.5;
	COLOR += col * mix(0.0, 1.0, step(t_m, UV.x) * step(UV.x, 1.0 - 0.2222/2.0)) * leading;
}