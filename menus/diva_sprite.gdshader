shader_type canvas_item;

varying flat vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;
	COLOR = modulate * texture(TEXTURE, uv);
}