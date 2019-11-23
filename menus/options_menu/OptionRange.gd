extends Control

export(float) var minimum = 0.0
export(float) var maximum = 10
export(float) var step = 1

var value = 0 setget set_value
signal changed(option)

onready var text_label = get_node("OptionRange/HBoxContainer/Label")
onready var option_label = get_node("OptionRange/HBoxContainer/Control/OptionLabel")
var hover_style
var normal_style
signal hover
var text setget set_text
func _init():
	normal_style = StyleBoxEmpty.new()
	hover_style = preload("res://styles/PanelStyleTransparentHover.tres")
	
func hover():
	$OptionRange.add_stylebox_override("panel", hover_style)
	emit_signal("hover")

func stop_hover():
	$OptionRange.add_stylebox_override("panel", normal_style)

func set_text(value):
	text_label.text = value

func set_value(val):
	value = val
	option_label.text = str(value)

func _ready():
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	stop_hover()
	
func _gui_input(event):
	var option_change = 0
	if event.is_action_pressed("ui_left"):
		option_change = -step
		get_tree().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		option_change = step
		get_tree().set_input_as_handled()
	if option_change != 0:
		set_value(clamp(value+option_change, minimum, maximum))
		emit_signal("changed", value)
	
	var normal_style



