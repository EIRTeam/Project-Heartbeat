extends Button

signal hovered

class_name HBHovereableButton

var target_opacity = 1.0

const LERP_SPEED = 3.0

export(StyleBox) var normal_style = preload("res://styles/PanelStyleTransparentIcon.tres")
export(StyleBox) var hover_style = preload("res://styles/PanelStyleTransparentIconHover.tres")
export (bool) var _test
func _process(delta):
	modulate.a = lerp(modulate.a, target_opacity, LERP_SPEED*delta)

func hover():
	add_stylebox_override("normal", hover_style)
	emit_signal("hovered")
func stop_hover():
	add_stylebox_override("normal", normal_style)

func _ready():
	stop_hover()
	add_stylebox_override("hover", hover_style)
