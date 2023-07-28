extends Label

class_name HBUIDynamicLabel

var font: HBUIFont = preload("res://fonts/skined_fallback_font.tres"): set = set_font
var _internal_font: HBUIFont
var ignore_resize_hack := false

func set_font(val):
	font = val
	_internal_font = font.duplicate()
	add_theme_font_override("font", _internal_font)
	if is_inside_tree():
		_fit_font()
func _ready():
	connect("resized", Callable(self, "_on_resized"))
	
func _fit_font():
	if _internal_font:
		if not label_settings:
			label_settings = LabelSettings.new()
		_internal_font.target_size = font.target_size
		label_settings.font_size = font.target_size
		set_text(text)
		if not clip_text:
			set_text(text)
			await get_tree().process_frame
		else:
			return
		var string_size := _internal_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _internal_font.target_size)
		if not autowrap_mode == TextServer.AUTOWRAP_ARBITRARY:
			while string_size.x > size.x:
				_internal_font.target_size -= 1
				string_size = _internal_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _internal_font.target_size)
				if _internal_font.target_size <= 1:
					break
		label_settings.font_size = _internal_font.target_size
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
