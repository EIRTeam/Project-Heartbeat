extends "Option.gd"

var options = ["Yes", "No"]
var options_pretty = []
var selected_option = 0
var text setget set_text

signal changed(option)

func set_text(value):
	text = value
	$HBoxContainer/Label.text = value

func _ready():
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	
func select(option: int):
	selected_option = option
	if options_pretty.size() > option:
		$HBoxContainer/Control/OptionLabel.text = options_pretty[option]
	else:
		$HBoxContainer/Control/OptionLabel.text = options[option]
	
func _gui_input(event):
	var option_change = 0
	if event.is_action_pressed("ui_left"):
		option_change = -1
		get_tree().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		option_change = 1
		get_tree().set_input_as_handled()

	if option_change != 0:
		select(clamp(selected_option+option_change, 0, options.size()-1))
		emit_signal("changed", options[selected_option])
		get_tree().set_input_as_handled()
