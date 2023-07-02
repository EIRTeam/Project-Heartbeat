# In PH all input must be converted to InputEventActions for consistency between
# different controllers

extends Node

class_name HBGameInputManager

var _buffered_inputs = []

func _init():
	name = "GameInputManager"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func get_action_press_count(action):
	return 0
	
func reset():
	_buffered_inputs.clear()
	
func is_action_held(action):
	return false
func send_input(action, pressed, count = 1, event_uid=0b0, current_actions=[]):
	# When paused we only buffer release events...
	if pressed and get_tree().paused:
		return
	var a = InputEventHB.new()
	a.action = action
	a.triggered_actions_count = count
	a.pressed = pressed
	a.event_uid = event_uid
	a.actions = current_actions
	_buffered_inputs.append(a)

func _frame_end():
	_buffered_inputs.clear()

func flush_inputs():
	for input in _buffered_inputs:
		current_input_handled = false
		Input.parse_input_event(input)
	current_input_handled = false

func _input_received(event):
	pass

func _input(event):
	_input_received(event)

enum EVENT_FLAGS {
	IS_AXIS = 1 << 0,
	IS_DJA = 2 << 0
}

func get_dja_event_uid(axis: int) -> int:
	var flags = EVENT_FLAGS.IS_DJA
	var ev_device = UserSettings.controller_device_idx
	var ev_scancode = axis
	var flags_size = 2
	return (ev_device << 8 + flags_size) + (ev_scancode << 16 + flags_size) + flags

var current_input_handled = false

func set_input_as_handled():
	current_input_handled = true

func get_event_uid(event):
	var flags = 0
	var ev_device = 0
	var ev_scancode = 0
	ev_device = event.device
	if event is InputEventKey:
		ev_scancode = event.keycode
	elif event is InputEventJoypadButton:
		ev_scancode = event.button_index
	elif event is InputEventJoypadMotion:
		flags += EVENT_FLAGS.IS_AXIS
		ev_scancode = event.axis
	var flags_size = 2
	return (ev_device << 8 + flags_size) + (ev_scancode << 16 + flags_size) + flags
