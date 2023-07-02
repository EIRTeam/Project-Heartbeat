extends StyleBoxTexture

class_name HBUIStyleboxTexture

func register_texture_to_plist(property_list: Array, texture_name: String):
	property_list.push_back({
		"name": texture_name,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Texture2D",
		"type": TYPE_OBJECT
	})

func _get_property_list():
	var list := []
	register_texture_to_plist(list, "texture")
	return list

func get_hb_inspector_whitelist() -> Array:
	var whitelist := []
	whitelist.append_array([
		"axis_stretch_horizontal",
		"axis_stretch_vertical",
		"draw_center",
		"modulate_color" ,
		"texture",
	])
	return whitelist
