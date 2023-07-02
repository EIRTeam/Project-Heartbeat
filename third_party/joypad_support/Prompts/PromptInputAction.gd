extends MarginContainer
# Class to automatize almost everything related to showing Input Prompts. Just Instance the scene
# where you need, set the export variables and it should always show the correct input prompt or a 
# fallback label. Even though it's a tool, it doesn't work well on the editor, better tested on 
# runtime.
#
# Exports:
# - input_action - the name of the action you configured in the ProjectSettings or through code
# - force_type - Default is NONE, and in this state it will prefer to show Joypad Prompts if there
# 				 there is any in this action and if a Joypad is connected, otherwise it will show
# 				 a Keyboard/Mouse prompt. KEYBOARD will force it to only show KEYBOARD/MOUSE prompts
# 				 and JOYPAD will force it to only show JOYPAD prompts. (This is usefull if you want
# 				 to let the user have different profiles for KEYBOARD/JOYPAD so that each menu only
# 				 its relevant Prompts)

### Member Variables and Dependencies -----
# signals 
# enums
enum ForceType {
	NONE,
	KEYBOARD,
	JOYPAD
}
# constants
const DIRECTION_IMAGE_SIZE_MULTIPLIER = 0.75

# export variables
@export var input_action: = "": set = _set_input_action
@export var force_type := ForceType.NONE
@export var skip_inputs: int = 0
@export var disable_axis_direction_display: bool = false

# public variables
# private variables
var _event_keyboard: String = ""
var _event_mouse: String = ""
var _event_joybutton: String = ""
var _event_joyaxis: String = ""
var _event_joyaxis_direction = 0.0

# onready variables
@onready var _prompt: TextureRect = get_node("HBoxContainer/Prompt")
@onready var _fallback: Label = get_node("Fallback")
@onready var _direction_left: TextureRect =  get_node("HBoxContainer/LeftPrompt")
@onready var _direction_right: TextureRect =  get_node("HBoxContainer/RightPrompt")
@onready var _direction_up: TextureRect =  get_node("HBoxContainer/UpPrompt")
@onready var _direction_down: TextureRect =  get_node("HBoxContainer/DownPrompt")

### ---------------------------------------


### Built in Engine Methods ---------------

func _ready():
	if input_action == "":
		push_warning("Undefined input_action")
	_setup()
	
	if not get_tree().get_root().has_node("/root/JoypadSupport"):
		push_error("Please register the JoypadSupport scene as an autoload on Project Settings " + \
				"with JoypadSupport as name.Or change the code below to point to where " + \
				"JoypadSupport is or it's equivalent.")
		assert(false)
	
	# Both call backs do the same thing here, but kept them separate to facilitade customization
	# or expansion of each event separately
	JoypadSupport.connect("joypad_connected", Callable(self, "_on_JoypadSupport_joypad_connected"))
	JoypadSupport.connect("joypad_disconnected", Callable(self, "_on_JoypadSupport_joypad_disconnected"))
	JoypadSupport.connect("joypad_manually_changed", Callable(self, "_on_JoypadSupport_joypad_manually_changed"))
	JoypadSupport.connect("input_remapped", Callable(self, "_on_JoypadSupport_input_remapped"))

	connect("resized", Callable(self, "_on_resized"))
	
	_on_resized()

### ---------------------------------------


### Public Methods ------------------------
### ---------------------------------------


### Private Methods -----------------------
func _set_input_action(value) -> void:
	input_action = value
	if _prompt != null:
		_setup()

func _on_resized():
	custom_minimum_size.x = size.y
	for dir in [_direction_left, _direction_right, _direction_up, _direction_down]:
		if dir.visible:
			custom_minimum_size.x += size.y * DIRECTION_IMAGE_SIZE_MULTIPLIER

