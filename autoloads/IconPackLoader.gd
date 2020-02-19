extends Node

const ICON_PACKS_SEARCH_PATHS = ["res://graphics/icon_packs"]

var packs = {}

const LOG_NAME = "IconPackLoader"

var preloaded_graphics = {}
var current_pack
var arrow_overrides_graphics
func _ready():
	load_all_icon_packs()
	# Todo use default if pack doesn't exist
	preloaded_graphics = preload_graphics(packs[UserSettings.user_settings.icon_pack])
	current_pack = UserSettings.user_settings.icon_pack
	arrow_overrides_graphics = preload_graphics(load_icon_pack("res://graphics/arrow_overrides"))
	
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
func get_variations(type):
	# This makes arrow overrides work
	
	var directional_types_property_map = {
		"LEFT": "left_arrow_override_enabled",
		"RIGHT": "right_arrow_override_enabled",
		"UP": "up_arrow_override_enabled",
		"DOWN": "left_arrow_override_enabled"
	}
	
	var graphics = preloaded_graphics
	
	if type in directional_types_property_map.keys():
		if UserSettings.user_settings.get(directional_types_property_map[type]):
			graphics = arrow_overrides_graphics
	if graphics.has(type):
		return graphics[type]
		
func get_color(type) -> Color:
	var color = "#FFFFFF"
	if packs[current_pack].graphics.has(type):
		color = packs[current_pack].graphics[type].color
	return Color(color)
