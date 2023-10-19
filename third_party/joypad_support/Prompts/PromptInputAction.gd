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

func _set_input_action(input_action):
	$InputGlyphRect.action_name = input_action
