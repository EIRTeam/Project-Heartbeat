extends Node

const ICON_PACKS_SEARCH_PATHS = ["res://graphics/icon_packs", "user://icon_packs"]

var packs = {}

const LOG_NAME = "IconPackLoader"

# Currently loaded atlas before processing
var current_atlas
var current_pack
# Arrows pack also acts as fallback when other graphics are not available
var fallback_atlas: HBAtlas
var fallback_pack

# Final atlas data
var final_atlas: HBAtlas = HBAtlas.new()
var final_pack = {}

var variations_map = {}

class HBAtlas:
	var texture: Texture
	var config: Dictionary
	var atlas_textures: Dictionary

const DIRECTIONAL_TYPES_PROPERTY_MAP = {
	"LEFT": "left_arrow_override_enabled",
	"RIGHT": "right_arrow_override_enabled",
	"UP": "up_arrow_override_enabled",
	"DOWN": "down_arrow_override_enabled"
}

var hold_icon_sprite = AtlasTexture.new()
var hold_icon_sprite_multi = AtlasTexture.new()

const hold_multi_sprite_texture = preload("res://graphics/hold_text_atlas.png")
	
var current_pack_name = ""

	
func _init_icon_pack_loader():
	load_all_icon_packs()
	# Todo use default if pack doesn't exist
	fallback_pack = load_icon_pack("res://graphics/fallback_icon_pack")
	fallback_atlas = preload_atlas(fallback_pack)


func set_current_pack(pack_name):
	if pack_name != current_pack_name:
		current_pack_name = pack_name
		current_atlas = preload_atlas(packs[pack_name])
		current_pack = packs[pack_name]
		rebuild_final_atlas()
	
var timing_arm_texture = preload("res://graphics/arm.png")
var timing_arm_atlas = AtlasTexture.new()


func regenerate_direction_overrides():
	var overriden_directions = []
	var final_atlas_texures = final_atlas.atlas_textures
	for note_type in DIRECTIONAL_TYPES_PROPERTY_MAP:
		if not UserSettings.user_settings.get(DIRECTIONAL_TYPES_PROPERTY_MAP[note_type]):
			final_atlas.atlas_textures[note_type] = HBUtils.merge_dict(final_atlas.atlas_textures[note_type], current_atlas.atlas_textures[note_type])
			final_pack.graphics[note_type] = HBUtils.merge_dict(final_pack.graphics[note_type], current_pack.graphics[note_type])
		else:
			final_atlas.atlas_textures[note_type] = HBUtils.merge_dict(final_atlas.atlas_textures[note_type], fallback_atlas.atlas_textures[note_type])
			final_pack.graphics[note_type] = HBUtils.merge_dict(final_pack.graphics[note_type], fallback_pack.graphics[note_type])

