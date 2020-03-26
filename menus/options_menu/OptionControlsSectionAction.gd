extends Panel

class_name HBOptionControlsSectionAction

var normal_style
var hover_style
var action setget set_action
signal hover
signal pressed
onready var icon_panel = get_node("HBoxContainer/HBoxContainer/Panel")

func set_action(val):
	$HBoxContainer/Label.text = val
	action = val
func _init():
	normal_style = StyleBoxEmpty.new()
	hover_style = preload("res://styles/PanelStyleTransparentHover.tres")

func _ready():
	stop_hover()

func hover():
	icon_panel.add_stylebox_override("panel", hover_style)
	emit_signal("hover")

func stop_hover():
	icon_panel.add_stylebox_override("panel", normal_style)

func _gui_input(event):
	if event.is_action_pressed("gui_accept"):
		get_tree().set_input_as_handled()
		emit_signal("pressed")
