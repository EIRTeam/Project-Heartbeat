extends Window

@onready var tab_container = get_node("TabContainer")

@onready var song_settings_tab = get_node("TabContainer/Song")
@onready var general_settings_tab = get_node("TabContainer/General")
@onready var shortcuts_tab = get_node("TabContainer/Shortcuts/VBoxContainer/Panel")

func _on_song_variant_download_requested(song: HBSong, variant: int):
	hide()
	MouseTrap.cache_song_overlay.show_download_prompt(song, variant, false, true)
	await MouseTrap.cache_song_overlay.download_prompt_done
	show()

func _ready() -> void:
	song_settings_tab.song_variant_download_requested.connect(_on_song_variant_download_requested)
	YoutubeDL.song_cached.connect(_on_song_cached)

func _on_song_cached(song: HBSong):
	if song == song_settings_tab.editor.current_song:
		song_settings_tab.notify_song_media_cached()

func _input(event):
	if visible and event.is_action_pressed("gui_cancel", false, true) \
	   and not get_viewport().gui_get_focus_owner() is LineEdit:
		close_requested.emit()


func _about_to_hide():
	song_settings_tab._hide()
	general_settings_tab._hide()
