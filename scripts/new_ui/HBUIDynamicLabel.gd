extends Label

class_name HBUIDynamicLabel

var font: HBUIFont = preload("res://fonts/skined_fallback_font.tres"): set = set_font
var _internal_font: HBUIFont

func set_font(val):
	font = val
	_internal_font = font.duplicate()
	add_theme_font_override("font", _internal_font)
	_fit_font()
func _ready():
	connect("resized", Callable(self, "_on_resized"))
	
func _fit_font():
	if _internal_font:
		_internal_font.target_size = font.target_size
		if not clip_text:
			set_text(text)
			await get_tree().process_frame
		else:
			return
		var string_size := _internal_font.get_string_size(text)
		if not autowrap_mode == TextServer.AUTOWRAP_ARBITRARY:
			while string_size.x > size.x:
				_internal_font.target_size -= 1
				string_size = _internal_font.get_string_size(text)
				if _internal_font.target_size <= 1:
					break

func _on_resized():
	_fit_font()
	
func _set(property, value):
	if property == "text":
		_fit_font()
