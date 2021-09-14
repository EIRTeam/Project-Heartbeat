extends HBGameInputManager

class_name HeartbeatInputManager

signal unhandled_release(event, event_uid)

var digital_action_tracking = {}

const TRACKED_ACTIONS = ["note_up", "note_down", "note_left", "note_right", "slide_left", "slide_right", "heart_note"]

const DIRECT_AXIS = [JOY_AXIS_0, JOY_AXIS_1, JOY_AXIS_2, JOY_AXIS_3]
const DIRECT_AXIS_ACTIONS = ["heart_note", "slide_left", "slide_right"]

var last_direct_axis_values = [0, 0, 0, 0]

const BIDIRECTIONAL_ACTIONS = [
	"heart_note"
]

var current_event: InputEvent # Current event being converted to action
var current_actions: Array = []
var last_axis_values = {}

var current_sending_actions_count = 0

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
		var x1 = Input.get_joy_axis(UserSettings.controller_device_idx, JOY_AXIS_0)
		var y1 = Input.get_joy_axis(UserSettings.controller_device_idx, JOY_AXIS_1)
		var x2 = Input.get_joy_axis(UserSettings.controller_device_idx, JOY_AXIS_2)
		var y2 = Input.get_joy_axis(UserSettings.controller_device_idx, JOY_AXIS_3)
		
		var v1 = Vector2(x1, y1)
		var v2 = Vector2(x2, y2)
		var deadzone = _get_action_deadzone(action)
		if action == "heart_note":
			if v1.length() > deadzone:
				count += 1
			if v2.length() > deadzone:
				count += 1
		elif action == "slide_left":
			if v1.x < -deadzone:
				count += 1
			if v2.x < -deadzone:
				count += 1
		elif action == "slide_right":
			if v1.x > deadzone:
				count += 1
			if v2.x > deadzone:
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

func _handle_direct_axis_input(event: InputEventJoypadMotion):
	var deadzone = _get_action_deadzone("heart_note")

	current_sending_actions_count = 1
	
	var event_uid = get_event_uid(event)

	for axis in range(2):
		var off = 2 * axis
		var axis_x = JOY_AXIS_0 + off
		var axis_y = JOY_AXIS_1 + off
		if event.axis in [axis_x, axis_y]:
			var x1 = Input.get_joy_axis(UserSettings.controller_device_idx, axis_x)
			var y1 = Input.get_joy_axis(UserSettings.controller_device_idx, axis_y)
			var prev_x = last_direct_axis_values[axis_x]
			var prev_y = last_direct_axis_values[axis_y]
			var change_x = x1 - prev_x
			var change_y = y1 - prev_y
			var length1 = Vector2(x1, y1).length()
			var old_length = Vector2(last_direct_axis_values[axis_x], last_direct_axis_values[axis_y]).length()
			
			var slide_action = "slide_right" if sign(x1) == 1 else "slide_left"
			
			current_actions = ["heart_note"]
			
			if (abs(change_x) > deadzone*2.0 or abs(change_y) > deadzone*2.0) or (old_length < deadzone and length1 > deadzone):
				if abs(x1) > deadzone:
					current_actions.append(slide_action)
					send_input(slide_action, true, current_actions.size(), event_uid, current_actions)
				if length1 > deadzone:
					send_input("heart_note", true, current_actions.size(), event_uid, current_actions)

			elif old_length > deadzone and length1 < deadzone:
				current_actions = [slide_action, "heart_note"]
				send_input(slide_action, false, current_actions.size(), event_uid, current_actions)
				emit_signal("unhandled_release", slide_action, event_uid)
				send_input("heart_note", false, current_actions.size(), event_uid, current_actions)


			last_direct_axis_values[axis_x] = x1
			last_direct_axis_values[axis_y] = y1



func _input_received(event):
	var actions_to_send = []
	var releases_to_send = []
	if not event is InputEventAction and not event is InputEventMouseMotion:
		var found_actions = []
		
		for action in TRACKED_ACTIONS:
			if event.is_action(action):
				found_actions.append(action)
				if event is InputEventJoypadMotion:
					if action in DIRECT_AXIS_ACTIONS:
						if event.axis in DIRECT_AXIS:
							if UserSettings.should_use_direct_joystick_access():
								if event.axis in DIRECT_AXIS:
									_handle_direct_axis_input(event)
							
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
					button_i = event.scancode
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
