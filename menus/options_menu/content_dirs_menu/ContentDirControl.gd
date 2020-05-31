extends Panel

var normal_style
var hover_style
var dir setget set_dir
signal hover
signal pressed
onready var icon_panel = get_node("HBoxContainer/HBoxContainer/Panel")

func set_dir(val):
	dir = val
	$HBoxContainer/Label.text = ProjectSettings.globalize_path(dir)
func _init():
	normal_style = StyleBoxEmpty.new()
	hover_style = preload("res://styles/PanelStyleTransparentHover.tres")
func _ready():
	stop_hover()
	
func hover():
	icon_panel.add_stylebox_override("panel", hover_style)
	emit_signal("hover")

func stop_hover():
	add_stylebox_override("panel", normal_style)
	icon_panel.add_stylebox_override("panel", normal_style)

func _gui_input(event):
	if event.is_action_pressed("gui_accept"):
		get_tree().set_input_as_handled()
		emit_signal("pressed")
