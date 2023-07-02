extends HBUIComponent

class_name HBUIHealthDisplay

@onready var texture_progress_green := TextureProgressBar.new()
@onready var texture_progress_red := TextureProgressBar.new()
@onready var health_texture_progress := TextureProgressBar.new()
@onready var health_tween := Threen.new()

var fill_mode := 0: set = set_fill_mode

var progress_texture: Texture2D: set = set_progress_texture

var increase_color := Color(1.0, 1.0, 1.0, 0.5): set = set_increase_color
var decrease_color := Color(1.0, 1.0, 1.0, 0.5): set = set_decrease_color
var progress_color := Color.WHITE: set = set_progress_color

var health_test := 40.0: set = set_health_test

func get_hb_inspector_whitelist() -> Array:
	var whitelist := super.get_hb_inspector_whitelist()
	whitelist.append_array([
		"health_test", "increase_color", "decrease_color",
		"progress_color", "progress_texture", "fill_mode"
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
	
	register_texture_to_plist(list, "progress_texture")
	
	return list

func set_health_test(val):
	var old := health_test
	health_test = val
	if is_inside_tree():
		set_health(health_test, true, old)

func set_increase_color(val):
	increase_color = val
	if is_inside_tree():
		texture_progress_green.tint_progress = val

func set_decrease_color(val):
	decrease_color = val
	if is_inside_tree():
		texture_progress_red.tint_progress = val
		
		
func set_progress_color(val):
	progress_color = val
	if is_inside_tree():
		health_texture_progress.tint_progress = val

func set_progress_texture(val):
	progress_texture = val
	if is_inside_tree():
		texture_progress_green.texture_progress = progress_texture
		texture_progress_red.texture_progress = progress_texture
		health_texture_progress.texture_progress = progress_texture
	update_min_size()
func set_fill_mode(val):
	fill_mode = val
	if is_inside_tree():
		health_texture_progress.fill_mode = val
		texture_progress_red.fill_mode = val
		texture_progress_green.fill_mode = val

func update_min_size():
	if health_texture_progress:
		custom_minimum_size = health_texture_progress.get_minimum_size()

func _ready():
	super._ready()
	add_child(health_tween)
	add_child(texture_progress_green)
	add_child(texture_progress_red)
	add_child(health_texture_progress)
	
	texture_progress_green.max_value = 100
	texture_progress_red.max_value = 100
	health_texture_progress.max_value = 100
	
	texture_progress_green.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_progress_red.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	health_texture_progress.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	set_fill_mode(fill_mode)
	set_progress_texture(progress_texture)
	set_health_test(50.0)
	set_health(50.0, false, 40.0)
	
	set_increase_color(increase_color)
	set_decrease_color(decrease_color)
	set_progress_color(progress_color)

func set_health(health_value: float, animated := false, old_health := -1):
	if old_health == health_value:
		return
	health_tween.remove_all()
	if not texture_progress_red.visible:
		texture_progress_red.value = old_health
	texture_progress_red.hide()
	texture_progress_green.hide()
	if animated:
		if old_health != -1:
			if old_health < health_value:
				texture_progress_green.show()
				texture_progress_green.value = health_value
				health_tween.interpolate_property(health_texture_progress, "value", health_texture_progress.value, health_value, 0.2, 0, 2, 0.5)
			if health_value < old_health:
				texture_progress_red.show()
				health_texture_progress.value = health_value
				health_tween.interpolate_property(texture_progress_red, "value", texture_progress_red.value, health_value, 0.2, 0, 2, 0.5)
		else:
				health_tween.interpolate_property(health_texture_progress, "value", health_texture_progress.value, health_value, 0.2)
		health_tween.start()
	else:
		health_texture_progress.value = health_value

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := super._to_dict(resource_storage)
	out_dict["increase_color"] = increase_color.to_html()
	out_dict["decrease_color"] = decrease_color.to_html()
	out_dict["progress_color"] = progress_color.to_html()
	out_dict["progress_texture"] = resource_storage.get_texture_name(progress_texture)
	out_dict["fill_mode"] = fill_mode
	return out_dict
	
func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	super._from_dict(dict, cache)
	fill_mode = dict.get("fill_mode", fill_mode)
	increase_color = get_color_from_dict(dict, "increase_color", increase_color)
	decrease_color = get_color_from_dict(dict, "decrease_color", decrease_color)
	progress_color = get_color_from_dict(dict, "progress_color", progress_color)
	progress_texture = cache.get_texture(dict.get("progress_texture", ""))

static func get_component_id() -> String:
	return "health_display"

static func get_component_name() -> String:
	return "Health Display"
