extends FontVariation

class_name HBUIFont

enum FALLBACK_HINT {
	NORMAL,
	BOLD,
	BLACK
}

var fallback_hint: int = FALLBACK_HINT.NORMAL: set = set_fallback_hint
var target_size := 16
var outline_size := 0
var outline_color: Color

func set_fallback_hint(val):
	fallback_hint = val
	fallbacks.clear()
	match fallback_hint:
		FALLBACK_HINT.NORMAL:
			fallbacks.push_back(preload("res://fonts/default_font_regular.tres"))
		FALLBACK_HINT.BOLD:
			fallbacks.push_back(preload("res://fonts/default_font_bold.tres"))
		FALLBACK_HINT.BLACK:
			fallbacks.push_back(preload("res://fonts/default_font_black.tres"))

func _set(property, value):
	if property == "font_data":
		set_fallback_hint(fallback_hint)
