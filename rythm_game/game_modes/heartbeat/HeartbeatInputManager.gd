extends HBGameInputManager

class_name HeartbeatInputManager

signal unhandled_release(event, event_uid)

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

var current_sending_actions_count = 0

const DJA_SLIDE_DOT_THRESHOLD = 0.5
var dja_last_filtered_axis_values = [Vector2(), Vector2()]
var dja_joystick_wma_history := [PackedVector2Array(), PackedVector2Array()]

func reset():
	super.reset()
	current_sending_actions_count = 0
	last_axis_values = {}
	current_actions = []
	digital_action_tracking = {}
	

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
func _get_analog_action_held_count(action):
	var count = 0
	if UserSettings.should_use_direct_joystick_access() and action in DIRECT_AXIS_ACTIONS:
		var v1 = dja_last_filtered_axis_values[0]
		var v2 = dja_last_filtered_axis_values[1]
		var deadzone = _get_action_deadzone(action)
		if action == "heart_note":
			if v1.length() > deadzone:
				count += 1
			if v2.length() > deadzone:
				count += 1
		elif action == "slide_left":
			if v1.x < 0 and v1.length() > deadzone and _is_in_slide_range(v1):
				count += 1
			if v2.x < 0 and v2.length() > deadzone and _is_in_slide_range(v2):
				count += 1
		elif action == "slide_right":
			if v1.x > 0 and v1.length() > deadzone and _is_in_slide_range(v1):
				count += 1
			if v2.x > 0 and v2.length() > deadzone and _is_in_slide_range(v2):
				count += 1
	for device in last_axis_values:
		if action in last_axis_values[device]:
			for axis in last_axis_values[device][action]:
				if abs(last_axis_values[device][action][axis]) >= _get_action_deadzone(action):
					if not UserSettings.should_use_direct_joystick_access() or not axis in DIRECT_AXIS:
						count += 1
	return count
func _is_action_held_analog(action):
	return _get_analog_action_held_count(action) > 0

func _is_in_slide_range(value: Vector2):
	return abs((Vector2.RIGHT * sign(value.x)).angle_to(value)) < deg_to_rad(UserSettings.user_settings.direct_joystick_slider_angle_window) * 0.5

func _handle_direct_axis_input():
	var deadzone = _get_action_deadzone("heart_note")

	current_sending_actions_count = 0
	var press_actions_to_send = []
	var press_actions_event_uids = []
	var action_state = []
	for joystick in range(2):
		var event_uid := get_dja_event_uid(joystick)
		var off := 2 * joystick
		var axis_x := JOY_AXIS_LEFT_X + off
		var axis_y := JOY_AXIS_LEFT_Y + off
		var x1 := Input.get_joy_axis(UserSettings.controller_device_idx, axis_x)
		var y1 := Input.get_joy_axis(UserSettings.controller_device_idx, axis_y)
		var curr_value := Vector2(x1, y1)
		
		var prev_filtered_input := dja_last_filtered_axis_values[joystick] as Vector2
		var filtered_input := curr_value
		var factor: float = UserSettings.user_settings.direct_joystick_filter_factor
		
		# WMA
		var pva := dja_joystick_wma_history[joystick] as PackedVector2Array
		if pva.size() != 20:
			pva.resize(20)
			pva.fill(Vector2.ZERO)
		var wma_total := 0.0
		var wma_sum := Vector2()
		# Move WMA to the right and do WMA computation
		for i in range(1, pva.size()):
			wma_total += (i * i * i)
			wma_sum += pva[i] * (i * i * i)
			pva[i-1] = pva[i]
		wma_sum += curr_value * (pva.size() * pva.size() * pva.size())
		wma_total += (pva.size() * pva.size() * pva.size())
		wma_sum /= wma_total
		
		pva[pva.size()-1] = curr_value
		dja_joystick_wma_history[joystick] = pva
		
		filtered_input = wma_sum
		
		var is_in_slide_window: bool = abs((Vector2.RIGHT * sign(filtered_input.x)).angle_to(filtered_input)) < deg_to_rad(UserSettings.user_settings.direct_joystick_slider_angle_window) * 0.5
		var curr_length := filtered_input.length()
		var prev_length := prev_filtered_input.length()
		# We need to check for the sign here to make sure we don't compare against 0, since that could be an issue
		if sign(filtered_input.x) != 0 and is_in_slide_window:
			if curr_length > deadzone and (prev_length < deadzone or sign(prev_filtered_input.x) != sign(filtered_input.x)):
				press_actions_to_send.push_back("slide_right" if filtered_input.x > 0.0 else "slide_left")
				press_actions_event_uids.push_back(event_uid)
				action_state.push_back(true)
		
		# Sometimes, when quickly turning the stick to the opposite direction the whole deadzone is skipped
		# this ensures that we still trigger those events if necessary
		var is_opposite: bool = abs(prev_filtered_input.angle_to(-filtered_input)) < deg_to_rad(90.0 * 0.5)
		if curr_length > deadzone and (prev_length < deadzone or is_opposite):
			press_actions_to_send.push_back("heart_note")
			press_actions_event_uids.push_back(event_uid)
			action_state.push_back(true)
		# Heart note release
		if (curr_length < deadzone and prev_length > deadzone) or (prev_length > deadzone and is_opposite):
			press_actions_to_send.push_back("heart_note")
			press_actions_event_uids.push_back(event_uid)
			action_state.push_back(false)
		dja_last_filtered_axis_values[joystick] = filtered_input
	
	if press_actions_to_send.size() > 0:
		current_sending_actions_count = press_actions_to_send.size()
		for i in range(press_actions_to_send.size()):
			send_input(press_actions_to_send[i], action_state[i], press_actions_to_send.size(), press_actions_event_uids[i], press_actions_to_send)

func flush_inputs():
	if UserSettings.should_use_direct_joystick_access() and is_processing_input():
		_handle_direct_axis_input()
	super.flush_inputs()

func _input_received(event):
	var actions_to_send = []
	var releases_to_send = []
	if event is InputEventHB:
		return
		
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if UserSettings.controller_device_idx != event.device:
			return
	if not event is InputEventAction and not event is InputEventMouseMotion:
		var found_actions = []
		
		for action in TRACKED_ACTIONS:
			if event.is_action(action):
				found_actions.append(action)
							
		current_input_handled = false
							
		for action in found_actions:
			if event is InputEventJoypadMotion:
				var digital_action = action
				if UserSettings.should_use_direct_joystick_access() \
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
			current_sending_actions_count = actions_to_send.size()
			send_input(action_data.action, action_data.pressed, actions_to_send.size(), event_uid, current_actions)
		for action in releases_to_send:
			emit_signal("unhandled_release", action, event_uid)
