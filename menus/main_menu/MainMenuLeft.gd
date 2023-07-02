extends HBMenu

@onready var start_menu = get_node("VBoxContainer/StartMenu")

const APRIL_FOOLS_LOGO = preload("res://graphics/logo_april.png")

signal right

func _ready():
	super._ready()
	var date_time = Time.get_datetime_dict_from_system()
	if date_time.day == 1 and date_time.month == 4:
		$TextureRect2.texture = APRIL_FOOLS_LOGO
	start_menu.connect("navigate_to_menu", Callable(self, "change_to_menu"))
	if not PlatformService.service_provider.implements_lobby_list or HBGame.demo_mode:
		get_tree().call_group("mponly", "free")
	if HBGame.demo_mode:
		get_tree().call_group("nodemo", "free")
	else:
		get_tree().call_group("demo_only", "free")
		
func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	start_menu.grab_focus()
	
func _on_discord_server_pressed():
	OS.shell_open("https://discord.com/invite/qGMdbez")

func _input(event):
	if event.is_action_pressed("gui_right"):
		if start_menu.has_focus():
			get_viewport().set_input_as_handled()
			emit_signal("right")
			HBGame.fire_and_forget_sound(HBGame.menu_press_sfx, HBGame.sfx_group)

func _on_left_from_MainMenuRight():
	start_menu.grab_focus()
