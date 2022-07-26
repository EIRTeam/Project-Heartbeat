shader_type canvas_item;

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	COLOR = texture(TEXTURE, uv);
}