func rebuild_final_atlas():
	# We first do the atlas processing, for batching purposes we map the packs into a single texture

	var final_texture = ImageTexture.new()

	var final_texture_img := fallback_atlas.texture.get_data().duplicate(true) as Image
	var new_height = max(final_texture_img.get_height(), current_atlas.texture.get_height())
	var new_width = final_texture_img.get_width() + current_atlas.texture.get_width() + timing_arm_texture.get_width()
	final_texture_img.crop(nearest_po2(new_width), new_height)
	var current_atlas_texture_img := current_atlas.texture.get_data() as Image
	var src_rect = Rect2(Vector2.ZERO, current_atlas_texture_img.get_size())
	final_texture_img.lock()
	final_texture_img.blit_rect(current_atlas_texture_img, src_rect, Vector2(fallback_atlas.texture.get_width()-1, 0))
	
	# We also bake the timing arm texture
	var timing_arm_target_position = Vector2(fallback_atlas.texture.get_width() + current_atlas.texture.get_width()-1, 0)
	var timing_arm_size = timing_arm_texture.get_size()
	final_texture_img.blit_rect(timing_arm_texture.get_data(), Rect2(Vector2.ZERO, timing_arm_size), timing_arm_target_position)

	timing_arm_atlas.atlas = final_texture
	timing_arm_atlas.region = Rect2(timing_arm_target_position, timing_arm_size)
	
	timing_arm_target_position.y += timing_arm_texture.get_height()
	
	final_texture_img.blit_rect(hold_multi_sprite_texture.get_data(), Rect2(Vector2.ZERO, hold_multi_sprite_texture.get_size()), timing_arm_target_position)
		
	final_texture_img.unlock()

	hold_icon_sprite.atlas = final_texture
	hold_icon_sprite_multi.atlas = final_texture
	
	var hold_icon_sprite_size = hold_multi_sprite_texture.get_size()
	
	hold_icon_sprite.region = Rect2(timing_arm_target_position + Vector2(hold_icon_sprite_size.x / 2.0, 0), Vector2(hold_icon_sprite_size.x / 2.0, hold_icon_sprite_size.y))
	hold_icon_sprite_multi.region = Rect2(timing_arm_target_position, Vector2(hold_icon_sprite_size.x / 2.0, hold_icon_sprite_size.y))

	#final_texture_img.save_png("user://test.png")

	final_texture.create_from_image(final_texture_img)

	var current_atlas_offset_x = fallback_atlas.texture.get_width()

	for type in current_atlas.atlas_textures:
		for variation in current_atlas.atlas_textures[type]:
			var texture := current_atlas.atlas_textures[type][variation] as AtlasTexture
			texture.region.position.x += fallback_atlas.texture.get_width()
	var final_atlas_textures = HBUtils.merge_dict(fallback_atlas.atlas_textures.duplicate(true), current_atlas.atlas_textures.duplicate(true))
	var final_pack_config = {"graphics": HBUtils.merge_dict(fallback_pack.graphics.duplicate(true), current_pack.graphics.duplicate(true))}
	
	final_pack = final_pack_config
	for type in final_atlas_textures:
		for variation in final_atlas_textures[type]:
			var texture := final_atlas_textures[type][variation] as AtlasTexture
			texture.atlas = final_texture
	var atlas = HBAtlas.new()
	atlas.atlas_textures = final_atlas_textures
	atlas.texture = final_texture
	final_atlas = atlas
	regenerate_direction_overrides()
func generate_atlas_textures(pack_config, texture, atlas_config, x_offset = 0):
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
		
				var region = Rect2(Vector2(frame.x + x_offset - 2, frame.y), Vector2(frame.w + 3, frame.h))
				atlas_texture.region = region
		
				var margin = Rect2(Vector2(sprite_source_size.x, sprite_source_size.y), Vector2(sprite_source_size.w-frame.w, sprite_source_size.h-frame.h))
				atlas_texture.margin = margin
		
				if not atlas_textures.has(type):
					atlas_textures[type] = {}
				atlas_textures[type][variation] = atlas_texture
			else:
				Log.log(self, "Atlas entry not found: %s" % [graphic_path], Log.LogLevel.ERROR)
	return atlas_textures
func preload_atlas(icon_pack, x_offset = 0):
	var file = File.new()
	file.open(icon_pack.__origin + "/" + "atlas.json", File.READ)
	var atlas_json := JSON.parse(file.get_as_text()) as JSONParseResult
	if atlas_json.error == OK:
		var texture = HBUtils.texture_from_fs(icon_pack.__origin + "/" + "atlas.png")
		var atlas = HBAtlas.new()
		atlas.texture = texture
		atlas.config = atlas_json.result
		atlas.atlas_textures = generate_atlas_textures(icon_pack, texture, atlas_json.result, x_offset)
		return atlas
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
		var p = HBGame.platform_settings.user_dir_redirect(path)
		packs = HBUtils.merge_dict(packs, load_icon_packs_from_path(p))
		
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


