extends Node

var pressed_inputs = {}
var objects_processing = []
const ACTIONS_TO_TRACK_FOR_TAPS = ["tap_right", "tap_left"]

var debounce_polls = {}

func _ready():
	for action in ACTIONS_TO_TRACK_FOR_TAPS:
		pressed_inputs[action] = false
		debounce_polls[action] = 0

var current_tap_handled = false

func add_to_processing_unhandled_taps(object):
	objects_processing.append(object)
	
func set_tap_as_handled():
	current_tap_handled = true
	
func _unhandled_input(event):
	if event is InputEventJoypadMotion:
		for action in debounce_polls:
			debounce_polls[action] -= 1
		for action in ACTIONS_TO_TRACK_FOR_TAPS:
			if event.is_action(action):
				
				if event.get_action_strength(action) > 0.5:
					if pressed_inputs[action] == false:
						if debounce_polls[action] <= 0:
							pressed_inputs[action] = true
							print("TAP")
							debounce_polls[action] = 1
							for i in range(objects_processing.size() -1, -1, -1):
								var object = objects_processing[i]
								if is_instance_valid(object) and not object.is_queued_for_deletion():
									object._unhandled_tap(event)
									if current_tap_handled:
										current_tap_handled = false
										break
								else:
									objects_processing.remove(i)
				else:
					pressed_inputs[action] = false
