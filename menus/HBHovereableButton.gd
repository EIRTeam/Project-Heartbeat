extends Button

class_name HBHovereableButton

@export var normal_style: StyleBox = preload("res://styles/PanelStyleTransparentIcon.tres")
@export var hover_style: StyleBox = preload("res://styles/PanelStyleTransparentIconHover.tres")

signal hovered


var target_opacity = 1.0

const LERP_SPEED = 3.0

func _process(delta):
	modulate.a = lerp(modulate.a, target_opacity, LERP_SPEED*delta)

func hover():
	add_theme_stylebox_override("normal", hover_style)
	emit_signal("hovered")
func stop_hover():
	add_theme_stylebox_override("normal", normal_style)

func _ready():
	stop_hover()
	add_theme_stylebox_override("hover", hover_style)
	focus_mode = FOCUS_NONE
