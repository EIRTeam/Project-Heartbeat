extends HBMenu

const APRIL_FOOLS_LOGO = preload("res://graphics/logo_april.png")

func _ready():
	var date_time := OS.get_datetime()
	if date_time.day == 1 and date_time.month == 4:
		$PressStart/VBoxContainer/TextureRect3.texture = APRIL_FOOLS_LOGO


func _on_PressStart_start_pressed():
	if HBGame.platform_settings is HBPlatformSettingsSwitch:
		change_to_menu("switch_premenu")
	elif HBGame.demo_mode:
		change_to_menu("demo_premenu")
	else:
		change_to_menu("main_menu")
