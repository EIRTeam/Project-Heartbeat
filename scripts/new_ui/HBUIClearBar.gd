extends HBUIComponent

class_name HBUIClearBar

const CLEAR_POINT = 0.75


var value = 90.0: set = set_value
var max_value = 100.0: set = set_max_value
var potential_score = 90.0


var top_clear_margin := 0: set = set_top_clear_margin
var bottom_clear_margin := 0: set = set_bottom_clear_margin

var progress_bar := TextureProgressBar.new()

var clear_separator_color := Color("a90d5d"): set = set_clear_separator_color
var excellent_line_color := Color.WHITE: set = set_excellent_line_color
var great_line_color := Color.WHITE: set = set_great_line_color
var standard_line_color := Color.WHITE: set = set_standard_line_color
var percentage_font := HBUIFont.new(): set = set_percentage_font
var stylebox: StyleBox = HBUIStyleboxFlat.new(): set = set_stylebox
var stylebox_post_pass: StyleBox = HBUIStyleboxFlat.new(): set = set_stylebox_post_pass
var rating_lines_extra_height := 10.0: set = set_rating_lines_extra_height
var clear_line_extra_height := 12.0: set = set_clear_line_extra_height

# Test value for HBInspector
var test_value: float: get = get_test_value, set = set_test_value
func set_test_value(val):
	set_value(val)
func get_test_value():
	return value 

@onready var percentage_label := HBUIDynamicLabel.new()

func set_rating_lines_extra_height(val):
	rating_lines_extra_height = val
	queue_redraw()

func set_excellent_line_color(val):
	excellent_line_color = val
	queue_redraw()

func set_great_line_color(val):
	great_line_color = val
	queue_redraw()

func set_standard_line_color(val):
	standard_line_color = val
	queue_redraw()

func set_clear_separator_color(val):
	clear_separator_color = val
	queue_redraw()

func set_percentage_font(val):
	percentage_font = val
	if is_inside_tree():
		set_control_font(percentage_label, "font", percentage_font)

func set_clear_line_extra_height(val):
	clear_line_extra_height = val
	queue_redraw()

func set_stylebox(val):
	stylebox = val
	queue_redraw()

func set_stylebox_post_pass(val):
	stylebox_post_pass = val
	queue_redraw()

func set_value(val):
	value = val
	queue_redraw()
	if max_value > 0:
		percentage_label.text = "%.2f " % ((value / max_value) * 100.0)
		percentage_label.text += "%"
func set_max_value(val):
	max_value = val
	queue_redraw()

func apply_margin(rect: Rect2) -> Rect2:
	rect.position.y += top_clear_margin
	rect.size.y -= top_clear_margin + bottom_clear_margin
	return rect

func _ready():
	super._ready()
	percentage_label.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
	percentage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percentage_label.clip_text = true
	add_child(percentage_label)
	set_max_value(max_value)
	set_value(value)
	set_stylebox(stylebox)
	set_stylebox_post_pass(stylebox_post_pass)
	set_percentage_font(percentage_font)
	set_standard_line_color(standard_line_color)
	set_excellent_line_color(excellent_line_color)
	set_great_line_color(great_line_color)
	set_clear_separator_color(clear_separator_color)
	set_rating_lines_extra_height(rating_lines_extra_height)
	
func set_top_clear_margin(val):
	top_clear_margin = val
	queue_redraw()

func set_bottom_clear_margin(val):
	bottom_clear_margin = val
	queue_redraw()

