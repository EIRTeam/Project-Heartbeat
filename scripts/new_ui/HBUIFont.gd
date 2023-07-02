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
			fallbacks.push_back(preload("res://fonts/NotoSansJP-Regular.otf"))
		FALLBACK_HINT.BOLD, FALLBACK_HINT.BLACK:
			# TODO: Add different fallback fonts for black/bold
			fallbacks.push_back(preload("res://fonts/NotoSansJP-Black.otf"))

func _set(property, value):
	if property == "font_data":
		set_fallback_hint(fallback_hint)
