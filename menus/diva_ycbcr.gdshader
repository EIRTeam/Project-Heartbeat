shader_type canvas_item;

uniform sampler2D texture_ya;
uniform sampler2D texture_cbcr;

const mat4 transform = mat4(
	vec4(1.0000, 1.0000, 1.0000, 0.0000),
	vec4(0.0000, -0.3441, 1.7720, 0.0000),
	vec4(1.4020, -0.7141, 0.0000, 0.0000),
	vec4(-0.7010, 0.5291, -0.8860, 1.0000)
);


void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	vec4 ycbcr = vec4(texture(texture_ya, uv).r, texture(texture_cbcr, uv).rg, 1.0);
	COLOR = transform * ycbcr;
    COLOR.a = texture(texture_ya, uv).g;
}