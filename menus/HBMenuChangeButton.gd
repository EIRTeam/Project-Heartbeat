@tool
extends Button

class_name HBMenuChangeButton

@export var next_menu: String

var normal_style = preload("res://styles/NewButtonStyle.tres")
var hover_style = preload("res://styles/NewButtonStyleHover.tres")

var target_opacity = 1.0

func _ready():
	focus_mode = Control.FOCUS_NONE
	flat = false
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_stylebox_override("normal", normal_style)

func hover():
	add_theme_stylebox_override("normal", hover_style)

func stop_hover():
	add_theme_stylebox_override("normal", normal_style)
