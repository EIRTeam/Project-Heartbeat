extends "res://menus/tutorial/TutorialScreen.gd"

func _unhandled_input(event):
	if (event is InputEventJoypadButton and event.pressed) \
			or (event is InputEventKey and event.pressed):
		change_to_menu("main_menu")
