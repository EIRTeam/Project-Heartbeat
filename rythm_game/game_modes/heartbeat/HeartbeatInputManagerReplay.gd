extends HeartbeatInputManager

class_name HeartbeatInputManagerReplay

var guid_to_index_map: Dictionary

var replay_reader: HBReplayReader:
	set(val):
		replay_reader = val
		guid_to_index_map.clear()
		if replay_reader:
			for i in range(replay_reader.get_gamepad_info_count()):
				guid_to_index_map[replay_reader.get_gamepad_guid(i)] = i

func _input(event: InputEvent) -> void:
	pass

var state: HBReplayStateSnapshot

func bitfield_to_action_list(b: HBReplay.EventActionBitfield) -> Array[String]:
	var arr_str: Array[String]

	if HBReplay.EventActionBitfield.NOTE_UP_B & b:
		arr_str.push_back("note_up")
	if HBReplay.EventActionBitfield.NOTE_LEFT_B & b:
		arr_str.push_back("note_left")
	if HBReplay.EventActionBitfield.NOTE_DOWN_B & b:
		arr_str.push_back("note_down")
	if HBReplay.EventActionBitfield.NOTE_RIGHT_B & b:
		arr_str.push_back("note_right")
	if HBReplay.EventActionBitfield.SLIDE_LEFT_B & b:
		arr_str.push_back("slide_left")
	if HBReplay.EventActionBitfield.SLIDE_RIGHT_B & b:
		arr_str.push_back("slide_right")
	if HBReplay.EventActionBitfield.HEART_NOTE_B & b:
		arr_str.push_back("heart_note")
	
	return arr_str

func action_name_to_action(action: String) -> HBReplay.EventAction:
	var out := HBReplay.NOTE_UP
	match action:
		"note_up":
			out = HBReplay.NOTE_UP
		"note_down":
			out = HBReplay.NOTE_DOWN
		"note_left":
			out = HBReplay.NOTE_LEFT
		"note_right":
			out = HBReplay.NOTE_RIGHT
		"slide_left":
			out = HBReplay.SLIDE_LEFT
		"slide_right":
			out = HBReplay.SLIDE_RIGHT
		"heart_note":
			out = HBReplay.HEART_NOTE
	return out
func is_action_held(action):
	if not state:
		return false
	
	return state.get_action_held_count(action_name_to_action(action)) > 0

func get_action_press_count(action):
	if not state:
		return 0
	return state.get_action_held_count(action_name_to_action(action))

func get_replay_event_uid(event: HBReplayEvent):
	var flags = 0
	var ev_device = 0
	var ev_scancode = 0
	ev_device = -1
	if event.event_type == HBReplay.EventType.KEYBOARD_KEY:
		ev_scancode = event.keyboard_key
	if event.event_type == HBReplay.EventType.GAMEPAD_BUTTON:
		ev_scancode = event.gamepad_button_index
		ev_device = guid_to_index_map[event.device_guid]
	if event.event_type == HBReplay.EventType.GAMEPAD_JOY_SINGLE_AXIS:
		flags += EVENT_FLAGS.IS_AXIS
		ev_scancode = event.get_joystick_axis(0)
		ev_device = guid_to_index_map[event.device_guid]
	var flags_size = 2
	return (ev_device << 8 + flags_size) + (ev_scancode << 16 + flags_size) + flags

func flush_inputs(prev_game_time_usec: float, new_game_time_usec: float, last_frame_time_usec: int):
	var rp_events := replay_reader.get_replay_events_in_interval(prev_game_time_usec, new_game_time_usec)
	for rp_event in rp_events:
		state = rp_event.get_state_snapshot()
		var game_event := InputEventHB.new()
		game_event.event_uid = get_replay_event_uid(rp_event)
		game_event.game_time = rp_event.game_timestamp
		var press_actions := bitfield_to_action_list(rp_event.press_actions)
		var release_actions := bitfield_to_action_list(rp_event.release_actions)
		game_event.actions = press_actions
		for action in press_actions:
			game_event.action = action
			game_event.pressed = true
			input_out.emit(game_event)

		var event_release_actions := []
		for action in release_actions:
			unhandled_release.emit(action, game_event.event_uid, game_event.game_time)
			if get_action_press_count(action) == 0:
				event_release_actions.push_back(action)
		
		game_event.pressed = false
		game_event.actions = event_release_actions
		for action in event_release_actions:
			game_event.action = action
			if get_action_press_count(action) == 0:
				input_out.emit(game_event)

		
