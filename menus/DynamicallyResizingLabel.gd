extends Label

var font: DynamicFont

func _ready():
	connect("item_rect_changed", self, "_on_resized", [], CONNECT_DEFERRED)
	font = get_font("font")
func _on_resized():
	var calculated_string_size := float(font.get_string_size(text).x)
	if font.get_string_size(text).x > rect_size.x:
		var font_override = font.duplicate()
		font_override.size = (rect_size.x / calculated_string_size) * font.size
		add_font_override("font", font_override)