func _draw():
	var origin = Vector2(0,0)
	if max_value != 0:
		size.x = size.x * (value / max_value)
	else:
		size.x = 0
	
	var rect_clear = Rect2(Vector2(size.x * CLEAR_POINT, 0), Vector2(size.x * (1 - CLEAR_POINT), size.y))
	
	rect_clear = apply_margin(rect_clear)
	draw_rect(rect_clear, clear_separator_color)
	var progress_rect = Rect2(origin, size)
	progress_rect = apply_margin(progress_rect)
	draw_style_box(stylebox, progress_rect)
	
	var past_completion_size = size
	if max_value != 0:
		past_completion_size.x = past_completion_size.x * ((value-(max_value*CLEAR_POINT)) / max_value)
	else:
		past_completion_size.x = 0
	
	if past_completion_size.x > 0:
		var past_completion_progress_rect = Rect2(Vector2(size.x * CLEAR_POINT, 0), past_completion_size)
		past_completion_progress_rect = apply_margin(past_completion_progress_rect)
		
		draw_style_box(stylebox_post_pass, past_completion_progress_rect)
	draw_rating_line(HBGame.EXCELLENT_THRESHOLD, excellent_line_color)
	draw_rating_line(HBGame.GREAT_THRESHOLD, great_line_color)
	draw_rating_line(HBGame.PASS_THRESHOLD, standard_line_color)
	draw_line(origin+Vector2(size.x * CLEAR_POINT, -clear_line_extra_height), origin+Vector2(size.x * CLEAR_POINT, size.y), Color.RED, 3)
	percentage_label.position = Vector2(size.x * CLEAR_POINT, 0)
	percentage_label.size = Vector2(size.x * (1.0-CLEAR_POINT), size.y)

func draw_rating_line(val, color=Color.WHITE, height=10):
	if max_value != 0:
		var val_r = round(potential_score) / max_value
		var origin = Vector2(size.x * (val_r * val), -height)
		var end = Vector2(origin.x, size.y)
		draw_line(origin, end, color, 3)

func _get_property_list():
	var list := []
	register_subresource_to_plist(list, "stylebox")
	register_subresource_to_plist(list, "stylebox_post_pass")
	return list

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := super._to_dict(resource_storage)
	out_dict["stylebox"] = serialize_stylebox(stylebox, resource_storage)
	out_dict["stylebox_post_pass"] = serialize_stylebox(stylebox_post_pass, resource_storage)
	out_dict["percentage_font"] = serialize_font(percentage_font, resource_storage)
	out_dict["top_clear_margin"] = top_clear_margin
	out_dict["bottom_clear_margin"] = bottom_clear_margin
	out_dict["clear_separator_color"] = clear_separator_color.to_html()
	out_dict["excellent_line_color"] = excellent_line_color.to_html()
	out_dict["great_line_color"] = great_line_color.to_html()
	out_dict["standard_line_color"] = standard_line_color.to_html()
	out_dict["rating_lines_extra_height"] = rating_lines_extra_height
	out_dict["clear_line_extra_height"] = clear_line_extra_height
	return out_dict
	
func get_hb_inspector_whitelist() -> Array:
	var whitelist := super.get_hb_inspector_whitelist()
	whitelist.append_array([
		"stylebox", "stylebox_post_pass", "test_value", "percentage_font", "top_clear_margin", "bottom_clear_margin",
		"clear_separator_color", "excellent_line_color", "great_line_color", "standard_line_color"
	])
	return whitelist
	
func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	super._from_dict(dict, cache)
	
	stylebox = deserialize_stylebox(dict.get("stylebox", {}), cache, stylebox)
	stylebox_post_pass = deserialize_stylebox(dict.get("stylebox_post_pass", {}), cache, stylebox_post_pass)
	deserialize_font(dict.get("percentage_font", {}), percentage_font, cache)
	top_clear_margin = dict.get("top_clear_margin", 0)
	bottom_clear_margin = dict.get("bottom_clear_margin", 0)
	clear_separator_color = get_color_from_dict(dict, "clear_separator_color", clear_separator_color)
	great_line_color = get_color_from_dict(dict, "great_line_color", great_line_color)
	standard_line_color = get_color_from_dict(dict, "standard_line_color", standard_line_color)
	excellent_line_color = get_color_from_dict(dict, "excellent_line_color", excellent_line_color)
	rating_lines_extra_height = dict.get("rating_lines_extra_height", 10.0)
	clear_line_extra_height = dict.get("clear_line_extra_height", 12.0)
static func get_component_id() -> String:
	return "clear_bar"

static func get_component_name() -> String:
	return "Clear Bar"
