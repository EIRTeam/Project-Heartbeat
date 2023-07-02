extends CanvasLayer
# Takes care of identifying Joypads and providing prompt images for registered actions, either
# Joypad prompts if there is any Joypad Connected or Keyboard/Mouse prompts if there isn't any.
# It also provide helper methods to deal with letting the user change Input Maps, auto swaps ui_accept
# and ui_cancel joypad mappings for Switch Controllers, and other stuff. Better used in conjuction
# with PromptInputAction scene to automatize Showing Prompts.
#
# For changing input maps, use listen_input_for public method for an almost automatic experience,
# but there is also change_action_event_type if you want to have your own "Press any key" screen
# or other workflow outside of JoypadSupport. 
#
# To let the user set a prompt skin manually, you'll have to use the set_autodetect and set_chosen_skin
# methods in conjunction
#
# To let users swap ui_accept and ui_cancel manually, in case they want to confirm with Circle and
# cancel with Cross like in eastern rpgs and games for example, just use swap_ui_accept_and_cancel
# passing true when the user chooses this option. It will override the automatic swapping. 


### Member Variables and Dependencies -----
# signals 
# Kept this signals separate instead of only "_changed" so that both events can be used if needed
signal joypad_connected
signal joypad_disconnected
signal joypad_manually_changed
signal input_entered(input_map_action)
signal input_remapped

# enums

enum Modes {
	NONE,
	KEYBOARD_AND_MOUSE,
	JOYPAD,
}

# constants
# export variables
# public variables
@onready var prompts_keyboard: ResourcePreloader = get_node("Keyboard")
@onready var prompts_mouse: ResourcePreloader = get_node("Mouse")
@onready var prompts_joypad: ResourcePreloader = get_node("JoypadIdentifier/Xbox")

# private variables
var _listen_mode = Modes.NONE

var _accept_event: = JS_InputMapAction.new("ui_accept", 
		JS_InputMapAction.Types.JOYPAD_BUTTON, JOY_BUTTON_A)
var _cancel_event: = JS_InputMapAction.new("ui_cancel", 
		JS_InputMapAction.Types.JOYPAD_BUTTON, JOY_BUTTON_B)
var _swapped_accept_event = JS_InputMapAction.new("ui_accept", 
		JS_InputMapAction.Types.JOYPAD_BUTTON, JOY_BUTTON_B)
var _swapped_cancel_event = JS_InputMapAction.new("ui_cancel", 
		JS_InputMapAction.Types.JOYPAD_BUTTON, JOY_BUTTON_A)

@onready var _configs: JS_Config = get_node("Configs") as JS_Config
@onready var _joypad_identifier: JS_JoypadIdentifier = get_node("JoypadIdentifier")
@onready var _animator: AnimationPlayer = get_node("AnimationPlayer")

### ---------------------------------------


### Built in Engine Methods ---------------

func _ready() -> void:
	if not get_autodetect():
		update_joypad_prompts_manually()
	
	set_process_input(false)
	Input.connect("joy_connection_changed", Callable(self, "_on_Input_joy_connection_changed"))
	var input_devices = Input.get_connected_joypads()
	if input_devices.size() > 0:
		_set_joypad(input_devices[0], true)


func force_keyboard_prompts():
	if _joypad_identifier.joypad_type != JS_JoypadIdentifier.JoyPads.NO_JOYPAD:
		_joypad_identifier.reset_joypad_type()
		current_joypad = null
		emit_signal("joypad_disconnected")

func _input(event) -> void:
	return
	if _listen_mode == Modes.NONE:
		set_process_input(false)
		return 
	
	var input_code: int = -1
	var event_type: int = -1
	
	if _listen_mode == Modes.JOYPAD:
		if event is InputEventJoypadButton:
			input_code = event.button_index
			event_type = JS_InputMapAction.Types.JOYPAD_BUTTON
		elif event is InputEventJoypadMotion:
			input_code = event.axis
			event_type = JS_InputMapAction.Types.JOYPAD_AXIS
	elif _listen_mode == Modes.KEYBOARD_AND_MOUSE:
		if event is InputEventKey:
			input_code = event.keycode
			event_type = JS_InputMapAction.Types.KEY
		elif event is InputEventMouseButton:
			input_code = event.button_index
			event_type = JS_InputMapAction.Types.MOUSE
	
	get_viewport().set_input_as_handled()
	
	if input_code != -1:
		emit_signal("input_entered", {event_type = event_type, input_code = input_code})


