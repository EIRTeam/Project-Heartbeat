# In PH all input must be converted to InputEventActions for consistency between
# different controllers

extends Node

class_name HBGameInputManager

func get_action_press_count(action):
	return 0
	
func is_action_held(action):
	return false
func send_input(action, pressed, count = 1, event_uid="emulated"):
	var a = InputEventHB.new()
	a.action = action
	a.triggered_actions_count = count
	a.pressed = pressed
	a.event_uid = event_uid
	Input.parse_input_event(a)

func _input_received(event):
	pass

func _input(event):
	_input_received(event)

func get_event_uid(event):
	var event_uid = ""
	if event is InputEventKey:
		event_uid = "%d_%d" % [event.device, event.scancode]
	elif event is InputEventJoypadButton:
		event_uid = "%d_%d" % [event.device, event.button_index]
	elif event is InputEventJoypadMotion:
		event_uid = "AXIS%d_%d" % [event.device, event.axis]
	return event_uid
