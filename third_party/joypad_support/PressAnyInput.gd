extends Label
# Write your doc striing for this file here

### Member Variables and Dependencies -----
# signals 
# enums
# constants
const key_text = "Press any key"
const button_text = "Press any button"

# export variables
# public variables
# private variables
# onready variables
### ---------------------------------------


### Built in Engine Methods ---------------

func _ready():
	await JoypadSupport.ready
	_choose_text()
	pass

### ---------------------------------------


### Public Methods ------------------------
### ---------------------------------------


### Private Methods -----------------------
func _choose_text() -> void:
	match JoypadSupport.get_joypad_type():
		JS_JoypadIdentifier.JoyPads.NO_JOYPAD:
			text = key_text
		_:
			text = button_text


func _on_JoypadSupport_joypad_connected():
	_choose_text()


func _on_JoypadSupport_joypad_disconnected():
	_choose_text()

### ---------------------------------------
