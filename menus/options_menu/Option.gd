extends Panel

var normal_style
var hover_style
var value : set = set_value
signal hovered
signal changed(value)
#warning-ignore:unused_signal
signal back

var disabled := false
var disabled_callback: Callable

func set_value(val):
	value = val
func _init():
	normal_style = StyleBoxEmpty.new()
	hover_style = preload("res://styles/PanelStyleTransparentHover.tres")
	stop_hover()
func hover():
	add_theme_stylebox_override("panel", hover_style)
	emit_signal("hovered")

func update_disabled():
	if disabled_callback:
		disabled = disabled_callback.call()
		modulate = Color.WHITE
		if disabled:
			modulate = Color.GRAY

func stop_hover():
	add_theme_stylebox_override("panel", normal_style)

func change_value(new_value):
	emit_signal("changed", new_value)
