extends Node

var action_tracking = {}

const TRACKED_ACTIONS = ["note_up", "note_down", "note_left", "note_right", "tap_left", "tap_right"]

func is_action_pressed(action: String):
	var action_inputs = action_tracking[action]
	for device in action_inputs:
		for button in action_inputs[device]:
			if action_inputs[device][button] == true:
				return true
	return false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pause_mode = Node.PAUSE_MODE_PROCESS
	

func _input(event):
	if event is InputEventMouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not event is InputEventAction:
		if event is InputEventJoypadButton or event is InputEventKey or event or event is InputEventJoypadMotion:
			if not event.is_echo():
				for action in TRACKED_ACTIONS:
					if event.is_action(action):
						var found_action = action
						
						var button = 0
						var event_pressed = event.is_pressed()
						if event is InputEventKey:
							button = event.scancode
						elif event is InputEventJoypadButton:
							button = event.button_index
						elif event is InputEventJoypadMotion:
							button = "AXIS" + str(event.axis)
							event_pressed = event.get_action_strength(found_action) >= (1.0 - UserSettings.user_settings.analog_translation_deadzone)
							
						if not action_tracking.has(found_action):
							action_tracking[found_action] = {}
						if not action_tracking[found_action].has(event.device):
							action_tracking[found_action][event.device] = {}
						if not action_tracking[found_action][event.device].has(button):
							action_tracking[found_action][event.device][button] = false
						else:
							if action_tracking[found_action][event.device][button] == event_pressed:
								return
						action_tracking[found_action][event.device][button] = event.is_pressed()
						get_tree().set_input_as_handled()
						if not is_action_pressed(found_action) or event_pressed:
							var ev = InputEventAction.new()
							ev.action = found_action
							ev.pressed = is_action_pressed(found_action)
							Input.parse_input_event(ev)
