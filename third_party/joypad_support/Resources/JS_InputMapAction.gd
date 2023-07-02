extends Resource
class_name JS_InputMapAction
# Custom Resource to help create Input Map Profiles and change events in actions. Used by and in
# conjunction with JoypadSupport autoload.

### Member Variables and Dependencies -----
# signals 
# enums
enum Types {
	KEY,
	MOUSE,
	JOYPAD_BUTTON,
	JOYPAD_AXIS,
}

# constants
# export variables
# public variables
var event: InputEvent = null

# private variables
var _action: = ""
var _event_type: int = Types.KEY
var _input_code: int = -1

### Built in Engine Methods ---------------
func _init(action: String, event_type: int, input_code: int) -> void:
	_action = action
	_event_type = event_type
	_input_code = input_code
	event = _get_new_event_of_type(_event_type, _input_code)

### ---------------------------------------


### Public Methods ------------------------
func get_action_name() -> String:
	return _action


func get_event_type() -> int:
	return _event_type


func get_input_code() -> int:
	return _input_code

### ---------------------------------------


### Private Methods -----------------------
func _get_new_event_of_type(event_type: int, new_input_code:int) -> InputEvent:
	var new_event: InputEvent = null
	
	match event_type:
		Types.KEY:
			new_event = _get_new_key_event(new_input_code)
		Types.MOUSE:
			new_event = _get_new_mouse_button_event(new_input_code)
		Types.JOYPAD_BUTTON:
			new_event = _get_new_joypad_button_event(new_input_code)
		Types.JOYPAD_AXIS:
			new_event = _get_new_joypad_axis_event(new_input_code)
		_:
			push_error("Invalid event_type: %s"%[event_type])
			assert(false)
	
	return new_event


func _get_new_key_event(keycode: int) -> InputEventKey:
	var new_event: = InputEventKey.new()
	new_event.keycode = keycode
	return new_event


func _get_new_mouse_button_event(button_index: int) -> InputEventMouseButton:
	var new_event: = InputEventMouseButton.new()
	new_event.button_index = button_index
	return new_event


func _get_new_joypad_button_event(button_index: int) -> InputEventJoypadButton:
	var new_event: = InputEventJoypadButton.new()
	new_event.button_index = button_index
	return new_event


func _get_new_joypad_axis_event(axis: int) -> InputEventJoypadMotion:
	var new_event: = InputEventJoypadMotion.new()
	new_event.axis = axis
	return new_event

### ---------------------------------------


