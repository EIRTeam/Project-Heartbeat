extends "res://menus/HBConfirmationWindow.gd"

signal entered(text)

onready var line_edit = get_node("Panel/MarginContainer/VBoxContainer/LineEdit")

func _on_Control_about_to_show():
	grab_focus()
	
func _on_LineEdit_text_entered(new_text):
	emit_signal("entered", new_text)

func _connect_button_signals():
	return
