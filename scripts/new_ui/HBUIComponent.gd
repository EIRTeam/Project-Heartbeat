extends Control

class_name HBUIComponent

static func get_component_id() -> String:
	return "component"

static func get_component_name() -> String:
	return "HBComponent"

func register_texture_to_plist(property_list: Array, texture_name: String):
	property_list.push_back({
		"name": texture_name,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "Texture2D",
		"type": TYPE_OBJECT
	})

func register_subresource_to_plist(property_list: Array, property_name: String):
	property_list.push_back({
		"name": property_name,
		"hint": PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string": "hb_subres",
		"type": TYPE_OBJECT
	})

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	return {
		"name": name,
		"modulate": modulate.to_html(),
		"anchor_bottom": anchor_bottom,
		"anchor_top": anchor_top,
		"anchor_left": anchor_left,
		"anchor_right": anchor_right,
		
		"margin_bottom": offset_bottom,
		"margin_top": offset_top,
		"margin_left": offset_left,
		"margin_right": offset_right,
		"component_type": get_component_id()
	}
	
func _ready():
	add_to_group(get_component_id())
	
func get_texture_name(texture: Texture2D) -> String:
	if not texture:
		return ""
	if not texture.has_meta("texture_name"):
		return ""
	return texture.get_meta("texture_name")

func get_hb_inspector_whitelist() -> Array:
	return [
		"margin_left", "margin_right", "margin_top", "margin_bottom",
		"anchor_left", "anchor_right", "anchor_top", "anchor_bottom",
		"modulate"
	]

func set_control_font(control: Control, property_name: String, font: Font):
	if font is HBUIFont and font.base_font:
		control.set(property_name, font)
	else:
		var ff := HBGame.fallback_font.duplicate() as Font
		ff.size = font.size
		ff.outline_size = font.outline_size
		ff.outline_color = font.outline_color
		control.set(property_name, ff)

func set_control_font_override(control: Control, property_name: String, font: Font):
	control.remove_meta("%s_font_override" % property_name)
	if font is HBUIFont and font.base_font:
		control.add_theme_font_override(property_name, font)
	else:
		var ff := HBGame.fallback_font.duplicate() as Font
		ff.size = font.size
		ff.outline_size = font.outline_size
		ff.outline_color = font.outline_color
		control.add_theme_font_override(property_name, ff)
		control.set_meta("%s_font_override" % property_name, ff)

func get_color_from_dict(dict: Dictionary, key: String, backup: Color):
	var col := dict.get(key, "") as String
	col = col.substr(2) + col.substr(0, 2)
	if col:
		return Color(col)
	return backup

func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	set_anchor(SIDE_LEFT, dict.get("anchor_left", 0.0), false, true)
	set_anchor(SIDE_BOTTOM, dict.get("anchor_bottom", 0.0), false, true)
	set_anchor(SIDE_TOP, dict.get("anchor_top", 0.0), false, true)
	set_anchor(SIDE_RIGHT, dict.get("anchor_right", 0.0), false, true)

	offset_bottom = dict.get("margin_bottom", 0.0)
	offset_top = dict.get("margin_top", 0.0)
	offset_left = dict.get("margin_left", 0.0)
	offset_right = dict.get("margin_right", 0.0)
	
	name = dict.get("name", get_component_name().capitalize().replace(" ", ""))
	
	modulate = get_color_from_dict(dict, "modulate", modulate)
	
