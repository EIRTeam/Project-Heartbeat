extends Node

var action_tracking = {}

const TRACKED_ACTIONS = ["note_a", "note_b", "note_x", "note_y", "tap_left", "tap_right"]

func is_action_pressed(action: String):
	var action_inputs = action_tracking[action]
	for device in action_inputs:
		for button in action_inputs[device]:
			if action_inputs[device][button] == true:
				return true
	return false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event):
	if event is InputEventMouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not event is InputEventAction:
		if event is InputEventJoypadButton or event is InputEventKey:
			if not event.is_echo():
				var found_action
				for action in TRACKED_ACTIONS:
					if event.is_action(action):
						found_action = action
						break
				if not found_action:
					return
				
				var previous_state = false
				
				var button = 0
				
				if event is InputEventKey:
					button = event.scancode
				elif event is InputEventJoypadButton:
					button = event.button_index
				
				if not action_tracking.has(found_action):
					action_tracking[found_action] = {}
				if not action_tracking[found_action].has(event.device):
					action_tracking[found_action][event.device] = {}
				if not action_tracking[found_action][event.device].has(button):
					action_tracking[found_action][event.device][button] = false
	
				previous_state = is_action_pressed(found_action)
				action_tracking[found_action][event.device][button] = event.is_pressed()
				get_tree().set_input_as_handled()
				
				if not is_action_pressed(found_action) or event.is_pressed():
					var ev = InputEventAction.new()
					ev.action = found_action
					ev.pressed = is_action_pressed(found_action)
					Input.parse_input_event(ev)
