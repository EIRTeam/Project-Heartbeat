# In PH all input must be converted to InputEventActions for consistency between
# different controllers

extends Node

class_name HBGameInputManager

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS

func get_action_press_count(action):
	return 0
	
func is_action_held(action):
	return false
func send_input(action, pressed, count = 1, event_uid=0b0):
	if not get_tree().paused:
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

enum EVENT_FLAGS {
	IS_AXIS = 1 << 0
}

func get_event_uid(event):
	var flags = 0
	var ev_device = 0
	var ev_scancode = 0
	ev_device = event.device
	if event is InputEventKey:
		ev_scancode = event.scancode
	elif event is InputEventJoypadButton:
		ev_scancode = event.button_index
	elif event is InputEventJoypadMotion:
		flags += EVENT_FLAGS.IS_AXIS
		ev_scancode = event.axis
	var flags_size = 1
	return (ev_device << 8 + flags_size) + (ev_scancode << 16 + flags_size) + flags