func _setup() -> void:
	_reset_event_variables()
	var actions_list: = InputMap.get_actions()
	if actions_list.has(input_action):
		_setup_event_variables()
		_setup_prompt_appearence()
	else:
		if not Engine.is_editor_hint():
			push_warning("Couldn't find %s in input map list: %s"%[input_action, actions_list])
			assert(false)


func _reset_event_variables() -> void:
	_event_keyboard = ""
	_event_mouse = ""
	_event_joybutton = ""
	_event_joyaxis = ""
	_event_joyaxis_direction = 0.0


func _setup_event_variables() -> void:
	var event_list: = InputMap.action_get_events(input_action)
	var _skip_count_keyboard = skip_inputs+1
	var _skip_count_mouse = skip_inputs+1
	var _skip_count_joybutton = skip_inputs+1
	var _skip_count_joyaxis = skip_inputs+1
	if event_list.size() > 0:
		for event in event_list:
			if event is InputEventKey and (_event_keyboard == "" or _skip_count_keyboard > 0):
				_event_keyboard = str((event as InputEventKey).keycode)
				_skip_count_keyboard -= 1
			elif event is InputEventMouseButton and (_event_mouse == "" or _skip_count_mouse > 0):
				_event_mouse = str((event as InputEventMouseButton).button_index)
				_skip_count_mouse -= 1
			elif event is InputEventJoypadButton and (_event_joybutton == "" or _skip_count_joybutton > 0):
				_event_joybutton = str((event as InputEventJoypadButton).button_index)
				_skip_count_joybutton -= 1
			elif event is InputEventJoypadMotion and (_event_joyaxis == "" or _skip_count_joyaxis > 0):
				_event_joyaxis = str((event as InputEventJoypadMotion).axis)
				_event_joyaxis_direction = event.axis_value
				_skip_count_joyaxis -= 1
	else:
		if not Engine.is_editor_hint():
			push_error("input map action has no events in it!" + \
					" Register events for it in the Project Settings or through code")
			assert(false)


func _setup_prompt_appearence() -> void:
	_prompt.texture = null
	_fallback.text = ""
	
	_direction_up.hide()
	_direction_down.hide()
	_direction_left.hide()
	_direction_right.hide()
	
	var success: = false
	success = _set_prompt_texture()
	
	if not success:
		success = _set_fallback_label()
	
	if not success:
		_push_fallback_failed_error()


func _set_joypad_direction_display(string_index: String):
	var idx = int(string_index)
	if not disable_axis_direction_display:
		if idx == JOY_AXIS_LEFT_X or idx == JOY_AXIS_RIGHT_X:
			if _event_joyaxis_direction < 0.0:
				_direction_left.show()
			else:
				_direction_right.show()
		elif idx == JOY_AXIS_LEFT_Y or idx == JOY_AXIS_RIGHT_Y:
			if _event_joyaxis_direction < 0.0:
				_direction_up.show()
			else:
				_direction_down.show()

func _set_prompt_texture() -> bool:
	var success: = false
	
	if (JoypadSupport.get_joypad_type() != JS_JoypadIdentifier.JoyPads.NO_JOYPAD \
	or (force_type == ForceType.JOYPAD)) and not force_type == ForceType.KEYBOARD:
		if _event_joybutton != "":
			success = _set_prompt_for(_event_joybutton)
		elif _event_joyaxis != "":
			success = _set_prompt_for(_event_joyaxis)
			_set_joypad_direction_display(_event_joyaxis)
		elif _event_keyboard != "":
			success = _set_prompt_for(_event_keyboard)
		elif _event_mouse != "":
			success = _set_prompt_for(_event_mouse)
	else:
		if _event_keyboard != "":
			success = _set_prompt_for(_event_keyboard)
		elif _event_mouse != "":
			success = _set_prompt_for(_event_mouse)
	
	return success


func _set_prompt_for(string_index: String) -> bool:
	return false
	var prompt_texture: Texture2D =  _get_prompt_texture_for(string_index)
	var success = prompt_texture.resource_path != ""
	
	if success:
		_prompt.texture = prompt_texture
	
	return success

