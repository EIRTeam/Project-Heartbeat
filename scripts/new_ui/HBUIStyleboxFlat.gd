extends StyleBoxFlat

class_name HBUIStyleboxFlat

func get_hb_inspector_whitelist() -> Array:
	var whitelist := []
	whitelist.append_array([
		"border_width_top",
		"border_width_bottom",
		"border_width_right",
		"border_width_left" ,
		"bg_color",
		"border_color",
		"corner_detail",
		"anti_aliasing",
		"corner_radius_bottom_left",
		"corner_radius_bottom_right",
		"corner_radius_top_left",
		"corner_radius_top_right",
		"shadow_color",
		"shadow_size",
		"content_margin_bottom",
		"content_margin_top",
		"content_margin_left",
		"content_margin_right"
	])
	return whitelist
