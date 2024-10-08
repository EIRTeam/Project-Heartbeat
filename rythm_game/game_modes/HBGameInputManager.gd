# In PH all input must be converted to InputEventActions for consistency between
# different controllers

extends Node

class_name HBGameInputManager

signal input_out(event: InputEventHB)

var current_ev: InputEventHB

var _buffered_inputs = []

enum DEVICE_TYPE {
	JOYPAD,
	OTHER
}

# This is used for deciding what device to vibrate, however since inputs are buffered and flushed all together
# this might be problematic by failing to trigger vibration if say a keyboard is used on the same frame as a gamepad
# but you'd have to be a special kind of retard to complain about something like this that no other rhythm game supports
var last_action_device_idx := -1
var last_action_device_type := DEVICE_TYPE.OTHER

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
	
func send_input(action, pressed, count = 1, event_uid=0b0, current_actions=[], timestamp := -1):
	# When paused we only buffer release events...
	if pressed and get_tree().paused:
		return
	var a = InputEventHB.new()
	a.action = action
	a.triggered_actions_count = count
	a.pressed = pressed
	a.event_uid = event_uid
	a.actions = current_actions
	a.timestamp = timestamp
	_buffered_inputs.append(a)

func _frame_end():
	_buffered_inputs.clear()

func event_time_to_game_time(event_time: int, prev_game_time_usec: float, new_game_time_usec: float, last_frame_time_usec: int) -> int:
	var out_game_time := 0
	if event_time == -1:
		out_game_time = new_game_time_usec
	else:
		out_game_time = clamp(prev_game_time_usec + ((last_frame_time_usec - event_time)), prev_game_time_usec, new_game_time_usec)
	return out_game_time

func flush_inputs(prev_game_time_usec: float, new_game_time_usec: float, last_frame_time_usec: int):
	var current_frame_time_usec := Time.get_ticks_usec()
	for input: InputEventHB in _buffered_inputs:
		if input.timestamp == -1 or get_tree().paused:
			input.game_time = new_game_time_usec
		else:
			input.game_time = clamp(prev_game_time_usec + ((last_frame_time_usec - input.timestamp)), prev_game_time_usec, new_game_time_usec)
		current_ev = input
		input_out.emit(input)

func _input_received(event):
	pass

func _input(event):
	_input_received(event)

enum EVENT_FLAGS {
	IS_AXIS = 1 << 0,
	IS_DJA = 2 << 0
}

func get_dja_event_uid(device_idx: int, axis: int) -> int:
	var flags = EVENT_FLAGS.IS_DJA
	var ev_device = device_idx
	var ev_scancode = axis
	var flags_size = 2
	return (ev_device << 8 + flags_size) + (ev_scancode << 16 + flags_size) + flags

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
