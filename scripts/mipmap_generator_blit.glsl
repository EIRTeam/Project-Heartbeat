#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform sampler2D tex_source;
layout(rgba8, set = 0, binding = 1) uniform restrict writeonly image2D output_image;

layout(push_constant, std430) uniform Params {
    vec2 level_size;
    float flip_y;
    float padding;
} params;

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	vec2 sample_uv = uv / params.level_size;
	vec4 sample_value = texture(tex_source, sample_uv);
	if (params.flip_y > 0.0) {
		uv.y = int(params.level_size.y) - 1 - uv.y; 
	}
	imageStore(output_image, uv, sample_value);
}
