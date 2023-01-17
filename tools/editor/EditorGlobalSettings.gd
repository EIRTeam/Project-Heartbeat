extends WindowDialog

onready var tab_container = get_node("TabContainer")

onready var song_settings_tab = get_node("TabContainer/Song")
onready var general_settings_tab = get_node("TabContainer/General")
onready var shortcuts_tab = get_node("TabContainer/Shortcuts/VBoxContainer/Panel")

func _input(event):
	if visible and event.is_action_pressed("gui_cancel", false, true) \
	   and not get_focus_owner() is LineEdit:
		hide()
