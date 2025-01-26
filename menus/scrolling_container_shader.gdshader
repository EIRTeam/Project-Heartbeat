shader_type canvas_item;

uniform int fade_size = 50;

uniform float fade_left_amount = 0.0;
uniform float fade_right_amount = 0.0;
uniform vec2 position;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec4 c = texture(screen_texture, SCREEN_UV);
	
	float fade_size_l = float(fade_size) * SCREEN_PIXEL_SIZE.x * fade_left_amount;
	float fade_size_r = float(fade_size) * SCREEN_PIXEL_SIZE.x * fade_right_amount;
	
	vec2 pos_on_screen = vec2(COLOR.r, COLOR.g);
	vec2 pos_on_screen_uv = (vec4(pos_on_screen, 0.0, 0.0)).rg * SCREEN_PIXEL_SIZE;
	float fade_mask_l = smoothstep(0.0, COLOR.r, UV.x);
	float fade_mask_r = COLOR.g > 0.0 ? smoothstep(1.0, 1.0 - COLOR.g, UV.x) : 1.0;
	
	COLOR = texture(screen_texture, SCREEN_UV);
	COLOR.a *= fade_mask_l * fade_mask_r;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
