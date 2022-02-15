extends HBMenu
const APRIL_FOOLS_LOGO = preload("res://graphics/logo_april.png")
const VALENTINES_DAY_LOGO = preload("res://graphics/logo_valentines.png")

var song: HBSong

onready var event_logo_texture_rect: TextureRect = get_node("MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/EventLogoTextureRect")

func _ready():
	event_logo_texture_rect.texture = UserSettings.user_settings.get_event_logo()
	if UserSettings.user_settings.event_single_controller_mode:
		$VBoxContainer.hide()
		$PressStart/VBoxContainer/VBoxContainer/HBoxContainer/RandomQuote.text = tr("Press")
	
func _on_PressStart_start_pressed():
	if HBGame.platform_settings is HBPlatformSettingsSwitch:
		change_to_menu("switch_premenu")
	elif HBGame.demo_mode:
		change_to_menu("demo_premenu")
	else:
		if song:
			change_to_menu("song_list", false, {"song": song.id})
