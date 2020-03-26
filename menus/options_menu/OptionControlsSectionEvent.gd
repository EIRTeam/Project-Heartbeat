extends Panel

var normal_style
var hover_style
var event setget set_event
signal hover
signal pressed
onready var icon_panel = get_node("HBoxContainer/HBoxContainer/Panel")

func set_event(val):
	event = val	
	if event is InputEventJoypadMotion:
		var axis_sign = "+"
		if event.axis_value < 0:
			axis_sign = "-"
		$HBoxContainer/Label.text = UserSettings.get_axis_name(event)
	elif event is InputEventJoypadButton:
		$HBoxContainer/Label.text = UserSettings.get_button_name(event)
	elif event is InputEventKey:
		$HBoxContainer/Label.text = OS.get_scancode_string(event.scancode)
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
