extends Node

var pressed_inputs = {}
const ACTIONS_TO_TRACK_FOR_TAPS = ["tap_right_analog", "tap_left_analog"]

const ANALOG_TO_DIGITAL_MAP = {
	"tap_right_analog": "tap_right",
	"tap_left_analog": "tap_left"
}

# device -> action -> axis -> pressed

var device_map = {
	
}
# device -> axis -> action
var last_axis_values = {
	
}

var debounce_polls = {}

func _ready():
	for action in ACTIONS_TO_TRACK_FOR_TAPS:
		pressed_inputs[action] = false
		debounce_polls[action] = 0
	
	
func get_action_status_in_device_axis(action: String, device: int, axis: int):
	if not device_map.has(device):
		device_map[device] = {}
	if not device_map[device].has(action):
		device_map[device][action] = {}
	if not device_map[device][action][axis]:
		device_map[device][action][axis] = false
	
func _unhandled_input(event):
	if event is InputEventJoypadMotion:
#		for action in ACTIONS_TO_TRACK_FOR_TAPS:
#			if event.is_action(action):
#				print("ACTION!!!")
		for action in debounce_polls:
			debounce_polls[action] -= 1
		for action in ACTIONS_TO_TRACK_FOR_TAPS:
			if event.is_action(action):
				if not last_axis_values.has(event.device):
					last_axis_values[event.device] = {}
				if not last_axis_values[event.device].has(action):
					last_axis_values[event.device][action] = {}
				if not last_axis_values[event.device][action].has(event.axis):
					last_axis_values[event.device][action][event.axis] = 0.0
				var last_value = last_axis_values[event.device][action][event.axis]
				if last_value < UserSettings.user_settings.tap_deadzone and event.get_action_strength(action) >= UserSettings.user_settings.tap_deadzone:
					if pressed_inputs[action] == false:
						var a = InputEventAction.new()
						a.action = ANALOG_TO_DIGITAL_MAP[action]
						a.pressed = true
						Input.parse_input_event(a)

				elif last_value >= UserSettings.user_settings.tap_deadzone and event.get_action_strength(action) < UserSettings.user_settings.tap_deadzone:
						var a = InputEventAction.new()
						a.action = ANALOG_TO_DIGITAL_MAP[action]
						a.pressed = false
						Input.parse_input_event(a)
				last_axis_values[event.device][action][event.axis] = event.get_action_strength(action)
