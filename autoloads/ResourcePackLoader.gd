extends Node

const ICON_PACK_LOCATIONS = ["user://editor_resource_packs", "user://resource_packs", "res://graphics/resource_packs"]

var resource_packs = {}

var fallback_images = {}
var fallback_pack: HBResourcePack
var note_pack: HBResourcePack
var fallback_textures = {}
var selected_pack_textures = {}

# Used for debugging only
var _final_atlases := {}

var final_textures := {}
var missing_texture = preload("res://graphics/missing_texture.png")

var note_override_list_i := []
var note_override_list_str := []

const ATLASES = [
	"notes"
]

# Ordinary graphics that aren't loaded from an atlas
const GRAPHICS_FILE_NAMES = [
	"note_trail.png",
	"multi_laser.png",
	"sustain_trail.png"
]

# Graphics that should be loaded from the same pack as note graphics but that are not
# atlases, they should be both here and in graphics_file_names
const NOTE_ICON_GRAPHICS_FILE_NAMES = [
	"note_trail.png",
	"multi_laser.png",
	"sustain_trail.png"
]

func _init_resource_pack_loader():
	var dir = Directory.new()
	for location in ICON_PACK_LOCATIONS:
		if not dir.file_exists(location):
			dir.make_dir_recursive(location)
		_load_icon_packs_from_path(location)
	rebuild_final_atlases()
func _setup_fallback_pack(fallback: HBResourcePack):
	for atlas_name in ATLASES:
		var atlas_image = fallback.get_atlas_image(atlas_name)
		fallback_images[atlas_name] = atlas_image
	for file_name in GRAPHICS_FILE_NAMES:
		var image := fallback.get_graphic_image(file_name)
		if image:
			var texture = ImageTexture.new()
			texture.create_from_image(image)
			texture.resource_path = "PH_RPL_" + file_name + "_" + str(rand_range(0, 200000))
			
			fallback_textures[file_name] = texture
		else:
			prints("failed to load", file_name)
	fallback_pack = fallback
	
func soft_rebuild_final_atlas():
	final_textures = fallback_textures.duplicate()
	
	note_override_list_str = []
	note_override_list_i = []
	
	if UserSettings.user_settings.up_arrow_override_enabled:
		note_override_list_str.append("up")
		note_override_list_i.append(HBBaseNote.NOTE_TYPE.UP)
	if UserSettings.user_settings.down_arrow_override_enabled:
		note_override_list_str.append("down")
		note_override_list_i.append(HBBaseNote.NOTE_TYPE.DOWN)
	if UserSettings.user_settings.left_arrow_override_enabled:
		note_override_list_str.append("left")
		note_override_list_i.append(HBBaseNote.NOTE_TYPE.LEFT)
	if UserSettings.user_settings.right_arrow_override_enabled:
		note_override_list_str.append("right")
		note_override_list_i.append(HBBaseNote.NOTE_TYPE.RIGHT)
		
	for texture_name in selected_pack_textures:
		var skip_this = false
		for note_name in note_override_list_str:
			if texture_name.begins_with(note_name):
				skip_this = true
				break
		if skip_this:
			continue
		final_textures[texture_name] = selected_pack_textures[texture_name]
	
func rebuild_final_atlases():
	_final_atlases = {}
	final_textures = {}
	selected_pack_textures = {}
	
	for atlas_name in ATLASES:
		var err = rebuild_final_atlas(atlas_name)
		if err != OK:
			push_error("Error rebuilding atlas \"%s\", pack missing?" % [atlas_name])
	var selected_pack := resource_packs.get(UserSettings.user_settings.resource_pack, null) as HBResourcePack
	note_pack = selected_pack
	if UserSettings.user_settings.note_icon_override != "__resource_pack":
		if UserSettings.user_settings.note_icon_override in resource_packs:
			note_pack = resource_packs[UserSettings.user_settings.note_icon_override]
	for file_name in GRAPHICS_FILE_NAMES:
		var pack := selected_pack
		if UserSettings.user_settings.note_icon_override != "__resource_pack" and file_name in NOTE_ICON_GRAPHICS_FILE_NAMES:
			pack = note_pack
		if pack:
			var image := pack.get_graphic_image(file_name)
			if image:
				var texture := ImageTexture.new()
				texture.create_from_image(image)
				selected_pack_textures[file_name] = texture
	soft_rebuild_final_atlas()
	
