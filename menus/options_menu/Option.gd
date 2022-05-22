extends Panel

var normal_style
var hover_style
var value setget set_value
signal hover
signal changed(value)
signal back

var disabled := false
var disabled_callback: FuncRef

func set_value(val):
	value = val
func _init():
	normal_style = StyleBoxEmpty.new()
	hover_style = preload("res://styles/PanelStyleTransparentHover.tres")
	stop_hover()
func hover():
	add_stylebox_override("panel", hover_style)
	emit_signal("hover")

func update_disabled():
	if disabled_callback:
		disabled = disabled_callback.call_func()
		modulate = Color.white
		if disabled:
			modulate = Color.gray

func stop_hover():
	add_stylebox_override("panel", normal_style)

func change_value(new_value):
	emit_signal("changed", new_value)
