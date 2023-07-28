extends HBUIComponent

class_name HBUICosmeticTextureRect

@onready var texture_rect := TextureRect.new()

var texture: Texture2D: set = set_texture

var stretch_mode := TextureRect.STRETCH_KEEP_ASPECT_CENTERED: set = set_stretch_mode

enum FADE_DIRECTION {
	NONE,
	BOTTOM_TO_TOP,
	TOP_TO_BOTTOM
}

var fade_materials := {
	FADE_DIRECTION.BOTTOM_TO_TOP: preload("res://scripts/new_ui/bottom_to_top_fade_material.tres"),
	FADE_DIRECTION.TOP_TO_BOTTOM: preload("res://scripts/new_ui/top_to_bottom_fade_material.tres")
}

@export var fade_direction := FADE_DIRECTION.NONE: set = set_fade_direction

func set_fade_direction(val):
	fade_direction = val
	if is_inside_tree():
		var fade_direction_material: ShaderMaterial = fade_materials.get(fade_direction, null)
		texture_rect.material = fade_direction_material

func set_stretch_mode(val):
	stretch_mode = val
	if is_inside_tree():
		texture_rect.stretch_mode = stretch_mode

func set_texture(val):
	texture = val
	if is_inside_tree():
		texture_rect.texture = val

static func get_component_id() -> String:
	return "cosmetic_texture_rect"
	
static func get_component_name() -> String:
	return "Cosmetic Texture2D Rect" 

func _ready():
	super._ready()
	texture_rect.expand = true
	texture_rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(texture_rect)
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_texture(texture)
	set_stretch_mode(stretch_mode)
	set_fade_direction(fade_direction)
func get_hb_inspector_whitelist() -> Array:
	var whitelist := super.get_hb_inspector_whitelist()
	whitelist.append_array([
		"texture", "stretch_mode", "fade_direction"
	])
	return whitelist

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := super._to_dict(resource_storage)
	out_dict["texture"] = resource_storage.get_texture_name(texture)
	out_dict["stretch_mode"] = stretch_mode
	out_dict["fade_direction"] = fade_direction
	out_dict["_stretch_mode_version"] = 1
	return out_dict

func _get_property_list():
	var list := []
	
	register_texture_to_plist(list, "texture")
	list.push_back({
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Scale On Expand (Compat),Scale,Tile,Keep,Keep Centered,Keep Aspect,Keep Aspect Centered,Keep Aspect Covered",
		"name": "stretch_mode",
		"type": TYPE_INT,
	})
	
	return list

func _migrate_stretch_mode(old_stretch_mode: int) -> TextureRect.StretchMode:
	var new_stretch_mode := TextureRect.STRETCH_SCALE
	#"Scale On Expand (Compat),Scale,Tile,Keep,Keep Centered,Keep Aspect,Keep Aspect Centered,Keep Aspect Covered"
	match old_stretch_mode:
		# Scale on expand, Scale
		0, 1:
			new_stretch_mode = TextureRect.STRETCH_SCALE
		# Tile
		2:
			new_stretch_mode = TextureRect.STRETCH_TILE
		# Keep
		3:
			new_stretch_mode = TextureRect.STRETCH_KEEP
		# Keep centered
		4:
			new_stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		# Keep aspect
		5:
			new_stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		# Keep aspect centered
		6:
			new_stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Keep aspect covered
		7:
			new_stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	return new_stretch_mode

func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	super._from_dict(dict, cache)
	texture = cache.get_texture(dict.get("texture", ""))
	if not dict.has("_stretch_mode_version"):
		# This must be from the old engine, migrate it
		var old_stretch_mode := dict.get("stretch_mode") as int
		stretch_mode = _migrate_stretch_mode(old_stretch_mode)
	else:
		stretch_mode = dict.get("stretch_mode", TextureRect.STRETCH_KEEP_CENTERED)
	fade_direction = dict.get("fade_direction", FADE_DIRECTION.NONE)
