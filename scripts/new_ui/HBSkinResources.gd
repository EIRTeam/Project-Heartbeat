extends HBSerializable

class_name HBSkinResources

# resource name to file name maps
var fonts := {}
var textures := {}

# not serialized
var _path: String

func _init():
	serializable_fields += [
		"fonts",
		"textures"
	]

func get_serialized_type():
	return "SkinResources"

func get_cache():
	# No type hinting bc cyclic reference
	return load("res://scripts/new_ui/HBSkinResourcesCache.gd").new(self)

func get_texture_path(texture_name: String) -> String:
	if not texture_name in textures:
		return ""
	return _path.plus_file("skin_resources").plus_file(textures[texture_name])

func get_animated_texture_frame_path(texture_name: String, frame: int) -> String:
	if not texture_name in textures:
		return ""
	if not is_animated_texture(texture_name):
		return ""
	var frames := textures[texture_name].get("frames", []) as Array
	if frame > frames.size()-1:
		return ""
	if not "texture_path" in frames[frame]:
		return ""
	return _path.plus_file("skin_resources").plus_file(frames[frame].get("texture_path"))

func get_animated_texture_frame_count(texture_name: String) -> int:
	if not texture_name in textures:
		return 0
	if not is_animated_texture(texture_name):
		return 0
	var frames := textures[texture_name].get("frames", []) as Array
	return frames.size()

func get_animated_texture_fps(texture_name: String) -> int:
	if not texture_name in textures:
		return 0
	if not is_animated_texture(texture_name):
		return 0
	return textures[texture_name].get("fps", 24)

func get_animated_texture_frame_delay(texture_name: String, frame: int) -> int:
	if not texture_name in textures:
		return 0
	if not is_animated_texture(texture_name):
		return 0
	var frames := textures[texture_name].get("frames", []) as Array
	if frame > frames.size()-1:
		return 0
	if not "delay" in frames[frame]:
		return 0
	return frames[frame].delay

func get_font_path(font_name: String) -> String:
	if not font_name in fonts:
		return ""
	return _path.plus_file("skin_resources").plus_file(fonts[font_name])

func is_animated_texture(texture_name: String) -> bool:
	return textures.get(texture_name, null) is Dictionary
