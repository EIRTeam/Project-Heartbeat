extends Node
class_name JS_JoypadMapButton
# Usefull to add as a component to Buttons that serve to map joypad controls. 
# They auto enable and auto disable the parent Button when Joypads Connect/Disconnect
# to prevent the user to getting to a Joypad Remaping screen without having a Joypad Connected
# and getting stuck because JoypadSupport is only listening for Joypad Input.

### Member Variables and Dependencies -----
# private variables
var _parent_button: Button = null

### ---------------------------------------


### Built in Engine Methods ---------------
func _ready():
	_parent_button = get_parent() as Button
	if _parent_button == null or not _parent_button is Button:
		push_error("Invalid _parent_button: %s | This script is made to act as a component of " + \
				"Buttons that serve for mapping Joypad buttons. If the parent is null or it is " + \
				"not a Button there is no meaning in using it.")
		assert(false)
	
	JoypadSupport.connect("joypad_connected", Callable(self, "_on_JoypadSupport_joypad_connected"))
	JoypadSupport.connect("joypad_disconnected", Callable(self, "_on_JoypadSupport_joypad_disconnected"))

### ---------------------------------------


### Public Methods ------------------------
func activate_parent_button() -> void:
	_parent_button.disabled = false
	_parent_button.focus_mode = Control.FOCUS_ALL

func deactivate_parent_button() -> void:
	_parent_button.disabled = true
	_parent_button.focus_mode = Control.FOCUS_NONE

### ---------------------------------------


### Private Methods -----------------------
func _on_JoypadSupport_joypad_connected() -> void:
	activate_parent_button()


func _on_JoypadSupport_joypad_disconnected() -> void:
	deactivate_parent_button()

### ---------------------------------------


