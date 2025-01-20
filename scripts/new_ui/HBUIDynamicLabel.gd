extends Label

class_name HBUIDynamicLabel

var font: HBUIFont = preload("res://fonts/skined_fallback_font.tres"): set = set_font
var ignore_resize_hack := false

func _update_label_settings():
	if not label_settings:
		label_settings = LabelSettings.new()
	label_settings.font = font
	label_settings.outline_color = font.outline_color
	label_settings.outline_size = font.outline_size
func set_font(val):
	font = val
	_update_label_settings()
	if is_inside_tree():
		_fit_font()
func _ready():
	connect("resized", Callable(self, "_on_resized"))
	
func _fit_font():
	if font:
		if not label_settings:
			label_settings = LabelSettings.new()
		var test_target_size = font.target_size
		label_settings.font_size = test_target_size
		set_text(text)
		if not clip_text:
			set_text(text)
			await get_tree().process_frame
		else:
			return
		var string_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, test_target_size)
		if not autowrap_mode == TextServer.AUTOWRAP_ARBITRARY:
			while string_size.x > size.x:
				test_target_size -= 1
				string_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, test_target_size)
				if test_target_size <= 1:
					break
		label_settings.font_size = test_target_size
		if is_inside_tree():
			ignore_resize_hack = true
			await get_tree().process_frame
			ignore_resize_hack = false
func _on_resized():
	if not ignore_resize_hack:
		_fit_font()
	
func _set(property, value):
	if property == "text":
		if is_inside_tree():
			_fit_font()
