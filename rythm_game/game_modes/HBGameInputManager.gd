# In PH all input must be converted to InputEventActions for consistency between
# different controllers

extends Node

class_name HBGameInputManager

signal input_out(event: InputEventHB)

var current_ev: InputEventHB

var _buffered_inputs = []
var replay_events: Array[HBReplayEvent]

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
	replay_events.clear()
	
func is_action_held(action):
	return false
	
var f := FileAccess.open("user://replaydump.txt", FileAccess.WRITE)
	
var replay_data := HBReplayWriter.new()
	
var last_extra_replay_event_time: int

const EXTRA_REPLAY_EVENT_MAX_RATE := 60 # Events per second
const EXTA_REPLAY_EVENT_RATE_LIMIT_DURATION := 100_000 / EXTRA_REPLAY_EVENT_MAX_RATE
	
## Stores a replay event
## if [param is_extra] is set to [code]true[/code], the event may be dropped
## as it doesn't affect final gameplay and is subject to rate limits
func store_replay_event(event: HBReplayEvent):
	# While rolling back we should only store release events
	if get_tree().paused and event.press_actions != 0:
		return
		
	replay_events.push_back(event)
	var ev_type_name := ""
	var specific_data_line := ""
	
	match event.event_type:
		HBReplay.GAMEPAD_JOY_SINGLE_AXIS:
			ev_type_name = "GAMEPAD_JOY_SINGLE_AXIS"
			specific_data_line = "DEV: %d AXIS: %d JOYPOS: %.2f" % [event.device_guid, event.get_joystick_axis(0), event.joystick_position.x]
		HBReplay.GAMEPAD_JOY:
			ev_type_name = "GAMEPAD_JOY"
			specific_data_line = "DEV: %s AXIS0: %d AXIS1: %d JOYX: %.2f JOYY: %.2f" % [event.device_guid, event.get_joystick_axis(0), event.get_joystick_axis(1), event.joystick_position.x, event.joystick_position.y]
		HBReplay.GAMEPAD_BUTTON:
			ev_type_name = "GAMEPAD_BUTTON"
			specific_data_line = "DEV: %s BUTTON: %d" % [event.device_guid, event.gamepad_button_index]
		HBReplay.KEYBOARD_KEY:
			ev_type_name = "KEYBOARD_KEY"
			specific_data_line = "KEY: %d" % [event.keyboard_key]
	
	replay_data.song_id = "song_id"
	replay_data.song_chart_hash = "hash"
	replay_data.song_difficulty = "difficulty"
	replay_data.push_event(event)
	
	var replay_data_line := "%s %d %d - %s" % [ev_type_name, event.press_actions, event.release_actions, specific_data_line]
	
	f.store_line(replay_data_line)
	f.flush()
	
func send_input(action, pressed, source_event: HBReplayEvent, count = 1, event_uid=0b0, current_actions=[], timestamp := -1):
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
	a.replay_event = source_event
	_buffered_inputs.append(a)

func _frame_end():
	_buffered_inputs.clear()

static func action_list_to_bitfield(action_list: Array) -> HBReplay.EventActionBitfield:
	var bitfield: HBReplay.EventActionBitfield = 0
	for action in action_list:
		match action:
			"note_up":
				bitfield |= HBReplay.EventActionBitfield.NOTE_UP_B
			"note_left":
				bitfield |= HBReplay.EventActionBitfield.NOTE_LEFT_B
			"note_down":
				bitfield |= HBReplay.EventActionBitfield.NOTE_DOWN_B
			"note_right":
				bitfield |= HBReplay.EventActionBitfield.NOTE_RIGHT_B
			"slide_left":
				bitfield |= HBReplay.EventActionBitfield.SLIDE_LEFT_B
			"slide_right":
				bitfield |= HBReplay.EventActionBitfield.SLIDE_RIGHT_B
			"heart_note":
				bitfield |= HBReplay.EventActionBitfield.HEART_NOTE_B
	return bitfield

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
	if event is InputEventKey:
		if event.keycode == KEY_F1 and event.pressed() and not event.is_echo():
			var f2 := FileAccess.open("user://replaydump.phr", FileAccess.WRITE)
			var buff := replay_data.write_to_buffer()
			f2.store_buffer(buff)
			f2.flush()
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
