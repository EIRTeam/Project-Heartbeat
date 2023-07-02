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

func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	super._from_dict(dict, cache)
	texture = cache.get_texture(dict.get("texture", ""))
	stretch_mode = dict.get("stretch_mode", TextureRect.STRETCH_KEEP_CENTERED)
	fade_direction = dict.get("fade_direction", FADE_DIRECTION.NONE)
