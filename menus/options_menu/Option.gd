extends Panel

var normal_style
var hover_style
var value setget set_value
signal hover
func set_value(val):
	value = val
func _init():
	normal_style = StyleBoxEmpty.new()
	hover_style = preload("res://styles/PanelStyleTransparentHover.tres")
	stop_hover()
func hover():
	add_stylebox_override("panel", hover_style)
	emit_signal("hover")

func stop_hover():
	add_stylebox_override("panel", normal_style)
