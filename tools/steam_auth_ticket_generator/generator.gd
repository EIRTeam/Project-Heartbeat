extends Control

func _ready():
	MouseTrap.disable_mouse_trap()

func _on_Button_pressed():
	var ticket = Steam.getAuthSessionTicket()
	$MarginContainer/VBoxContainer/TextEdit.text = ticket.buffer.hex_encode()
