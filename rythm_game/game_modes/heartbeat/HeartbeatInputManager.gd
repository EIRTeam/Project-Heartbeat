extends HBGameInputManager

class_name HeartbeatInputManager

signal unhandled_release(event, event_uid)

var digital_action_tracking = {}

const TRACKED_ACTIONS = ["note_up", "note_down", "note_left", "note_right", "slide_left", "slide_right", "heart_note"]

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
	for device in last_axis_values:
		if action in last_axis_values[device]:
			for axis in last_axis_values[device][action]:
				if abs(last_axis_values[device][action][axis]) >= _get_action_deadzone(action):
					count += 1
	return count
func _is_action_held_analog(action):
	return _get_analog_action_held_count(action) > 0

func _input_received(event):
	var actions_to_send = []
	var releases_to_send = []
	if not event is InputEventAction and not event is InputEventMouseMotion:
		var found_actions = []
		
		for action in TRACKED_ACTIONS:
			if event.is_action(action):
				found_actions.append(action)
		for action in found_actions:
			if event is InputEventJoypadMotion:
				var digital_action = action
				
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
