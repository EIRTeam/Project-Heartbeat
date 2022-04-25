extends HBUIComponent

class_name HBUISongProgress

var fill_mode := 0 setget set_fill_mode

onready var texture_progress_ctrl := TextureProgress.new()

var texture_under: Texture setget set_texture_under
var texture_over: Texture setget set_texture_over
var texture_progress: Texture setget set_texture_progress

var tint_under := Color.white setget set_tint_under
var tint_over := Color.white setget set_tint_over
var tint_progress := Color.white setget set_tint_progress

var value := 75.0 setget set_value
var min_value := 0.0 setget set_min_value
var max_value := 100.0 setget set_max_value

func set_fill_mode(val):
	fill_mode = val
	if is_inside_tree():
		texture_progress_ctrl.fill_mode = fill_mode

func set_value(val):
	value = val
	if is_inside_tree():
		texture_progress_ctrl.value = value

func set_min_value(val):
	min_value = val
	if is_inside_tree():
		texture_progress_ctrl.min_value = min_value

func set_max_value(val):
	max_value = val
	if is_inside_tree():
		texture_progress_ctrl.max_value = max_value

static func get_component_id() -> String:
	return "song_progress"

func _ready():
	set_fill_mode(fill_mode)
	set_texture_under(texture_under)
	set_texture_over(texture_over)
	set_texture_progress(texture_progress)
	set_tint_under(tint_under)
	set_tint_over(tint_over)
	set_tint_progress(tint_progress)
	set_value(value)
	set_min_value(min_value)
	set_max_value(max_value)
	add_child(texture_progress_ctrl)
	texture_progress_ctrl.set_anchors_and_margins_preset(Control.PRESET_WIDE)

func set_tint_under(val):
	tint_under = val
	if is_inside_tree():
		texture_progress_ctrl.tint_under = tint_under
		
func set_tint_over(val):
	tint_over = val
	if is_inside_tree():
		texture_progress_ctrl.tint_over = tint_over
		
func set_tint_progress(val):
	tint_progress = val
	if is_inside_tree():
		texture_progress_ctrl.tint_progress = tint_progress
		
func set_texture_under(val):
	texture_under = val
	if is_inside_tree():
		texture_progress_ctrl.texture_under = texture_under
		
func set_texture_over(val):
	texture_over = val
	if is_inside_tree():
		texture_progress_ctrl.texture_over = texture_over
		
func set_texture_progress(val):
	texture_progress = val
	if is_inside_tree():
		texture_progress_ctrl.texture_progress = texture_progress
		
func get_hb_inspector_whitelist() -> Array:
	var whitelist := .get_hb_inspector_whitelist()
	whitelist.append_array([
		"fill_mode", "texture_under", "texture_over", "texture_progress",
		"tint_under", "tint_over", "tint_progress"
	])
	return whitelist

func _get_property_list():
	var list := []
	list.push_back({
		"name": "fill_mode",
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Left to Right,Right to Left,Top to Bottom,Bottom to Top,Clockwise,Counter Clockwise,Bilinear (Left and Right),Bilinear (Top and Bottom),Clockwise and Counter Clockwise",
		"type": TYPE_INT
	})
	
	register_texture_to_plist(list, "texture_under")
	register_texture_to_plist(list, "texture_over")
	register_texture_to_plist(list, "texture_progress")
	
	return list

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := ._to_dict(resource_storage)
	out_dict["texture_under"] = resource_storage.get_texture_name(texture_under)
	out_dict["texture_over"] = resource_storage.get_texture_name(texture_over)
	out_dict["texture_progress"] = resource_storage.get_texture_name(texture_progress)
	out_dict["fill_mode"] = fill_mode
	out_dict["tint_under"] = tint_under.to_html()
	out_dict["tint_over"] = tint_over.to_html()
	out_dict["tint_progress"] = tint_progress.to_html()
	return out_dict

func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	._from_dict(dict, cache)
	texture_under = cache.get_texture(dict.get("texture_under"))
	texture_over = cache.get_texture(dict.get("texture_over"))
	texture_progress = cache.get_texture(dict.get("texture_progress"))
	fill_mode = dict.get("fill_mode", 0)
	tint_under = Color(dict.get("tint_under", "#FFFFFF"))
	tint_over = Color(dict.get("tint_over", "#FFFFFF"))
	tint_progress = Color(dict.get("tint_progress", "#FFFFFF"))

static func get_component_name() -> String:
	return "Song Progress Indicator"
