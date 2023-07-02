extends "Option.gd"

var options = ["No", "Yes"]
var options_pretty = []
var selected_option = 0
var text : set = set_text

@onready var checkbox: CheckBox = get_node("HBoxContainer/Control/CheckBox")

func set_value(val):
	super.set_value(val)
	select(val)
	
func select(val: bool):
	checkbox.set_block_signals(true)
	checkbox.button_pressed = val
	checkbox.set_block_signals(false)
	
func set_text(val):
	text = val
	$HBoxContainer/Label.text = val
func _ready():
	focus_mode = Control.FOCUS_ALL

func _gui_input(event):
	if event.is_action_pressed("gui_accept"):
		get_viewport().set_input_as_handled()
		set_value(!value)
		select(value)
		change_value(value)



func _on_CheckBox_toggled(button_pressed):
	set_value(button_pressed)
	change_value(button_pressed)
