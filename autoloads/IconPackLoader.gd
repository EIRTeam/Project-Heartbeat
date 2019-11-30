extends Node

const ICON_PACKS_SEARCH_PATHS = ["res://graphics/icon_packs"]

var packs = {}

const LOG_NAME = "IconPackLoader"

var preloaded_graphics = {}
var current_pack
func _ready():
	load_all_icon_packs()
	preload_graphics(UserSettings.user_settings.icon_pack)
	pass
func preload_graphics(pack: String):
	var icon_pack = packs[pack]
	preloaded_graphics = {}
	var graphics = {}
	for graphic_type in icon_pack.graphics:

		var graphic_srcs = icon_pack.graphics[graphic_type].src
		graphics[graphic_type] =  {}
		for variation_type in graphic_srcs:
			var source = graphic_srcs[variation_type]
			var graphic_path = icon_pack.__origin + "/" + source.target_path + ".png"
			graphics[graphic_type][variation_type] = load(graphic_path)
	HBUtils.merge_dict(preloaded_graphics, graphics)
	current_pack = pack
func load_icon_packs_from_path(path: String):
	var dir := Directory.new()
	var value = {}
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var dir_name = dir.get_next()

		while dir_name != "":
			if dir.current_is_dir() and not dir_name.begins_with("."):
				var pack_json_path = path + "/%s/icon_pack.json" % dir_name
				var file = File.new()
				
				if file.file_exists(pack_json_path):
					file.open(pack_json_path, File.READ)
					var result = JSON.parse(file.get_as_text())
					if result.error == OK:
						value[dir_name] = result.result
						value[dir_name]["__origin"] = path + "/%s" % dir_name
					else:
						Log.log(self, "Error parsing icon pack: %s from %s" % [dir_name, pack_json_path], Log.LogLevel.ERROR)
					
					
			dir_name = dir.get_next()
	return value

func load_all_icon_packs():
	for path in ICON_PACKS_SEARCH_PATHS:
		packs = HBUtils.merge_dict(packs, load_icon_packs_from_path(path))

func get_icon(type, variation):
	if preloaded_graphics.has(type):
		if preloaded_graphics[type].has(variation):
			return preloaded_graphics[type][variation]
func get_variations(type):
	
	if preloaded_graphics.has(type):
		return preloaded_graphics[type]
		
func get_color(type) -> Color:
	var color = "#FFFFFF"
	if packs[current_pack].graphics.has(type):
		color = packs[current_pack].graphics[type].color
	return Color(color)
