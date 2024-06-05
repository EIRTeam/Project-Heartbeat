shader_type canvas_item;

render_mode skip_vertex_transform;

varying vec2 model_og;

uniform sampler2D color_gradient_top : filter_nearest;
uniform sampler2D color_gradient_bottom : filter_nearest;
uniform vec2 size;
uniform vec2 global_position;

void vertex() {
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	model_og = (VERTEX - global_position) / size;
}

void fragment() {
	vec3 top = texture(color_gradient_top, vec2(model_og.x, 0.0)).rgb;
	vec3 bottom = texture(color_gradient_bottom, vec2(model_og.x, 0.0)).rgb;
	COLOR.rgb = mix(bottom, top, 1.0 - (model_og.y * model_og.y));
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
