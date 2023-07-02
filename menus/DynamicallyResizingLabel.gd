extends Label

var font: FontFile

func _ready():
	connect("item_rect_changed", Callable(self, "_on_resized").bind(), CONNECT_DEFERRED)
	font = get_font("font")
func _on_resized():
	var calculated_string_size := float(font.get_string_size(text).x)
	if font.get_string_size(text).x > size.x:
		var font_override = font.duplicate()
		font_override.size = (size.x / calculated_string_size) * font.size
		add_theme_font_override("font", font_override)
