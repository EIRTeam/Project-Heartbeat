shader_type canvas_item;

uniform float antialias_amount = 0.5;

uniform vec4 trail_color : source_color;
uniform vec4 color_start : source_color;
uniform vec4 color_end : source_color;
uniform float leading = 0.0;
uniform float time = 0.5;
uniform float trail_margin = 0.0;
uniform float duration = 0.2;
uniform float trail_position;
//uniform  wave_duration;

float get_A(float t) {
	return t;
}

float remap(float value, float low1, float low2, float high1, float high2) {
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1);
}

void fragment() {
	// 0.8 is calculated diving how much of the trail is used before the timing point time
	// and how much tim there is in total in the tail, so if the tail is 2.0 + 0.5 of late
	// tail then it's 0.8.....
	float t = remap(time / 2.0, 0.0, 0.0, 1.0, 0.888) + (0.888 / 2.0);
	float t_rear = remap((trail_position) / 2.0, 0.0, 0.0, 1.0, 0.888) + (0.888 / 2.0);
	float tail_length = 0.444 * 0.5;
	vec4 color = texture(TEXTURE, UV);
	vec4 col = color;
	float trail_mid = step(0.36, UV.y) * step(UV.y, 1.0 - 0.36);
	float visible = step(UV.x, t) * (1.0 - step(UV.x, t_rear));
	COLOR = col * trail_mid * trail_color * visible;
    COLOR += col * (1.0 - trail_mid) * visible;
}