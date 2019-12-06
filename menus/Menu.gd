extends Control

signal change_to_menu(menu_name)

class_name HBMenu

func _ready():
	pass
func change_to_menu(menu_name: String):
	emit_signal("change_to_menu", menu_name)

func _on_menu_enter():
	pass
	
func _on_menu_exit():
	pass
