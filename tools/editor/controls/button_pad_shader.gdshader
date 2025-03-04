shader_type canvas_item;

uniform bool hover = false;
uniform bool pressed = false;
uniform bool disabled = false;

uniform vec2 highlight_pos = vec2(1.0, 1.0);
uniform vec2 highlight_idx = vec2(1, 1);
uniform float highlight_area_size = 0.33;

uniform sampler2D icon_texture;

uniform vec4 pressed_color = vec4(0.0);
uniform vec4 disabled_color = vec4(0.0);

// Remaps input from [min, max] to [min, max]
// From https://github.com/arkology/ShaderV (MIT License)
vec2 remap(vec2 _remap_input, vec2 _remap_from, vec2 _remap_to){
	return _remap_to.x + ((_remap_input - _remap_from.x) * (_remap_to.y - _remap_to.x)) / (_remap_from.y - _remap_from.x);
}

void fragment() {
	// Remap UV to make the icon slightly smaller (Using UV as is would make it
	// occupy the whole button)
	vec2 icon_uv = remap(UV, vec2(0.1, 0.9), vec2(0.0, 1.0));

	vec4 icon_color = texture(icon_texture, icon_uv);

	vec2 highlight_area_start = highlight_idx * highlight_area_size;
	vec2 highlight_area_end = highlight_area_start + vec2(highlight_area_size);

	// Hover glow
	vec4 hover_color = vec4(0.0);
	if ((hover || pressed) && !disabled)  {
		float blending_factor = pow(UV.x - highlight_pos.x, 2.0) + pow(UV.y - highlight_pos.y, 2.0);

		hover_color = vec4(1, 1, 1, 1) * max(0.15 - blending_factor, 0.0);
	}

	// Pressed indicator
	if (pressed && !disabled &&
		UV.x >= highlight_area_start.x && UV.y >= highlight_area_start.y &&
		UV.x <= highlight_area_end.x && UV.y <= highlight_area_end.y) {
		// Remap UV again to make the icon slightly larger in the highlighted section
		icon_uv = remap(UV, vec2(0.05, 0.95), vec2(0.0, 1.0));

		// Apply color modulation for the pressed state
		// Note: This seems to result in a slightly weaker color than the .modulate
		// property. TODO: Check how godot handles it.
		icon_color = texture(icon_texture, icon_uv);
		if (icon_color.a > 0.0) {
			icon_color = pressed_color;
		}
	}

	if (disabled) {
		// Apply color modulation for the disabled state
		if (icon_color.a > 0.0) {
			icon_color = disabled_color;
		}
	}

	if (hover_color.a > 0.0) {
		COLOR += hover_color;
	}

	if (icon_color.a > 0.0) {
		// Basic blending based on alpha
		COLOR += vec4(icon_color.rgb * icon_color.a, 1.0);
	}
}