### ---------------------------------------


### Public Methods ------------------------
func listen_input_for(action_name: String, mode: int):
	_listen_mode = mode
	
	set_process_input(true)
	var new_input_dictionary: Dictionary = await _listen_input()
	set_process_input(false)
	
	var new_input_map_action: = JS_InputMapAction.new(action_name, 
			new_input_dictionary.event_type, new_input_dictionary.input_code)
	change_action_event_type(new_input_map_action)


func change_action_event_type(input_map_action: JS_InputMapAction):
	var action_name = input_map_action.get_action_name()
	var event = input_map_action.event
	_erase_all_event_type_from(action_name, event)
	InputMap.action_add_event(action_name, event)
	emit_signal("input_remapped")
	_configs.rebuild_actions()
	_configs.save()


func change_profile_to(profile_name: String) -> void:
	var profiles = $ControlProfiles
	if not profiles.has_profile(profile_name):
		return
	
	for input_map_action in profiles.get(profile_name):
		change_action_event_type(input_map_action)


func set_autodetect_to(on_off: bool) -> void:
	_configs.should_autodetect_joypad_skin = on_off
	_configs.save()
	if get_autodetect():
		var input_devices = Input.get_connected_joypads()
		if input_devices.size() > 0:
			_set_joypad(input_devices[0], true)
	else:
		update_joypad_prompts_manually()


func get_autodetect() -> bool:
	return _configs.should_autodetect_joypad_skin


func set_chosen_skin(skin: int) -> void:
	_configs.chosen_skin = skin
	_configs.save()
	if not get_autodetect():
		update_joypad_prompts_manually()


func get_chosen_skin() -> int:
	return _configs.chosen_skin


func get_joypad_type() -> int:
	if not get_autodetect() and not _joypad_identifier.joypad_type == JS_JoypadIdentifier.JoyPads.NO_JOYPAD:
		return get_chosen_skin()
	
	return _joypad_identifier.joypad_type


func set_was_ui_accept_manually_swapped(on_off: bool) -> void:
	_configs.was_ui_accept_manually_swapped = on_off
	_configs.save()


func was_ui_accept_manually_swapped() -> bool:
	return _configs.was_ui_accept_manually_swapped


func update_joypad_prompts_manually() -> void:
	_handle_swap_ui_accept_cancel()
	prompts_joypad = _joypad_identifier.get_joypad_prompts()
	emit_signal("joypad_manually_changed")


func swap_ui_accept_and_cancel(was_manually_swapped: = false):
	if are_ui_accept_and_cancel_swapped():
		change_action_event_type(_accept_event)
		change_action_event_type(_cancel_event)
	else:
		change_action_event_type(_swapped_accept_event)
		change_action_event_type(_swapped_cancel_event)
	
	if was_manually_swapped != was_ui_accept_manually_swapped():
		emit_signal("joypad_manually_changed")
		set_was_ui_accept_manually_swapped(was_manually_swapped)


func are_ui_accept_and_cancel_swapped() -> bool:
	var are_swapped: = false
	var event_list = InputMap.action_get_events("ui_accept")
	
	for event in event_list:
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A:
			are_swapped = true
			break
	
	return are_swapped


func get_joypad_button_prompt_for(button_index: String) -> Texture2D:
	var prompt_texture: Texture2D = _get_prompt_for(prompts_joypad, button_index)
	return prompt_texture
func get_joy_axis_prompt_for(button_index: String) -> Texture2D:
	var idx = int(button_index)
	var prompt_texture: Texture2D
	if idx == JOY_AXIS_LEFT_X or idx == JOY_AXIS_LEFT_Y:
		prompt_texture = _get_prompt_for(prompts_joypad, str(JOY_BUTTON_LEFT_STICK))
	elif idx == JOY_AXIS_RIGHT_X or idx == JOY_AXIS_RIGHT_Y:
		prompt_texture = _get_prompt_for(prompts_joypad, str(JOY_BUTTON_RIGHT_STICK))
	elif idx == JOY_AXIS_TRIGGER_LEFT:
		prompt_texture = _get_prompt_for(prompts_joypad, str(JOY_BUTTON_LEFT_SHOULDER))
	elif idx == JOY_AXIS_TRIGGER_RIGHT:
		prompt_texture = _get_prompt_for(prompts_joypad, str(JOY_BUTTON_RIGHT_SHOULDER))
	return prompt_texture
