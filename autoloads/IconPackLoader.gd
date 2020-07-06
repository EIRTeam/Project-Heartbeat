extends Node

const ICON_PACKS_SEARCH_PATHS = ["res://graphics/icon_packs", "user://icon_packs"]

var packs = {}

const LOG_NAME = "IconPackLoader"

var current_atlas
var current_pack
# Arrows pack also acts as fallback when other graphics are not available
var fallback_atlas
var fallback_pack

var final_atlas = {}
var final_pack = {}

var variations_map = {}

const DIRECTIONAL_TYPES_PROPERTY_MAP = {
	"LEFT": "left_arrow_override_enabled",
	"RIGHT": "right_arrow_override_enabled",
	"UP": "up_arrow_override_enabled",
	"DOWN": "down_arrow_override_enabled"
}

func _ready():
	pass
	
func _init_icon_pack_loader():
	load_all_icon_packs()
	# Todo use default if pack doesn't exist
	fallback_pack = load_icon_pack("res://graphics/fallback_icon_pack")
	fallback_atlas = preload_atlas(fallback_pack)

func set_current_pack(pack_name):
	current_atlas = preload_atlas(packs[pack_name])
	current_pack = packs[pack_name]
	rebuild_final_atlas()

func rebuild_final_atlas():
	var final_atlas_textures = HBUtils.merge_dict(current_atlas.atlas_textures.duplicate(true), fallback_atlas.atlas_textures)
	var final_pack_config = {"graphics": HBUtils.merge_dict(current_pack.graphics.duplicate(true), fallback_pack.graphics)}
	
	var overriden_directions = []
	for note_type in DIRECTIONAL_TYPES_PROPERTY_MAP:
		if not UserSettings.user_settings.get(DIRECTIONAL_TYPES_PROPERTY_MAP[note_type]):
			final_atlas_textures[note_type] = HBUtils.merge_dict(final_atlas_textures[note_type], current_atlas.atlas_textures[note_type])
			final_pack_config.graphics[note_type] = HBUtils.merge_dict(final_pack_config.graphics[note_type], current_pack.graphics[note_type])
	final_pack = final_pack_config
	final_atlas = {"atlas_textures": final_atlas_textures}
	
func generate_atlas_textures(pack_config, texture, atlas_config):
	var atlas_textures = {}
	for type in pack_config.graphics:
		for variation in pack_config.graphics[type].src:
			var graphic_path = pack_config.graphics[type].src[variation].target_path
			graphic_path = graphic_path.split("/")[-1] + ".png" # should be f.e Triangle.png
			if atlas_config.frames.has(graphic_path):
				var frame = atlas_config.frames[graphic_path].frame
				var sprite_source_size = atlas_config.frames[graphic_path].spriteSourceSize
				
				var atlas_texture := AtlasTexture.new()
				atlas_texture.atlas = texture
		
				var region = Rect2(Vector2(frame.x, frame.y), Vector2(frame.w, frame.h))
				atlas_texture.region = region
		
				var margin = Rect2(Vector2(sprite_source_size.x, sprite_source_size.y), Vector2(sprite_source_size.w-frame.w, sprite_source_size.h-frame.h))
				atlas_texture.margin = margin
		
				if not atlas_textures.has(type):
					atlas_textures[type] = {}
				atlas_textures[type][variation] = atlas_texture
			else:
				Log.log(self, "Atlas entry not found: %s" % [graphic_path], Log.LogLevel.ERROR)
	return atlas_textures
func preload_atlas(icon_pack):
	var file = File.new()
	file.open(icon_pack.__origin + "/" + "atlas.json", File.READ)
	var atlas_json := JSON.parse(file.get_as_text()) as JSONParseResult
	if atlas_json.error == OK:
		var texture = load(icon_pack.__origin + "/" + "atlas.png")
		return {
			"texture": texture,
			"config": atlas_json.result,
			"atlas_textures": generate_atlas_textures(icon_pack, texture, atlas_json.result)
			}
	else:
		Log.log(self, "Error loading atlas: " + icon_pack.__origin + "/" + "atlas.json", Log.LogLevel.ERROR)

func load_icon_packs_from_path(path: String):
	var dir := Directory.new()
	var value = {}
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var dir_name = dir.get_next()

		while dir_name != "":
			if dir.current_is_dir() and not dir_name.begins_with("."):
				var pack_path = path + "/%s" % dir_name
				value[dir_name] = load_icon_pack(pack_path)
			dir_name = dir.get_next()
	return value

func load_icon_pack(path: String):
	var pack_json_path = path + "/icon_pack.json"
	var file = File.new()
	
	var value = {}
	
	if file.file_exists(pack_json_path):
		file.open(pack_json_path, File.READ)
		var result = JSON.parse(file.get_as_text())
		if result.error == OK:
			value = result.result
			value["__origin"] = path
		else:
			Log.log(self, "Error parsing icon pack: %s from %s" % [path, pack_json_path], Log.LogLevel.ERROR)
	return value
	
func get_graphic(type, variation):
	return final_atlas.atlas_textures[type][variation]
	
func load_all_icon_packs():
	for path in ICON_PACKS_SEARCH_PATHS:
		packs = HBUtils.merge_dict(packs, load_icon_packs_from_path(path))
		
func get_color(type) -> Color:
	var color = "#FFFFFF"
	var pack = final_pack
	if pack.graphics.has(type):
		color = pack.graphics[type].color
	else:
		if pack != fallback_pack:
			color = fallback_pack.graphics[type].color
	return Color(color)

func get_trail_margin(type) -> float:
	var margin = 0.0
	var pack = final_pack
	if pack.graphics.has(type):
		if pack.graphics[type].has("trail_margin"):
			margin = pack.graphics[type].trail_margin
	else:
		if pack != fallback_pack:
			if fallback_pack.graphics[type].has("trail_margin"):
				margin = fallback_pack.graphics[type].trail_margin
	return margin


