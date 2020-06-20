extends Node

var pressed_inputs = {}
const ACTIONS_TO_TRACK_FOR_TAPS = ["tap_right_analog", "tap_left_analog", "tap_up_analog", "tap_down_analog"]

const ANALOG_TO_DIGITAL_MAP = {
	"tap_right_analog": "tap_right",
	"tap_left_analog": "tap_left",
	"tap_up_analog": "tap_up",
	"tap_down_analog": "tap_down"
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
	pause_mode = Node.PAUSE_MODE_PROCESS
	
func is_action_held(action: String):
	var actual_action = HBUtils.find_key(ANALOG_TO_DIGITAL_MAP, action)
	if actual_action in pressed_inputs:
		return pressed_inputs[actual_action]
	return false
	
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
					var a = InputEventAction.new()
					pressed_inputs[action] = true
					a.action = ANALOG_TO_DIGITAL_MAP[action]
					a.pressed = true
					Input.parse_input_event(a)

				elif last_value >= UserSettings.user_settings.tap_deadzone and event.get_action_strength(action) < UserSettings.user_settings.tap_deadzone:
					var a = InputEventAction.new()
					a.action = ANALOG_TO_DIGITAL_MAP[action]
					pressed_inputs[action] = false
					a.pressed = false
					Input.parse_input_event(a)
				last_axis_values[event.device][action][event.axis] = event.get_action_strength(action)
