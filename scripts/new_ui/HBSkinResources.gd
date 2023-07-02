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
	return _path.path_join("skin_resources").path_join(textures[texture_name])

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
	return _path.path_join("skin_resources").path_join(frames[frame].get("texture_path"))

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

func get_animated_texture_frame_duration(texture_name: String, frame: int) -> float:
	if not texture_name in textures:
		return 0
	if not is_animated_texture(texture_name):
		return 0
	var frames := textures[texture_name].get("frames", []) as Array
	if frame > frames.size()-1:
		return 0
	if not "texture_path" in frames[frame]:
		return 0.0
	# Legacy delay conversion
	if textures[texture_name].has("fps") and frames[frame].has("delay"):
		var fps := textures[texture_name].get("fps", 24) as float
		var delay := textures[texture_name].get("delay", 0.0) as float
		return 1.0 / fps + delay
	if not "duration" in frames[frame]:
		return 0.0
	return frames[frame].duration

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

func animated_texture_has_legacy_frame_delay(texture_name: String, frame: int) -> int:
	if not texture_name in textures:
		return false
	if not is_animated_texture(texture_name):
		return false
	var frames := textures[texture_name].get("frames", []) as Array
	if frame > frames.size()-1:
		return false
	if "delay" in frames[frame]:
		return true
	return false

func get_font_path(font_name: String) -> String:
	if not font_name in fonts:
		return ""
	return _path.path_join("skin_resources").path_join(fonts[font_name])

func is_animated_texture(texture_name: String) -> bool:
	return textures.get(texture_name, null) is Dictionary
