extends CheckBox

class_name HBHovereableCheckbox

signal hovered

@export var normal_style: StyleBox = preload("res://styles/PanelStyleTransparentIcon.tres")
@export var hover_style: StyleBox = preload("res://styles/PanelStyleTransparentIconHover.tres")

func hover():
	add_theme_stylebox_override("normal", hover_style)
	add_theme_stylebox_override("pressed", hover_style)
	emit_signal("hovered")
func stop_hover():
	add_theme_stylebox_override("normal", normal_style)
	add_theme_stylebox_override("pressed", normal_style)
