extends ColorRect

onready var event_logo_option_button: OptionButton = get_node("VBoxContainer/TabContainer/Visual/VBoxContainer/EventLogoOptionButton")
onready var event_ugly_bg_song_text_edit: TextEdit = get_node("VBoxContainer/TabContainer/Visual/VBoxContainer/UglyBGSongTextEdit")

func _ready():
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	event_logo_option_button.set_block_signals(true)
	for event_name in HBUserSettings.EVENT_LOGO:
		var event_id = HBUserSettings.EVENT_LOGO[event_name]
		event_logo_option_button.add_item(event_name.capitalize(), event_id)
		if event_id == UserSettings.user_settings.event_logo:
			event_logo_option_button.select(event_logo_option_button.get_item_count()-1)
	event_logo_option_button.set_block_signals(false)
	event_ugly_bg_song_text_edit.set_block_signals(true)
	event_ugly_bg_song_text_edit.text = PoolStringArray(UserSettings.user_settings.event_ugly_bg_songs).join("\n")
	event_ugly_bg_song_text_edit.set_block_signals(false)

func save_settings():
	UserSettings.user_settings.event_logo = event_logo_option_button.get_selected_id()
	UserSettings.user_settings.event_ugly_bg_songs = event_ugly_bg_song_text_edit.text.split("\n")
	UserSettings.save_user_settings()

func _on_OpenNormalSettingsButton_pressed():
	var scene = load("res://menus/MainMenu3D.tscn").instance()
	get_tree().current_scene.queue_free()
	scene.starting_menu = "options_menu"
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	get_tree().paused = false


func _on_RestartButton_pressed():
	var scene = load("res://menus/MainMenu3D.tscn").instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	get_tree().paused = false
	
func _on_EventLogoOptionButton_item_selected(_index):
	save_settings()

func _on_UglyBGSongTextEdit_text_changed():
	save_settings()


func _on_TestThankYouButton_pressed():
	var scene = load("res://menus/MainMenu3D.tscn").instance()
	scene.starting_menu = "event_thank_you"
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	get_tree().paused = false
