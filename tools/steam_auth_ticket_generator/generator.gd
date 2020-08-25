extends Control

func _on_Button_pressed():
	var ticket = Steam.getAuthSessionTicket()
	$MarginContainer/VBoxContainer/TextEdit.text = ticket.buffer.hex_encode()
