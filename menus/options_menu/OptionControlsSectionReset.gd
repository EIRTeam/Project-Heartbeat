extends Panel

var normal_style
var hover_style
signal hovered
signal pressed

func _init():
	normal_style = StyleBoxEmpty.new()
	hover_style = preload("res://styles/PanelStyleTransparentHover.tres")
func _ready():
	stop_hover()
func hover():
	add_theme_stylebox_override("panel", hover_style)
	emit_signal("hovered")

func stop_hover():
	add_theme_stylebox_override("panel", normal_style)

func _gui_input(event):
	if event.is_action_pressed("gui_accept"):
		get_viewport().set_input_as_handled()
		emit_signal("pressed")
