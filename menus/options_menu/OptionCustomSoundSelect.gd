extends "Option.gd"

var text = "": set = set_text
var sound_name = ""
# warning-ignore:unused_signal
signal pressed

@onready var selected_text = get_node("HBoxContainer/Control/Label2")
@onready var pack_select_dropdown = get_node("CanvasLayer/DropDown")
func set_text(val):
	text = val
	$HBoxContainer/Label.text = val

func _ready():
	pack_select_dropdown.hide()
	connect("pressed", Callable(self, "_on_pressed"))
	pack_select_dropdown.connect("selected_sound_changed", Callable(self, "_on_selected_sound_changed"))
	show_current()
	pack_select_dropdown.sound_name = sound_name
func _gui_input(event: InputEvent):
	pass
	
func show_current():
	if UserSettings.user_settings.custom_sounds[sound_name] == "default":
		selected_text.text = "Default"
	else:
		selected_text.text = UserSettings.user_settings.custom_sounds[sound_name]
var _old_focus
	
func _on_pressed():
	_old_focus = get_viewport().gui_get_focus_owner()
	pack_select_dropdown.show()
	pack_select_dropdown.grab_focus()
func _on_selected_sound_changed(new_sound):
	if new_sound:
		UserSettings.user_settings.custom_sounds[sound_name] = new_sound
		UserSettings.reload_sound_from_disk(sound_name)
		UserSettings.save_user_settings()
	show_current()
	_old_focus.grab_focus()
	pack_select_dropdown.hide()
