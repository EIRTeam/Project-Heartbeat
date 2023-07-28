extends "res://menus/HBConfirmationWindow.gd"

signal entered(text)

@onready var line_edit = get_node("Panel/MarginContainer/VBoxContainer/LineEdit")

@export var text_input_description: String = tr("Input text")

func _on_Control_about_to_show():
	line_edit.text = ""
	line_edit.grab_focus()
	
func _on_LineEdit_text_entered(new_text):
	emit_signal("entered", new_text)

func _connect_button_signals():
	return

func _on_LineEdit_focus_entered():
	if HBGame.is_on_steam_deck():
		PlatformService.service_provider.show_floating_gamepad_text_input()
	elif PlatformService.service_provider.show_gamepad_text_input(line_edit.text, false, text_input_description):
		PlatformService.service_provider.connect("gamepad_input_dismissed", Callable(self, "_on_gamepad_input_dismissed").bind(), CONNECT_ONE_SHOT)

func _on_gamepad_input_dismissed(submitted: bool, text: String):
	if submitted:
		_on_LineEdit_text_entered(text)
	else:
		emit_signal("cancel")
