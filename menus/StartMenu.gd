extends HBMenu

const APRIL_FOOLS_LOGO = preload("res://graphics/logo_april.png")
const VALENTINES_DAY_LOGO = preload("res://graphics/logo_valentines.png")
@onready var birthday_hat: Control = %BirthdayHat
@onready var random_quote: Control = %RandomQuote

func _ready():
	super._ready()
	var date_time := Time.get_datetime_dict_from_system()
	if date_time.day == 1 and date_time.month == Time.MONTH_APRIL:
		$PressStart/VBoxContainer/TextureRect3.texture = APRIL_FOOLS_LOGO
	elif date_time.day == 14 and date_time.month == Time.MONTH_FEBRUARY:
		$PressStart/VBoxContainer/TextureRect3.texture = VALENTINES_DAY_LOGO
	birthday_hat.hide()
	random_quote.birthday_triggered.connect(birthday_hat.show)
	#elif date_time.day == 20 and date_time.month == Time.MONTH_MARCH:

func _on_PressStart_start_pressed():
	if UserSettings.user_settings.content_path == "user://" and OS.has_feature("mobile"):
		change_to_menu("mobile_content_dir_set")
		return
	if HBGame.demo_mode:
		change_to_menu("demo_premenu")
		return
	if not UserSettings.user_settings.oob_completed:
		change_to_menu("oob")
		return
	if HBGame.platform_settings is HBPlatformSettingsSwitch:
		change_to_menu("switch_premenu")
	else:
		change_to_menu("main_menu")
