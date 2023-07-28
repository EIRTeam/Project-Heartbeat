extends Control

func _ready():
	MouseTrap.disable_mouse_trap()

func _on_Button_pressed():
	var ticket = Steamworks.user.get_auth_ticket_for_web_api("Project Heartbeat")
	$MarginContainer/VBoxContainer/TextEdit.text = ticket.buffer.hex_encode()
