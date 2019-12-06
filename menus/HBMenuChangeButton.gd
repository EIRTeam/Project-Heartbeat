tool
extends Button

class_name HBMenuChangeButton

export (String) var next_menu

var normal_style = preload("res://styles/PanelStyleTransparent.tres")
var hover_style = preload("res://styles/PanelStyleTransparentHover.tres")

func _ready():
	focus_mode = Control.FOCUS_NONE
	flat = false
	align = ALIGN_LEFT

func hover():
	add_stylebox_override("normal", hover_style)

func stop_hover():
	add_stylebox_override("normal", normal_style)
