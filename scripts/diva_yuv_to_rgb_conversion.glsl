#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Our textures
layout(set = 0, binding = 0) uniform sampler2D tex_ya;
layout(set = 0, binding = 1) uniform sampler2D tex_uv;
layout(rgba8, set = 0, binding = 2) uniform restrict writeonly image2D output_image;

const mat4 transform = mat4(
	vec4(1.0000, 1.0000, 1.0000, 0.0000),
	vec4(0.0000, -0.3441, 1.7720, 0.0000),
	vec4(1.4020, -0.7141, 0.0000, 0.0000),
	vec4(-0.7010, 0.5291, -0.8860, 1.0000)
);

// Our push constant
layout(push_constant, std430) uniform Params {
    vec2 mip_zero_size;
    float flip_y;
    float padding;
} params;

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 uv_chroma = ivec2(gl_GlobalInvocationID.xy) / 2;

	// Might as well flip it while we are here
	vec2 uv_sample = vec2(uv) / params.mip_zero_size;
	vec2 uv_sample_chroma = vec2(uv_chroma) / (params.mip_zero_size * 0.5);
	
	vec2 ya = texture(tex_ya, uv_sample).rg;
	vec2 cbcr = texture(tex_uv, uv_sample_chroma).rg;
	
	vec4 ycbcr = vec4(ya.r, cbcr.rg, 1.0);
	vec4 out_color = transform * ycbcr;
	out_color.a = ya.g;
	ivec2 out_pos = uv;
	if (params.flip_y > 0.0) {
		out_pos.y = int(params.mip_zero_size.y) - 1 - out_pos.y;
	}
	imageStore(output_image, out_pos, out_color);
}
