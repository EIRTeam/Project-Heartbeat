extends HBGameInputManager

class_name HeartbeatInputManager

signal unhandled_release(event, event_uid, game_time_usec: int)

var digital_action_tracking = {}

const TRACKED_ACTIONS = ["note_up", "note_down", "note_left", "note_right", "slide_left", "slide_right", "heart_note"]

const DIRECT_AXIS = [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]
const DIRECT_AXIS_ACTIONS = ["heart_note", "slide_left", "slide_right"]

const BIDIRECTIONAL_ACTIONS = [
	"heart_note"
]

var current_event: InputEvent # Current event being converted to action
var current_actions: Array = []
var last_axis_values = {}

const LOG_LOCATION := "user://input_log.txt"
var should_log_input := "--ph-log-input" in OS.get_cmdline_args()

var log_file: FileAccess

const EVENT_TIMESTAMP_META_KEY := &"event_timestamp"

class UnhandledRelease:
	var action: String
	var timestamp: int
	var event_uid: int
var _buffered_unhandled_releases: Array[UnhandledRelease]

func _ready() -> void:
	super._ready()
	Input.joy_connection_changed.connect(self._on_joy_connection_changed)
	if should_log_input:
		log_file = FileAccess.open(LOG_LOCATION, FileAccess.WRITE)

func send_input(action, pressed, count = 1, event_uid=0b0, current_actions=[], timestamp := -1):
	super.send_input(action, pressed, count, event_uid, current_actions, timestamp)

	if log_file:
		log_file.store_line("Game event: %s (%s) %d event uid: %X pressed: %s" % [action, str(current_actions), count, event_uid, "yes" if pressed else "no"])
		log_file.flush()

class JoypadDeviceData:
	var device_idx := 0
	var direct_joysticks: Array[HBJoystickData]
	var debug_windows: Array[HBAnalogInputProcessorDebug]
	
	func uses_direct_joypad_access() -> bool:
		return UserSettings.should_use_direct_joystick_access(device_idx)
	
	func _init(_device_idx: int) -> void:
		device_idx = _device_idx
		direct_joysticks = [
			HBJoystickData.new(device_idx, JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y),
			HBJoystickData.new(device_idx, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y)
		]

var joypad_device_datas: Dictionary

func get_or_create_joypad_device_data(device: int) -> JoypadDeviceData:
	if not device in joypad_device_datas:
		assert(device in Input.get_connected_joypads())
		var dv := JoypadDeviceData.new(device)
		joypad_device_datas[device] = dv
		for joystick in dv.direct_joysticks:
			var debug_w := HBAnalogInputProcessorDebug.new()
			joystick.set_meta("debug_w", debug_w)
			dv.debug_windows.push_back(debug_w)
		
		for w in dv.debug_windows:
			w.hide()
			add_child(w)
	return joypad_device_datas[device]

func reset():
	super.reset()
	last_axis_values = {}
	current_actions = []
	digital_action_tracking = {}
	_buffered_unhandled_releases = []
	

func get_action_press_count(action):
	return _get_analog_action_held_count(action) + _get_digital_action_held_count(action)

func _is_axis_held(device, action, axis):
	if abs(last_axis_values[device][action][axis]) >= _get_action_deadzone(action):
		return true
	else:
		return false

func is_action_held(action):
	return (_get_digital_action_held_count(action) + _get_analog_action_held_count(action)) > 0

func _get_digital_action_held_count(action):
	var count = 0
	if digital_action_tracking.has(action):
		for device in digital_action_tracking[action]:
			for button in digital_action_tracking[action][device]:
				if digital_action_tracking[action][device][button]:
					count += 1
	return count

func _get_action_deadzone(action: String):
	var deadzone = UserSettings.user_settings.analog_deadzone
	return deadzone
	
func _get_analog_action_bit(action: String) -> int:
	var bit := 0
	
	match action:
		"slide_left":
			bit = HBJoystickData.EVENT_STATES.SLIDE_LEFT
		"slide_right":
			bit = HBJoystickData.EVENT_STATES.SLIDE_RIGHT
		"heart_note":
			bit = HBJoystickData.EVENT_STATES.HEART
	
	assert(bit != 0)
	return bit
	