func _get_prompt_texture_for(string_index: String) -> Texture2D:
	var prompt_texture
	match string_index:
		_event_keyboard:
			prompt_texture = JoypadSupport.get_keyboard_prompt_for(_event_keyboard)
		_event_mouse:
			prompt_texture = JoypadSupport.get_mouse_prompt_for(_event_mouse)
		_event_joybutton:
			prompt_texture = JoypadSupport.get_joypad_button_prompt_for(_event_joybutton)
		_event_joyaxis:
			prompt_texture = JoypadSupport.get_joy_axis_prompt_for(_event_joyaxis)
		_:
			push_match_event_variables_error()
	
	return prompt_texture


func _set_fallback_label() -> bool:
	var success: = false
	
	if (JoypadSupport.get_joypad_type() != JS_JoypadIdentifier.JoyPads.NO_JOYPAD \
	or (force_type == ForceType.JOYPAD)) and not force_type == ForceType.KEYBOARD:
		if _event_joybutton != "":
			success = _set_fallback_for(_event_joybutton)
		elif _event_joyaxis != "":
			success = _set_fallback_for(_event_joyaxis)
		elif _event_keyboard != "":
			success = _set_fallback_for(_event_keyboard)
		elif _event_mouse != "":
			success = _set_fallback_for(_event_mouse)
	else:
		if _event_keyboard != "":
			success = _set_fallback_for(_event_keyboard)
		elif _event_mouse != "":
			success = _set_fallback_for(_event_mouse)
	
	return success


func _set_fallback_for(string_index: String) -> bool:
	var fallback_string: = _get_fallback_string_for(string_index)
	var success = fallback_string != ""
	
	if success:
		_fallback.text = fallback_string
	
	return success


func _get_fallback_string_for(string_index: String) -> String:
	var index: = int(string_index)
	var fallback_string: = ""
	
	match string_index:
		_event_keyboard:
			fallback_string = _get_keyboard_string(index)
		_event_mouse:
			fallback_string = "Mouse Button %s"%[index]
		_event_joybutton:
			# TODO: Migrate this
			fallback_string = "WAO"
		_event_joybutton:
			fallback_string = "Axis %s"%[index]
		_:
			push_match_event_variables_error()
	
	return fallback_string

func _get_keyboard_string(keycode: int) -> String:
	var string = ""
	match keycode:
		KEY_TAB:
			string = "Tab"
		KEY_BACKTAB:
			string = "Tab"
		_:
			string = OS.get_keycode_string(keycode)
	
	return string


func push_match_event_variables_error() -> void:
	if Engine.is_editor_hint():
		return
	
	push_error("If you got here it's because the string index doesn't match any " + \
			"of the registered _event_* variables. That may mean the event list for " + \
			"this particular action (%s) is empty, though if that's the case this " + \
			"should have been caught by another exception already and you shouldn't be" + \
			"here. Anyway, I hope this helps in debugging."%[input_action]
	)
	assert(false)


func _push_fallback_failed_error() -> void:
	if Engine.is_editor_hint():
		return
#	return
#	push_error("Unable to set prompt or fallback text for any of the events in %s: "\
#			%[input_action] + \
#			"_event_keyboard: %s | "%[_event_keyboard] + \
#			"_event_mouse: %s | "%[_event_mouse] + \
#			"_event_joybutton: %s | "%[_event_joybutton] + \
#			"_event_joyaxis: %s"%[_event_joyaxis] \
#	)
#	assert(false)


func _on_JoypadSupport_joypad_connected() -> void:
	_setup()


func _on_JoypadSupport_joypad_disconnected() -> void:
	_setup()


func _on_JoypadSupport_joypad_manually_changed() -> void:
	if force_type == ForceType.KEYBOARD \
	or force_type == ForceType.NONE and Input.get_connected_joypads().size() == 0:
		return
	
	_setup()


func _on_JoypadSupport_input_remapped() -> void:
	_setup()

### ---------------------------------------