func get_keyboard_prompt_for(keycode: String) -> Texture2D:
	var prompt_texture: Texture2D = _get_prompt_for(prompts_keyboard, keycode)
	return prompt_texture


func get_mouse_prompt_for(button_index: String) -> Texture2D:
	var prompt_texture: Texture2D = _get_prompt_for(prompts_mouse, button_index)
	return prompt_texture

### ---------------------------------------


### Private Methods -----------------------
### ---------------------------------------
func _listen_input() -> Dictionary:
	_animator.play("press_button")
	await _animator.animation_finished
	var input_dictionary: Dictionary = await self.input_entered
	_animator.play("base")
	return input_dictionary

var current_joypad = null

func _set_joypad(device: int, is_connected: bool) -> void:
	if is_connected:
		if device != current_joypad:
			current_joypad = device
			_joypad_identifier.set_joypad_type_for(device)
			_handle_swap_ui_accept_cancel()
			prompts_joypad = _joypad_identifier.get_joypad_prompts()
			emit_signal("joypad_connected")
	else:
		current_joypad = null
		_joypad_identifier.reset_joypad_type()
		emit_signal("joypad_disconnected")


func _get_prompt_for(loader: ResourcePreloader, index: String) -> Texture2D:
	var texture: Texture2D
	if loader.has_resource(index):
		texture = loader.get_resource(index)
		return texture
	else:
		return texture

func _handle_swap_ui_accept_cancel():
	var is_auto_swapped: = \
			are_ui_accept_and_cancel_swapped() \
			and not was_ui_accept_manually_swapped()
	var is_user_swapped: = \
			are_ui_accept_and_cancel_swapped() \
			and was_ui_accept_manually_swapped()
	var should_be_autoswapped: = \
			not are_ui_accept_and_cancel_swapped() \
			and not was_ui_accept_manually_swapped()
	var should_be_user_swapped: = \
			not are_ui_accept_and_cancel_swapped() \
			and was_ui_accept_manually_swapped()
	
	match get_joypad_type():
		JS_JoypadIdentifier.JoyPads.NINTENDO:
			if should_be_autoswapped:
				swap_ui_accept_and_cancel()
			elif is_user_swapped:
				swap_ui_accept_and_cancel(was_ui_accept_manually_swapped())
		JS_JoypadIdentifier.JoyPads.PLAYSTATION, \
		JS_JoypadIdentifier.JoyPads.XBOX, \
		JS_JoypadIdentifier.JoyPads.UNINDENTIFIED:
			if is_auto_swapped:
				swap_ui_accept_and_cancel()
			elif should_be_user_swapped:
				swap_ui_accept_and_cancel(was_ui_accept_manually_swapped())
		JS_JoypadIdentifier.JoyPads.NO_JOYPAD:
			pass
		_:
			push_error("Undefined Joypad: %s"%[get_joypad_type()])
			assert(false)


func _erase_all_event_type_from(action_name: String, new_event: InputEvent) -> void:
	var event_list = InputMap.action_get_events(action_name)
	for event in event_list:
		if event is InputEventKey and new_event is InputEventKey:
			InputMap.action_erase_event(action_name, event)
		elif event is InputEventMouseButton and new_event is InputEventMouseButton:
			InputMap.action_erase_event(action_name, event)
		elif event is InputEventJoypadButton and new_event is InputEventJoypadButton:
			InputMap.action_erase_event(action_name, event)
		elif event is InputEventJoypadMotion and new_event is InputEventJoypadMotion:
			InputMap.action_erase_event(action_name, event)


func _on_Input_joy_connection_changed(device: int, is_connected: bool) -> void:
	#print("Input device: %s, is_connected: %s"%[device, is_connected])
	_set_joypad(device, is_connected)