func _get_analog_action_name(action: int) -> String:
	var bit := ""
	
	match action:
		HBJoystickData.EVENT_STATES.SLIDE_LEFT:
			bit = "slide_left"
		HBJoystickData.EVENT_STATES.SLIDE_RIGHT:
			bit = "slide_right"
		HBJoystickData.EVENT_STATES.HEART:
			bit = "heart_note"
	
	assert(not bit.is_empty())
	return bit
	
func _on_joy_connection_changed(gamepad_i: int, connected: bool):
	if not connected:
		if gamepad_i in joypad_device_datas:
			joypad_device_datas.erase(gamepad_i)
	
func _get_analog_action_held_count(action):
	var count = 0
	if action in DIRECT_AXIS_ACTIONS:
		var bit := _get_analog_action_bit(action)
		for device: JoypadDeviceData in joypad_device_datas.values():
			for joy in device.direct_joysticks:
				if bit & joy.event_states:
					count += 1
		
	for device in last_axis_values:
		if action in last_axis_values[device]:
			for axis in last_axis_values[device][action]:
				if abs(last_axis_values[device][action][axis]) >= _get_action_deadzone(action):
					if not UserSettings.should_use_direct_joystick_access(device) or not axis in DIRECT_AXIS:
						count += 1
	return count
func _is_action_held_analog(action):
	return _get_analog_action_held_count(action) > 0

func _is_in_slide_range(value: Vector2):
	return abs((Vector2.RIGHT * sign(value.x)).angle_to(value)) < deg_to_rad(UserSettings.user_settings.direct_joystick_slider_angle_window) * 0.5

class ProcessedAnalogInputEvent:
	var device: int
	var joystick: int
	var action: int
	var actions: Array
	var used_extrapolation := false
	var pressed := false
	var timestamp: int

func process_joystick_events(joystick: HBJoystickData) -> Array[ProcessedAnalogInputEvent]:
	var merged_events := joystick.merge_events()
	var out_merged_events: Array[ProcessedAnalogInputEvent]
	var debug_w := joystick.get_meta("debug_w") as HBAnalogInputProcessorDebug
	for event in merged_events:
		var val := event.value
		var prev_joystick_state := joystick.joy_value
		if event.axises & HBJoystickData.AXIS_BITFIELD.X:
			joystick.joy_value.x = event.value.x
		if event.axises & HBJoystickData.AXIS_BITFIELD.Y:
			joystick.joy_value.y = event.value.y
		debug_w.display_input(joystick.joy_value)
		
		var just_hearted := false
		var heart_just_released := false
		var heart_release_event: ProcessedAnalogInputEvent
		var heart_press_event: ProcessedAnalogInputEvent
		var deadzone_inner: float = UserSettings.user_settings.direct_joystick_deadzone - 0.1
		var deadzone_outer: float = UserSettings.user_settings.direct_joystick_deadzone
		var pushed_event := false
		if joystick.event_states & HBJoystickData.EVENT_STATES.HEART && (joystick.joy_value.length() < deadzone_inner or HBJoystickData.event_intersects_deadzone(deadzone_inner, prev_joystick_state, joystick.joy_value)):
			joystick.event_states = joystick.event_states &(~HBJoystickData.EVENT_STATES.HEART)
			heart_just_released = true
			if get_action_press_count(_get_analog_action_name(HBJoystickData.EVENT_STATES.HEART)) == 0:
				pushed_event = true
				heart_release_event = ProcessedAnalogInputEvent.new()
				heart_release_event.pressed = false
				heart_release_event.action = HBJoystickData.EVENT_STATES.HEART
				heart_release_event.joystick = joystick.x_axis_idx
				heart_release_event.device = joystick.device_idx
				heart_release_event.timestamp = event.timestamp
			
				if joystick.joy_value.length() > deadzone_inner and HBJoystickData.event_intersects_deadzone(deadzone_inner, prev_joystick_state, joystick.joy_value):
					heart_release_event.used_extrapolation = true
				out_merged_events.push_back(heart_release_event)
		if (joystick.event_states & HBJoystickData.EVENT_STATES.HEART == 0) && joystick.joy_value.length() > deadzone_outer:
			pushed_event = true
			
			heart_press_event = ProcessedAnalogInputEvent.new()
			heart_press_event.pressed = true
			heart_press_event.action = HBJoystickData.EVENT_STATES.HEART
			heart_press_event.joystick = joystick.x_axis_idx
			heart_press_event.device = joystick.device_idx
			heart_press_event.timestamp = event.timestamp
			out_merged_events.push_back(heart_press_event)
			
			just_hearted = true
			joystick.event_states = joystick.event_states | HBJoystickData.EVENT_STATES.HEART
		
		var angular_deadzone := deg_to_rad(UserSettings.user_settings.direct_joystick_slider_angle_window)
		for slide_side in [HBJoystickData.EVENT_STATES.SLIDE_LEFT, HBJoystickData.EVENT_STATES.SLIDE_RIGHT]:
			var dir := Vector2.RIGHT if slide_side == HBJoystickData.EVENT_STATES.SLIDE_RIGHT else Vector2.LEFT
			if joystick.event_states & slide_side == 0 and just_hearted && abs(dir.angle_to(joystick.joy_value)) < angular_deadzone * 0.5:
				pushed_event = true
				
				var ev := ProcessedAnalogInputEvent.new()
				ev.pressed = true
				ev.action = slide_side
				ev.actions = [slide_side, HBJoystickData.EVENT_STATES.HEART]
				heart_press_event.actions = [slide_side, HBJoystickData.EVENT_STATES.HEART]
				ev.joystick = joystick.x_axis_idx
				ev.device = joystick.device_idx
				ev.timestamp = event.timestamp
				out_merged_events.push_back(ev)
				
				joystick.event_states = joystick.event_states |  slide_side
			if joystick.event_states & slide_side and ((heart_just_released and not just_hearted) or abs(dir.angle_to(joystick.joy_value)) >= angular_deadzone * 0.5):
				joystick.event_states = joystick.event_states & (~slide_side)
			
	return out_merged_events

