extends Node

const ICON_PACKS_SEARCH_PATHS = ["res://graphics/icon_packs", "user://icon_packs"]

var packs = {}

const LOG_NAME = "IconPackLoader"

var preloaded_graphics = {}
var current_pack
# Arrows pack also acts as fallback when other graphics are not available
var fallback_graphics
var fallback_pack

const DIRECTIONAL_TYPES_PROPERTY_MAP = {
	"LEFT": "left_arrow_override_enabled",
	"RIGHT": "right_arrow_override_enabled",
	"UP": "up_arrow_override_enabled",
	"DOWN": "down_arrow_override_enabled"
}

func _ready():
	load_all_icon_packs()
	# Todo use default if pack doesn't exist
	set_current_pack(UserSettings.user_settings.icon_pack)
	fallback_pack = load_icon_pack("res://graphics/fallback_icon_pack")
	fallback_graphics = preload_graphics(fallback_pack)
	
func set_current_pack(pack_name):
	preloaded_graphics = preload_graphics(packs[pack_name])
	current_pack = pack_name
	
func preload_graphics(icon_pack):
	var result = {}
	var graphics = {}
	for graphic_type in icon_pack.graphics:

		var graphic_srcs = icon_pack.graphics[graphic_type].src
		graphics[graphic_type] =  {}
		for variation_type in graphic_srcs:
			var source = graphic_srcs[variation_type]
			var graphic_path = icon_pack.__origin + "/" + source.target_path + ".png"
			graphics[graphic_type][variation_type] = load(graphic_path)
	return HBUtils.merge_dict(result, graphics)

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
func load_all_icon_packs():
	for path in ICON_PACKS_SEARCH_PATHS:
		packs = HBUtils.merge_dict(packs, load_icon_packs_from_path(path))

func get_icon(type, variation):
	if preloaded_graphics.has(type):
		if preloaded_graphics[type].has(variation):
			return preloaded_graphics[type][variation]
	elif fallback_graphics.has(type):
		if fallback_graphics[type].has(variation):
			return fallback_graphics[type][variation]
			
# For overrides (like arrows)
func get_graphics_for_type(type):
	# This makes arrow overrides work
	
	var graphics = preloaded_graphics
	
	if type in DIRECTIONAL_TYPES_PROPERTY_MAP.keys():
		if UserSettings.user_settings.get(DIRECTIONAL_TYPES_PROPERTY_MAP[type]):
			graphics = fallback_graphics
	var final_graphs
	if graphics.has(type):
		
		# This ensures that we take care of any missing graphics, even if the current
		# icon pack has the type defined it might still be missing some graphics
		final_graphs = HBUtils.merge_dict(fallback_graphics[type], graphics[type])
	else:
		final_graphs = fallback_graphics[type]
		
	return final_graphs
		
		
func get_pack_for_type(type):
	var pack = packs[current_pack]
	
	if type in DIRECTIONAL_TYPES_PROPERTY_MAP.keys():
		if UserSettings.user_settings.get(DIRECTIONAL_TYPES_PROPERTY_MAP[type]):
			if fallback_pack.has(type):
				pack = fallback_pack
	return pack
		
func get_variations(type):
	var graphics = get_graphics_for_type(type)
	if graphics:
		return graphics
		
func get_color(type) -> Color:
	var color = "#FFFFFF"
	var pack = get_pack_for_type(type)
	if pack.graphics.has(type):
		color = pack.graphics[type].color
	else:
		if pack != fallback_pack:
			color = fallback_pack.graphics[type].color
	return Color(color)

func get_trail_margin(type) -> float:
	var margin = 0.0
	var pack = get_pack_for_type(type)
	if pack.graphics.has(type):
		if pack.graphics[type].has("trail_margin"):
			margin = pack.graphics[type].trail_margin
	else:
		if pack != fallback_pack:
			if fallback_pack.graphics[type].has("trail_margin"):
				margin = fallback_pack.graphics[type].trail_margin
	return margin


