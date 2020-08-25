extends HBMenu

func _ready():
	pass


func _on_PressStart_start_pressed():
	if HBGame.demo_mode:
		change_to_menu("demo_premenu")
	else:
		change_to_menu("main_menu")