func rebuild_final_atlas(atlas_name: String) -> int:
	var time_start = OS.get_ticks_usec()
	var selected_pack := resource_packs.get(UserSettings.user_settings.resource_pack, null) as HBResourcePack
	if atlas_name == "notes":
		if UserSettings.user_settings.note_icon_override != "__resource_pack":
			if UserSettings.user_settings.note_icon_override in resource_packs:
				selected_pack = resource_packs.get(UserSettings.user_settings.note_icon_override, null) as HBResourcePack
	var use_fallback = false
	if selected_pack:
		var selected_pack_atlas := selected_pack.get_atlas_image("notes")
		if selected_pack_atlas:
			var at = HBUtils.pack_images_turbo16({
				"fallback": fallback_images[atlas_name],
				"selected": selected_pack_atlas
			}, 1, true)
			var atlas_texture := at.texture as Texture
			at.texture.resource_path = "PH_RESOURCE_PACK_LOADER_ATLAS_" + str(rand_range(0, 200000))
			var fallback_region_pos := at.atlas_data.fallback.region.position as Vector2
			var fallback_offset := at.atlas_data.fallback.margin.position as Vector2
			var selected_region_pos := at.atlas_data.selected.region.position as Vector2
			var selected_offset := at.atlas_data.selected.margin.position as Vector2
			fallback_region_pos -= fallback_offset
			selected_region_pos -= selected_offset
			_final_atlases[atlas_name] = atlas_texture
			fallback_textures = HBUtils.merge_dict(fallback_textures, fallback_pack.create_atlas_textures(atlas_texture, atlas_name, fallback_region_pos))
			selected_pack_textures = HBUtils.merge_dict(selected_pack_textures, selected_pack.create_atlas_textures(atlas_texture, atlas_name, selected_region_pos))
		else:
			use_fallback = true
	else:
		use_fallback = true
	if use_fallback:
		# If the resource pack used for this atlas is not present, we use the fallback only
		var fallback_image := fallback_images[atlas_name] as Image
		var fallback_image_tex := ImageTexture.new()
		fallback_image_tex.create_from_image(fallback_image)
		fallback_image_tex.resource_path = "PH_RESOURCE_PACK_LOADER_FALLBACK_ATLAS_" + str(rand_range(0, 200000))
		
		fallback_textures = HBUtils.merge_dict(fallback_textures, fallback_pack.create_atlas_textures(fallback_image_tex, atlas_name))
		_final_atlases[atlas_name] = fallback_image_tex
		return ERR_FILE_MISSING_DEPENDENCIES
	var time_end = OS.get_ticks_usec()
	print("atlas rebuild took %d microseconds" % [(time_end - time_start)])
	return OK
func _load_icon_packs_from_path(path: String):
	var dir := Directory.new()
	var value = {}
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var dir_name = dir.get_next()

		while dir_name != "":
			if dir.current_is_dir() and not dir_name.begins_with("."):
				var pack_path = path + "/%s" % dir_name
				var pack: HBResourcePack = HBResourcePack.load_from_directory(pack_path)
				if pack:
					pack._id = dir_name
				if path.begins_with("res://") and dir_name == "fallback":
					_setup_fallback_pack(pack)
				elif pack:
						resource_packs[pack._id] = pack
#				value[dir_name] = load_icon_pack(pack_path)
			dir_name = dir.get_next()
	return value

func get_graphic(graphic_name: String) -> Texture:
	return final_textures.get(graphic_name, missing_texture)

func get_note_trail_color(note_i: int) -> Color:
	var trail_color_property_name = HBGame.NOTE_TYPE_TO_STRING_MAP[note_i] + "_trail_color"
	if note_i in note_override_list_i or not trail_color_property_name in note_pack.property_overrides:
		return fallback_pack.get(trail_color_property_name)
	else:
		return note_pack.get(trail_color_property_name)

func get_note_trail_margin(note_i) -> float:
	var trail_margin_property_name = HBGame.NOTE_TYPE_TO_STRING_MAP[note_i] + "_trail_color"
	if note_i in note_override_list_i or not trail_margin_property_name in note_pack.property_overrides:
		return fallback_pack.get(trail_margin_property_name)
	else:
		return note_pack.get(trail_margin_property_name)
