# In PH all input must be converted to InputEventActions for consistency between
# different controllers

extends Node

class_name HBGameInputManager

func get_action_press_count(action):
	return 0
	
func is_action_held(action):
	return false
func send_input(action, pressed, count = 1):
	var a = InputEventHB.new()
	a.action = action
	a.triggered_actions_count = count
	a.pressed = pressed
	Input.parse_input_event(a)

func _input_received(event):
	pass

func _input(event):
	_input_received(event)
