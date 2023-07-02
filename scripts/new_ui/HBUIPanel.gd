extends HBUIComponent

class_name HBUIPanel

@onready var panel := Panel.new()
var stylebox: StyleBox = HBUIStyleboxFlat.new(): set = set_stylebox
var dots_stylebox := StyleBoxFlat.new()

func set_stylebox(val):
	stylebox = val
	if panel:
		panel.add_theme_stylebox_override("panel", val)
	update_dots_stylebox()

var dots_pattern := false: set = set_dots_pattern
var dots_texture: Texture2D: set = set_dots_texture
var dots_modulate := Color.WHITE: set = set_dots_modulate
var dots_behind := false: set = set_dots_behind

var dots_panel: Panel

func update_dots_stylebox():
	if dots_pattern and dots_panel:
		if stylebox is StyleBoxFlat:
			dots_stylebox = stylebox.duplicate()
			dots_stylebox.shadow_size = 0
			dots_panel.offset_bottom = -dots_stylebox.border_width_bottom
			dots_panel.offset_left = dots_stylebox.border_width_left
			dots_panel.offset_right = -dots_stylebox.border_width_right
			dots_panel.offset_top = dots_stylebox.border_width_top
			
			dots_stylebox.border_width_left = 0
			dots_stylebox.border_width_right = 0
			dots_stylebox.border_width_top = 0
			dots_stylebox.border_width_bottom = 0
			
			dots_stylebox.border_color.a = 0.0
			dots_stylebox.bg_color = Color.RED
			dots_stylebox.draw_center = true
			dots_panel.add_theme_stylebox_override("panel", dots_stylebox)
			assert(dots_panel.material is ShaderMaterial)
			if dots_texture:
				dots_panel.material.set_shader_parameter("bg", dots_texture)
				dots_panel.material.set_shader_parameter("texture_size", dots_texture.get_size())
			dots_panel.modulate = dots_modulate
			dots_panel.show_behind_parent = dots_behind
		
func set_dots_behind(val):
	dots_behind = val
	update_dots_stylebox()
		
func set_dots_modulate(val):
	dots_modulate = val
	update_dots_stylebox()

func set_dots_texture(val):
	dots_texture = val
	if is_inside_tree():
		update_dots_stylebox()

func set_dots_pattern(val):
	dots_pattern = val
	if is_inside_tree():
		if dots_panel:
			dots_panel.queue_free()
			dots_panel = null
		if dots_pattern:
			dots_panel = Panel.new()
			var shader_mat := ShaderMaterial.new()
			shader_mat.shader = preload("res://scripts/new_ui/dots_shader.tres")
			dots_panel.material = shader_mat
			add_child(dots_panel)
			dots_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			update_dots_stylebox()

func _ready():
	super._ready()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_stylebox(stylebox)
	set_dots_pattern(dots_pattern)
	set_dots_texture(dots_texture)
	set_dots_modulate(dots_modulate)
	set_dots_behind(dots_behind)
	
	panel.add_theme_stylebox_override("panel", stylebox)

func get_hb_inspector_whitelist() -> Array:
	var whitelist := super.get_hb_inspector_whitelist()
	whitelist.append_array([
		"stylebox", "dots_pattern", "dots_texture",
		"dots_modulate", "dots_behind"
	])
	return whitelist

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := super._to_dict(resource_storage)
	out_dict["stylebox"] = serialize_stylebox(stylebox, resource_storage)
	out_dict["dots_pattern"] = dots_pattern
	out_dict["dots_texture"] = resource_storage.get_texture_name(dots_texture)
	out_dict["dots_modulate"] = dots_modulate.to_html()
	out_dict["dots_behind"] = dots_behind
	return out_dict
	
func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	super._from_dict(dict, cache)
	
	stylebox = deserialize_stylebox(dict.get("stylebox", {}), cache, stylebox)
	dots_pattern = dict.get("dots_pattern", false)
	dots_texture = cache.get_texture(dict.get("dots_texture", ""))
	dots_modulate = get_color_from_dict(dict, "dots_modulate", Color("#999999"))
	dots_behind = dict.get("dots_behind", false)

func _get_property_list():
	var list := []
	register_subresource_to_plist(list, "stylebox")
	register_texture_to_plist(list, "dots_texture")
	print(list)
	return list

static func get_component_id() -> String:
	return "panel"

static func get_component_name() -> String:
	return "Cosmetic Panel"

