extends CheckBox

class_name HBHovereableCheckbox

export(StyleBox) var normal_style = preload("res://styles/PanelStyleTransparentIcon.tres")
export(StyleBox) var hover_style = preload("res://styles/PanelStyleTransparentIconHover.tres")

func hover():
	add_stylebox_override("normal", hover_style)
	add_stylebox_override("pressed", hover_style)
	emit_signal("hovered")
func stop_hover():
	add_stylebox_override("normal", normal_style)
	add_stylebox_override("pressed", normal_style)
