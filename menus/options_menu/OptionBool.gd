extends "Option.gd"

var options = ["No", "Yes"]
var options_pretty = []
var selected_option = 0
var text setget set_text

func set_value(val):
	.set_value(val)
	var res = 1
	
	if not val:
		res = 0
	select(res)
func set_text(val):
	text = val
	$HBoxContainer/Label.text = val
func select(option: int):
	selected_option = option
	if options_pretty.size() > option:
		$HBoxContainer/Control/OptionLabel.text = options_pretty[option]
	else:
		$HBoxContainer/Control/OptionLabel.text = options[option]
func _ready():
	focus_mode = Control.FOCUS_ALL
	options = ["No", "Yes"]
func _on_changed(val):
	if val == "Yes":
		change_value(true)
	else:
		change_value(false)

func _gui_input(event):
	var option_change = 0
	if event.is_action_pressed("gui_left"):
		get_tree().set_input_as_handled()
		option_change = -1
	elif event.is_action_pressed("gui_right"):
		get_tree().set_input_as_handled()
		option_change = 1

	if option_change != 0:
		get_tree().set_input_as_handled()
		select(clamp(selected_option+option_change, 0, options.size()-1))
		var result = true
		if selected_option == 0:
			result = false
		change_value(result)

