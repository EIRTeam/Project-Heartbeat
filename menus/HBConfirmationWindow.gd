tool
extends Popup

signal accept
signal cancel
export(bool) var has_cancel = true 
export(bool) var has_accept = true
export(String) var text  = "Are you sure you want to do this?" setget set_text
export(String) var accept_text  = "Yes" setget set_accept_text
export(String) var cancel_text  = "No" setget set_cancel_text

func _ready():
	popup_exclusive = true
	connect("cancel", self, "hide")
	connect("accept", self, "hide")
	if not has_cancel:
		$Panel/HBoxContainer/CancelButton.hide()
	if not has_accept:
		$Panel/HBoxContainer/AcceptButton.hide()

func set_text(value):
	text = value
	$Panel/MarginContainer/VBoxContainer/Label.text = value
func set_accept_text(value):
	accept_text = value
	$Panel/HBoxContainer/AcceptButton.text = value
func set_cancel_text(value):
	cancel_text = value
	$Panel/HBoxContainer/CancelButton.text = value


func _on_Control_about_to_show():
	$Panel/HBoxContainer.grab_focus()
	if has_cancel:
		$Panel/HBoxContainer.select_button(1)
	else:
		$Panel/HBoxContainer.select_button(0)
