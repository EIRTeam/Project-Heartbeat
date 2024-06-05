shader_type canvas_item;

render_mode skip_vertex_transform;

uniform vec2 size;
uniform vec2 global_position;

void vertex() {
	POINT_SIZE = 3.0;
	mat4 mat = MODEL_MATRIX;
	mat[3] -= vec4(global_position.x, global_position.y, 0.0, 0.0);

	mat[3][0] *= size.x;
	mat[3][1] *= size.y;
	mat[3][0] += global_position.x;
	mat[3][1] += global_position.y;

    VERTEX = (mat * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
