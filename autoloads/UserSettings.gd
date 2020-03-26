extends Node

var user_settings: HBUserSettings = HBUserSettings.new()

const USER_SETTINGS_PATH = "user://user_settings.json"
const LOG_NAME = "UserSettings"
var base_input_map = {}
var action_names = {
	"note_up": "Note up",
	"note_down": "Note down",
	"note_left": "Note left",
	"note_right": "Note right",
	"gui_up": "Menu up",
	"gui_down": "Menu down",
	"gui_left": "Menu left",
	"gui_right": "Menu right",
	"gui_accept": "Menu accept",
	"gui_cancel": "Menu cancel",
	"activate_heart_power": "Activate heart power",
	"tap_left": "Slide left",
	"tap_left_analog": "Slide left analog",
	"tap_right": "Slide right",
	"tap_right_analog": "Slide right analog",
	"pause": "Pause"
}

var axis_names = [
	" (Left Stick Left)",
	" (Left Stick Right)",
	" (Left Stick Up)",
	" (Left Stick Down)",
	" (Right Stick Left)",
	" (Right Stick Right)",
	" (Right Stick Up)",
	" (Right Stick Down)",
	"", "", "", "",
	"", " (L2)",
	"", " (R2)"
]

var button_names = [
	"DualShock Cross, Xbox A, Nintendo B",
	"DualShock Circle, Xbox B, Nintendo A",
	"DualShock Square, Xbox X, Nintendo Y",
	"DualShock Triangle, Xbox Y, Nintendo X",
	"L, L1",
	"R, R1",
	"L2",
	"R2",
	"L3",
	"R3",
	"Select, DualShock Share, Nintendo -",
	"Start, DualShock Options, Nintendo +",
	"D-Pad Up",
	"D-Pad Down",
	"D-Pad Left",
	"D-Pad Right"
]

const HIDE_KB_REMAPS_ACTIONS = [
	"gui_up",
	"gui_down",
	"gui_left",
	"gui_right",
	"gui_accept",
	"gui_cancel"
]

const DISABLE_ANALOG_FOR_ACTION = [
	"gui_accept",
	"gui_cancel",
	"tap_right",
	"tap_left"
]

var device_id = 0

func get_input_map():
	var map = {}
	for action_name in InputMap.get_actions():
		if action_name in action_names:
			map[action_name] = []
			for event in InputMap.get_action_list(action_name):
				if event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventKey:
					map[action_name].append(event)
	return map
func _ready():
	base_input_map = get_input_map()
	load_user_settings()
	# Set the controller to be the first one if we have none
	if not user_settings.last_controller_guid:
		user_settings.last_controller_guid = Input.get_joy_guid(0)
	load_input_map()
	save_user_settings()
	user_settings.last_controller_guid = ""
	for action in InputMap.get_actions():
		if action in action_names:
			for event in InputMap.get_action_list(action):
				if event is InputEventKey:
					print(OS.get_scancode_string(event.scancode))
				if event is InputEventJoypadMotion:
					var n = 2 * event.axis;
					if event.axis_value >= 0:
						n += 1
func get_axis_name(event: InputEventJoypadMotion):
	var n = 2 * event.axis;
	if event.axis_value >= 0:
		n += 1
	var axis_sign = "+"
	if event.axis_value < 0:
		axis_sign = "-"
	return "Axis " + str(event.axis) + " " + axis_sign + " " + axis_names[n]

func get_button_name(event: InputEventJoypadButton):
	return button_names[event.button_index]

func load_input_map():
	# Loads input map from the user's settings
	for action_name in user_settings.input_map:
		InputMap.action_erase_events(action_name)
		for action in user_settings.input_map[action_name]:
			InputMap.action_add_event(action_name, action)
	map_actions_to_controller()
func map_actions_to_controller():
	for _device_id in Input.get_connected_joypads():
		if Input.get_joy_guid(_device_id) == user_settings.last_controller_guid:
			Log.log(self, "Swapping main controller device from " + str(device_id) + " to " + str(_device_id))
			device_id = _device_id
			break
	# Remap actions to new device id
	for action_name in action_names:
		for event in InputMap.get_action_list(action_name):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				InputMap.action_erase_event(action_name, event)
				event.device = device_id
				InputMap.action_add_event(action_name, event)
func _input(event):
	if event is InputEventJoypadButton:
		# If we receive an input from a controller that isn't the one we have
		# we rebind the InputMap to use that
		var new_guid = Input.get_joy_guid(event.device)
		if new_guid != user_settings.last_controller_guid:
			user_settings.last_controller_guid = new_guid
			map_actions_to_controller()
			Input.parse_input_event(event)
func load_user_settings():
	var file := File.new()
	if file.file_exists(USER_SETTINGS_PATH):
		if file.open(USER_SETTINGS_PATH, File.READ) == OK:
			var result = JSON.parse(file.get_as_text())
			if result.error == OK:
				user_settings = HBUserSettings.deserialize(result.result)
				Log.log(self, "Successfully loaded user settings from " + USER_SETTINGS_PATH)
			else:
				Log.log(self, "Error loading user settings, on line %d: %s" % [result.error_line, result.error_string], Log.LogLevel.ERROR)
	Input.set_use_accumulated_input(!user_settings.input_poll_more_than_once_per_frame)
func save_user_settings():
	var file := File.new()
	user_settings.input_map = get_input_map()
	if file.open(USER_SETTINGS_PATH, File.WRITE) == OK:
		var contents = JSON.print(user_settings.serialize(), "  ")
		file.store_string(contents)
		PlatformService.service_provider.write_remote_file_async(USER_SETTINGS_PATH.get_file(), contents.to_utf8())

func get_event_name(event: InputEvent):
	var ret = ""
	if event is InputEventJoypadMotion:
		var axis_sign = "+"
		if event.axis_value < 0:
			axis_sign = "-"
		ret = get_axis_name(event)
	elif event is InputEventJoypadButton:
		ret = get_button_name(event)
	elif event is InputEventKey:
		ret = OS.get_scancode_string(event.scancode)
	return ret
func reset_to_default_input_map():
	user_settings.input_map = base_input_map
	load_input_map()
	save_user_settings()
