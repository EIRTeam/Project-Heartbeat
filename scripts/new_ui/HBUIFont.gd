extends DynamicFont

class_name HBUIFont

enum FALLBACK_HINT {
	NORMAL,
	BOLD,
	BLACK
}

var fallback_hint: int = FALLBACK_HINT.NORMAL setget set_fallback_hint
func set_fallback_hint(val):
	fallback_hint = val
	while get_fallback_count() > 0:
		remove_fallback(0)
	match fallback_hint:
		FALLBACK_HINT.NORMAL:
			add_fallback(preload("res://fonts/NotoSansJP-Regular.otf"))
		FALLBACK_HINT.BOLD, FALLBACK_HINT.BLACK:
			# TODO: Add different fallback fonts for black/bold
			add_fallback(preload("res://fonts/NotoSansJP-Black.otf"))

func _set(property, value):
	if property == "font_data":
		set_fallback_hint(fallback_hint)
