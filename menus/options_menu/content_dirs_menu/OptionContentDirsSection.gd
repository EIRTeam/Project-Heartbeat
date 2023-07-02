extends Control

signal back

@onready var scroll_container = get_node("VBoxContainer/Panel2/MarginContainer/ScrollContainer")
const PATH_SCENE = preload("res://menus/options_menu/content_dirs_menu/ContentDirControl.tscn")
@onready var bind_popup = get_node("Popup")

@onready var set_directory_confirmation_window = get_node("SetContentDirectoryConfirmationWindow")
@onready var file_dialog: FileDialog = MouseTrap.content_dir_dialog
@onready var content_reload_popup = get_node("ReloadingContentPopup")
@onready var content_reload_success_popup = get_node("ContentReloadSuccessPopup")
@onready var reset_content_directory_confirmation_window = get_node("ResetContentDirectoryConfirmationWindow")
@onready var cache_clear_success_popup = get_node("CacheClearSucccessPopup")
@onready var song_media_clear_success_popup: Popup = get_node("%SongMediaClearSuccessPopup")
var content_directory_control
var action_being_bound = ""

var mmplus_button: Control

var clear_unused_media_button: HBHovereableButton

func _unhandled_input(event):
	if visible:
		if event.is_action_pressed("gui_cancel"):
			if get_viewport().gui_get_focus_owner() == scroll_container:
				get_viewport().set_input_as_handled()
				file_dialog.hide()
				HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
				emit_signal("back")
				if scroll_container.get_selected_item():
					scroll_container.get_selected_item().stop_hover()
		else:
			if scroll_container.get_selected_item():
				if not event is InputEventMouse:
					if scroll_container.get_selected_item().has_method("_gui_input"):
						scroll_container.get_selected_item()._gui_input(event)

func _ready():
	populate()
	connect("focus_entered", Callable(self, "_on_focus_entered"))
	focus_mode = Control.FOCUS_ALL
	set_directory_confirmation_window.connect("accept", Callable(file_dialog, "popup_centered"))
	set_directory_confirmation_window.connect("cancel", Callable(self, "grab_focus"))
	reset_content_directory_confirmation_window.connect("accept", Callable(self, "_on_content_directory_reset"))
	reset_content_directory_confirmation_window.connect("cancel", Callable(self, "grab_focus"))
	content_reload_success_popup.connect("accept", Callable(self, "grab_focus"))
	cache_clear_success_popup.connect("accept", Callable(get_tree(), "quit"))
	file_dialog.connect("dir_selected", Callable(self, "_on_path_selected"))
	file_dialog.connect("popup_hide", Callable(self, "grab_focus"))
	song_media_clear_success_popup.connect("popup_hide", Callable(self, "grab_focus"))
	SongLoader.connect("all_songs_loaded", Callable(self, "_on_content_reload_complete"))
func populate():
	var children = scroll_container.item_container.get_children()
	for child in children:
		scroll_container.item_container.remove_child(child)
		child.queue_free()
		
	var add_content_path_button = HBHovereableButton.new()
	add_content_path_button.text = tr("Reset content directory to default")
	add_content_path_button.expand_icon = true
	add_content_path_button.connect("pressed", Callable(reset_content_directory_confirmation_window, "popup_centered"))
	
	var reload_content_button = HBHovereableButton.new()
	reload_content_button.text = tr("Reload all songs")
	reload_content_button.expand_icon = true
	reload_content_button.connect("pressed", Callable(self, "_on_content_reload"))
	
	var clear_cache_button = HBHovereableButton.new()
	clear_cache_button.text = tr("Clear cache")
	clear_cache_button.expand_icon = true
	clear_cache_button.connect("pressed", Callable(self, "_on_cache_cleared"))
	
	var download_all_song_media = HBHovereableButton.new()
	download_all_song_media.text = tr("Download all song media")
	download_all_song_media.expand_icon = true
	download_all_song_media.connect("pressed", Callable(self, "_on_download_all_song_media"))
	
	clear_unused_media_button = HBHovereableButton.new()
	clear_unused_media_button.text = tr("Clean unused song media") + " (%s)" % ["".humanize_size(YoutubeDL.unused_cache_size)]
	clear_unused_media_button.connect("pressed", Callable(self, "_on_clear_unused_media"))
	
	scroll_container.item_container.add_child(reload_content_button)
	scroll_container.item_container.add_child(add_content_path_button)
	scroll_container.item_container.add_child(clear_cache_button)
	scroll_container.item_container.add_child(download_all_song_media)
	scroll_container.item_container.add_child(clear_unused_media_button)
	
	content_directory_control = PATH_SCENE.instantiate()
	content_directory_control.dir = UserSettings.user_settings.content_path
	content_directory_control.connect("pressed", Callable(set_directory_confirmation_window, "popup_centered"))
	scroll_container.item_container.add_child(content_directory_control)
	
	mmplus_button = preload("res://menus/options_menu/content_dirs_menu/MMPlusControl.tscn").instantiate()
	scroll_container.item_container.add_child(mmplus_button)
	mmplus_button.set_value(UserSettings.user_settings.enable_system_mmplus_loading)
	mmplus_button.connect("changed", Callable(self, "_on_mmplus_option_changed"))
	mmplus_button.update_error()
	
func _on_mmplus_option_changed(new_value: bool):
	UserSettings.user_settings.enable_system_mmplus_loading = new_value
	UserSettings.save_user_settings()
	HBGame.mmplus_error = HBGame.MMPLUS_ERROR.NEEDS_RESTART
	mmplus_button.update_error()
	
func _on_path_selected(path):
	UserSettings.user_settings.content_path = path
	UserSettings.save_user_settings()
	_on_content_reload()
	content_directory_control.dir = UserSettings.user_settings.content_path
	
func _on_cache_cleared():
	SongDataCache.clear_cache()
	cache_clear_success_popup.popup_centered()
	cache_clear_success_popup.grab_focus()
	
func _on_content_reload_complete():
	content_reload_popup.hide()
	content_reload_success_popup.popup_centered()
	content_reload_success_popup.grab_focus()
	
func _on_content_reload():
	content_reload_popup.popup_centered()
	content_reload_popup.grab_focus()
	SongLoader.load_all_songs_async()
	
func _on_focus_entered():
	if not action_being_bound:
		scroll_container.grab_focus()

func _on_content_directory_reset():
	UserSettings.user_settings.content_path = HBUserSettings.new().content_path
	UserSettings.save_user_settings()
	file_dialog.hide()
	_on_content_reload()
	content_directory_control.dir = UserSettings.user_settings.content_path

func _on_clear_unused_media():
	YoutubeDL.clear_unused_media()
	clear_unused_media_button.text = tr("Clean unused song media") + " (%s)" % ["".humanize_size(YoutubeDL.unused_cache_size)]
	song_media_clear_success_popup.popup_centered()
	song_media_clear_success_popup.grab_focus()

func _on_download_all_song_media():
	for song_id in SongLoader.songs:
		var song := SongLoader.songs[song_id] as HBSong
		if song.youtube_url != "":
			if not song.is_cached():
				song.cache_data()
