extends "res://menus/HBConfirmationWindow.gd"

signal entered(text)

onready var line_edit = get_node("Panel/MarginContainer/VBoxContainer/LineEdit")

export var text_input_description: String = tr("Input text")

func _on_Control_about_to_show():
	grab_focus()
	
func _on_LineEdit_text_entered(new_text):
	emit_signal("entered", new_text)

func _connect_button_signals():
	return

func _on_LineEdit_focus_entered():
	var text_entry_shown: bool = PlatformService.service_provider.show_gamepad_text_input(line_edit.text, false, text_input_description)
	if text_entry_shown:
		PlatformService.service_provider.connect("gamepad_input_dismissed", self, "_on_gamepad_input_dismissed", [], CONNECT_ONESHOT)

func _on_gamepad_input_dismissed(submitted: bool, text: String):
	if submitted:
		_on_LineEdit_text_entered(text)
	else:
		emit_signal("cancel")
