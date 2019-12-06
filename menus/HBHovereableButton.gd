extends Button

signal hovered

class_name HBHovereableButton

var normal_style = preload("res://styles/PanelStyleTransparentIcon.tres")
var hover_style = preload("res://styles/PanelStyleTransparentIconHover.tres")

func hover():
	add_stylebox_override("normal", hover_style)
	emit_signal("hovered")
func stop_hover():
	add_stylebox_override("normal", normal_style)

func _ready():
	stop_hover()