func serialize_font(font: HBUIFont, resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var font_name := resource_storage.get_font_name(font.font_data) as String

	var out := {
		"name": font_name,
		"size": font.size,
		"fallback_hint": font.fallback_hint,
		"outline_size": font.outline_size,
		"outline_color": font.outline_color.to_html(),
		"spacing_top": font.spacing_top,
		"spacing_bottom": font.spacing_bottom,
		"extra_spacing_char": font.extra_spacing_char
	}
	
	return out
	
func serialize_stylebox(style_box: StyleBox, resource_manager: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := {}
	if style_box is StyleBoxFlat:
		out_dict["border_width_top"] = style_box.border_width_top
		out_dict["border_width_bottom"] = style_box.border_width_bottom
		out_dict["border_width_right"] = style_box.border_width_right
		out_dict["border_width_left"] = style_box.border_width_left
		out_dict["bg_color"] = style_box.bg_color.to_html()
		out_dict["border_color"] = style_box.border_color.to_html()
		out_dict["corner_detail"] = style_box.corner_detail
		out_dict["anti_aliasing"] = style_box.anti_aliasing
		out_dict["corner_radius_bottom_left"] = style_box.corner_radius_bottom_left
		out_dict["corner_radius_bottom_right"] = style_box.corner_radius_bottom_right
		out_dict["corner_radius_top_left"] = style_box.corner_radius_top_left
		out_dict["corner_radius_top_right"] = style_box.corner_radius_top_right
		out_dict["shadow_color"] = style_box.shadow_color.to_html()
		out_dict["shadow_size"] = style_box.shadow_size
		out_dict["stylebox_type"] = "flat"
	elif style_box is StyleBoxTexture:
		out_dict["axis_stretch_horizontal"] = style_box.axis_stretch_horizontal
		out_dict["axis_stretch_vertical"] = style_box.axis_stretch_vertical
		out_dict["draw_center"] = style_box.draw_center
		out_dict["modulate_color"] = style_box.modulate_color.to_html()
		out_dict["texture"] = resource_manager.get_texture_name(style_box.texture)
		out_dict["stylebox_type"] = "texture"
	# Shared properties
	out_dict["content_margin_bottom"] = style_box.content_margin_bottom
	out_dict["content_margin_left"] = style_box.content_margin_left
	out_dict["content_margin_right"] = style_box.content_margin_right
	out_dict["content_margin_top"] = style_box.content_margin_top
	
	return out_dict

func deserialize_stylebox(dict: Dictionary, cache: HBSkinResourcesCache, fallback = null) -> StyleBox:
	var stylebox: StyleBox = null
	if not "stylebox_type" in dict:
		print("FALLING BACK", fallback)
		return fallback
		
	match dict.get("stylebox_type"):
		"flat":
			stylebox = HBUIStyleboxFlat.new()
			stylebox.border_width_top = dict.get("border_width_top", 0)
			stylebox.border_width_bottom = dict.get("border_width_bottom", 0)
			stylebox.border_width_right = dict.get("border_width_right", 0)
			stylebox.border_width_left = dict.get("border_width_left", 0)
			stylebox.bg_color = get_color_from_dict(dict, "bg_color", Color("#999999"))
			stylebox.border_color = get_color_from_dict(dict, "border_color", Color("#cccccc"))
			stylebox.corner_detail = dict.get("corner_detail", 8)
			stylebox.anti_aliasing = dict.get("anti_aliasing", true)
			stylebox.corner_radius_bottom_left = dict.get("corner_radius_bottom_left", 0)
			stylebox.corner_radius_bottom_right = dict.get("corner_radius_bottom_right", 0)
			stylebox.corner_radius_top_left = dict.get("corner_radius_top_left", 0)
			stylebox.corner_radius_top_right = dict.get("corner_radius_top_right", 0)
			stylebox.shadow_color = get_color_from_dict(dict, "bg_color", Color("#000000cc"))
			stylebox.shadow_size = dict.get("shadow_size", 0)
		"texture":
			stylebox = HBUIStyleboxTexture.new()
			stylebox.axis_stretch_horizontal = dict.get("axis_stretch_horizontal", 0)
			stylebox.axis_stretch_vertical = dict.get("axis_stretch_vertical", 0)
			stylebox.draw_center = dict.get("draw_center", true)
			stylebox.modulate_color = get_color_from_dict(dict, "modulate_color", Color.WHITE)
			stylebox.texture = cache.get_texture(dict.get("texture", ""))
	# Shared properties
	if stylebox:
		stylebox.content_margin_bottom = dict.get("content_margin_bottom", 0)
		stylebox.content_margin_left = dict.get("content_margin_left", 0)
		stylebox.content_margin_right = dict.get("content_margin_right", 0)
		stylebox.content_margin_top = dict.get("content_margin_top", 0)
	return stylebox
	
func deserialize_font(data: Dictionary, font: HBUIFont, cache: HBSkinResourcesCache):
	if data:
		font.base_font = cache.get_font(data.get("name", ""))
		# Font size 0 crashes the engine... guard against it
		font.target_size = max(1, data.get("size", font.target_size))
		font.fallback_hint = data.get("fallback_hint", font.fallback_hint)
		font.outline_size = data.get("outline_size", font.outline_size)
		font.outline_color = get_color_from_dict(data, "outline_color", font.outline_color)
		font.spacing_top = data.get("spacing_top", font.spacing_top)
		font.spacing_bottom = data.get("spacing_bottom", font.spacing_bottom)
		font.spacing_glyph = data.get("extra_spacing_char", font.spacing_glyph)
	