func flush_inputs(prev_game_time_usec: float, new_game_time_usec: float, last_frame_time_usec: int):
	for joystick_v in joypad_device_datas.values():
		var joystick_device := joystick_v as JoypadDeviceData
		if not joystick_device.uses_direct_joypad_access():
			continue
		for joystick in joystick_device.direct_joysticks:
			var events := process_joystick_events(joystick)
			for event in events:
				var actions := event.actions.map(func(a: int): return _get_analog_action_name(a))
				var main_action := _get_analog_action_name(event.action)
				send_input(main_action, event.pressed, event.actions.size(), get_dja_event_uid(joystick_device.device_idx, event.joystick), actions, event.timestamp)
	for uh in _buffered_unhandled_releases:
		uh.timestamp = event_time_to_game_time(uh.timestamp, prev_game_time_usec, new_game_time_usec, last_frame_time_usec)
		unhandled_release.emit(uh.action, uh.event_uid, uh.timestamp)
	_buffered_unhandled_releases.clear()
	super.flush_inputs(prev_game_time_usec, new_game_time_usec, last_frame_time_usec)

func _input(event: InputEvent) -> void:
	super._input(event)
	if log_file:
		if event.is_action_pressed("contextual_option") or (event is InputEventKey and event.keycode == KEY_F2 and event.is_pressed() and not event.is_echo()):
			log_file.store_line("Telemetry Mark!")
			log_file.flush()
	if event is InputEventKey:
		if event.keycode == KEY_F10:
			get_window().gui_embed_subwindows = false
			for device_d in joypad_device_datas.values():
				var device: JoypadDeviceData = device_d
				for w in device.debug_windows:
					w.popup_centered()
