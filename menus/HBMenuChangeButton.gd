tool
extends Button

class_name HBMenuChangeButton

export (String) var next_menu

var normal_style = preload("res://styles/NewButtonStyle.tres")
var hover_style = preload("res://styles/NewButtonStyleHover.tres")

var target_opacity = 1.0

func _ready():
	focus_mode = Control.FOCUS_NONE
	flat = false
	align = ALIGN_LEFT
	add_stylebox_override("normal", normal_style)

func hover():
	add_stylebox_override("normal", hover_style)

func stop_hover():
	add_stylebox_override("normal", normal_style)
