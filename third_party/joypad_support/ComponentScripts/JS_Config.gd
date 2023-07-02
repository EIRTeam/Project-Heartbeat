extends Node
class_name JS_Config
# Class to save and load configurations related to Joypad and Input Mappings. To add actions to be
# saved just add them in the editor, using the _actions_to_save exported Array. Also in the editor
# there will be other exported variables you need to set, but thoretically, setting them is all you
# need to do, the saving and loading should be automatic if you use the JoypadSupport autoload.
#
# If you need to extend this with more options you can add them as public variables here and either
# access them directly or extend JoypadSupport so that it has public methods to access them. Also
# you'll need to include them in `_build_serialized_data` and `_translate_serialized_data`

### Member Variables and Dependencies -----
# signals 
# enums
# constants
# public variables
var should_autodetect_joypad_skin: = true
var was_ui_accept_manually_swapped: = false
var actions: = {}

@onready var chosen_skin: int = JS_JoypadIdentifier.JoyPads.UNINDENTIFIED

# private variables
@export var _version: = 1.0
@export var _dir_path: = "user://"
@export var _file_name: = ""
@export var _actions_to_save = [] # (Array, String)

var _full_path: = ""
var _serialized_data = {}
var _base_serialized_data = {}

### ---------------------------------------


### Built in Engine Methods ---------------
func _ready():
	return
	#_full_path = _dir_path.path_join(_file_name)
	#_base_serialized_data = _build_serialized_data()
	#check_savefile()

### ---------------------------------------


### Public Methods ------------------------
func check_savefile():
	if not DirAccess.dir_exists_absolute(_dir_path):
		DirAccess.make_dir_recursive_absolute(_dir_path)
	
	if not FileAccess.file_exists(_full_path):
		reset_savefile()
	
	read()


func reset_savefile():
	if not _serialized_data.is_empty():
		_translate_serialized_data(_base_serialized_data)
	save()


func save() -> void:
	return


func read() -> void:
	return


# Bellow Here things would go into the extended script if you change this to extend a Futur BaseSaveFile
func rebuild_actions():
	actions.clear()
	_build_actions_dictionary()

### ---------------------------------------


### Private Methods -----------------------
func _push_reading_file_error(error) -> void:
	push_error("Error while reading %s: %s"%[_file_name, error])
	assert(false)

func _build_serialized_data() -> Dictionary:
	#This should be a 'virtual' function if you turn this into a BaseSaveFile class
	var settings: = {}
	settings["version"] = _version
	
	if actions.is_empty():
		_build_actions_dictionary()
	
	settings["actions"] = {}
	for action in actions:
		settings["actions"][action] = []
		for event in actions[action]:
			settings["actions"][action].append(var_to_str(event))
	
	settings["was_ui_accept_manually_swapped"] = was_ui_accept_manually_swapped
	settings["should_autodetect_joypad_skin"] = should_autodetect_joypad_skin
	settings["chosen_skin"] = chosen_skin
	
	return settings


func _translate_serialized_data(data: Dictionary) -> void:
	#This should be a 'virtual' function if you turn this into a BaseSaveFile class
	should_autodetect_joypad_skin = data["should_autodetect_joypad_skin"]
	chosen_skin = data["chosen_skin"]
	was_ui_accept_manually_swapped = data["was_ui_accept_manually_swapped"]
	
	actions.clear()
	for action in data.actions:
		actions[action] = []
		for event_str in data.actions[action]:
			actions[action].push_back(str_to_var(event_str))

# Bellow Here things would go into the extended script if you change this to extend a Futur BaseSaveFile
func _build_actions_dictionary() -> void:
	for action in _actions_to_save:
		actions[action] = []
		for event in InputMap.action_get_events(action):
			actions[action].append(event)


func _restore_actions() -> void:
	for action in actions:
		InputMap.action_erase_events(action)
		for event in actions[action]:
			InputMap.action_add_event(action, event)

### ---------------------------------------