func _input_received(event: InputEvent):
	var actions_to_send = []
	var releases_to_send = []
	
	if event is InputEventHB:
		return
		
	if log_file and not event is InputEventMouse:
		var device_name := ""
		if event is InputEventKey:
			device_name = "Keyboard"
		elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
			device_name = Input.get_joy_name(event.device)
		if event is InputEventJoypadMotion:
			log_file.store_line("Engine event: " + event.as_text() + " (%d: %s) pressed: %s" % [event.device, device_name, "yes" if event.is_pressed() else "no"])
			log_file.flush()
		
	if not event is InputEventAction and not event is InputEventMouseMotion:
		var found_actions = []
		
		for action in TRACKED_ACTIONS:
			if event.is_action(action):
				found_actions.append(action)
							
		if event is InputEventJoypadMotion:
			if event.axis in DIRECT_AXIS:
				var device := get_or_create_joypad_device_data(event.device)
				if device.uses_direct_joypad_access():
					for joystick in device.direct_joysticks:
						if joystick.push_input(event):
							return
		for action in found_actions:
			if event is InputEventJoypadMotion:
				var digital_action = action
				if UserSettings.should_use_direct_joystick_access(event.device) \
					and action in DIRECT_AXIS_ACTIONS \
					and event.axis in DIRECT_AXIS:
					continue
				
				if not last_axis_values.has(event.device):
					last_axis_values[event.device] = {}
				if not last_axis_values[event.device].has(digital_action):
					last_axis_values[event.device][digital_action] = {}
				if not last_axis_values[event.device][digital_action].has(event.axis):
					last_axis_values[event.device][digital_action][event.axis] = 0.0
				var was_axis_held_last_time = _is_axis_held(event.device, digital_action, event.axis)

				var is_bidirectional = digital_action in BIDIRECTIONAL_ACTIONS
				
				if is_bidirectional:
					last_axis_values[event.device][digital_action][event.axis] = event.axis_value
				else:
					last_axis_values[event.device][digital_action][event.axis] = event.get_action_strength(digital_action)
				var is_axis_held_now = _is_axis_held(event.device, digital_action, event.axis)

				if not was_axis_held_last_time and is_axis_held_now:
					actions_to_send.append({"action": digital_action, "pressed": true, "event": event})
#					send_input(digital_action, true)
				if was_axis_held_last_time and not is_action_held(digital_action):
					actions_to_send.append({"action": digital_action, "pressed": false, "event": event})
					releases_to_send.append(action)
#					send_input(digital_action, false)
			else:
				var button_i = -1
				if event is InputEventKey:
					button_i = event.keycode
				elif event is InputEventJoypadButton:
					button_i = event.button_index
				if button_i != -1:
					var was_action_pressed = is_action_held(action)
					var was_button_held_last_time = false
					if not digital_action_tracking.has(action):
						digital_action_tracking[action] = {}
					if not digital_action_tracking[action].has(event.device):
						digital_action_tracking[action][event.device] = {}
					if not digital_action_tracking[action][event.device].has(button_i):
						digital_action_tracking[action][event.device][button_i] = false
					was_button_held_last_time = digital_action_tracking[action][event.device][button_i]
					digital_action_tracking[action][event.device][button_i] = event.is_pressed()
					if not was_button_held_last_time and is_action_held(action):
						actions_to_send.append({"action": action, "pressed": true, "event": event})
					
					if was_action_pressed and not is_action_held(action):
						actions_to_send.append({"action": action, "pressed": false, "event": event})
					if not event.is_pressed():
						releases_to_send.append(action)
		var event_uid = get_event_uid(event)
		current_actions = []
		for action_data in actions_to_send:
			current_actions.append(action_data.action)
			
		for action_data in actions_to_send:
			current_event = action_data.event
			var device_type := DEVICE_TYPE.OTHER
			var device_idx := -1
			
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				device_idx = event.device
				device_type = DEVICE_TYPE.JOYPAD

			last_action_device_idx = device_idx
			last_action_device_type = device_type
			
			send_input(action_data.action, action_data.pressed, actions_to_send.size(), event_uid, current_actions, event.timestamp)
		
		for action in releases_to_send:
			var buffered_uh_release := UnhandledRelease.new()
			buffered_uh_release.action = action
			buffered_uh_release.event_uid = event_uid
			buffered_uh_release.timestamp = event.timestamp
			_buffered_unhandled_releases.push_back(buffered_uh_release)
