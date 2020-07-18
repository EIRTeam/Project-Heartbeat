extends HBMenu

class_name HBSongListMenu

signal song_hovered(song)
var current_difficulty
var current_song: HBSong
var pevent_pregame_screen = false
#onready var difficulty_list = get_node("VBoxContainer/DifficultyList")
onready var song_container = get_node("VBoxContainer/MarginContainer/VBoxContainer")
onready var filter_type_container = get_node("VBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer")
onready var sort_by_list = get_node("Panel")
onready var sort_by_list_container = get_node("Panel/MarginContainer/VBoxContainer")
onready var sort_button_texture_rect = get_node("VBoxContainer/VBoxContainer2/HBoxContainer/HBoxContainer/Panel/HBoxContainer2/SortButtonLeft")
onready var fav_button_texture_rect = get_node("VBoxContainer/VBoxContainer2/HBoxContainer/HBoxContainer/Panel2/HBoxContainer2/FavButton")
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
#	populate_difficulties()
	song_container.grab_focus()
#	if args.has("song_difficulty"):
##		_select_difficulty(args.song_difficulty)
#		for i in range(difficulty_list.get_child_count()):
#			var button = difficulty_list.get_child(i)
#			if button.get_meta("difficulty") == args.song_difficulty:
#				difficulty_list.select_button(i)
#	else:
#		difficulty_list.select_button(0)
	if UserSettings.user_settings.filter_mode == "favorites" \
			and UserSettings.user_settings.favorite_songs.empty():
		UserSettings.user_settings.filter_mode = "all"
	populate_buttons()
	song_container.set_filter(UserSettings.user_settings.filter_mode)
	update_songs()

	if args.has("song_difficulty"):
		$VBoxContainer/MarginContainer/VBoxContainer.select_song_by_id(args.song, args.song_difficulty)
	elif args.has("song"):
		$VBoxContainer/MarginContainer/VBoxContainer.select_song_by_id(args.song)
	MouseTrap.cache_song_overlay.connect("done", song_container, "grab_focus")
	MouseTrap.ppd_dialog.connect("youtube_url_selected", self, "_on_youtube_url_selected")
	MouseTrap.ppd_dialog.connect("file_selected", self, "_on_ppd_audio_file_selected")
	MouseTrap.ppd_dialog.connect("file_selector_hidden", song_container, "grab_focus")
	MouseTrap.ppd_dialog.connect("popup_hide", song_container, "grab_focus")
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider as HBUGCService
		ugc.connect("ugc_item_installed", self, "_on_ugc_item_installed")
	song_container.hard_arrange_all()
	
	var allowed_sort_by = {
		"title": "Title",
		"artist": "Artist",
		"score": "Difficulty",
		"creator": "Chart Creator"
	}
	
	for button in sort_by_list_container.get_children():
		sort_by_list_container.remove_child(button)
		button.queue_free()
	
	for sort_by in allowed_sort_by:
		var button = HBHovereableButton.new()
		button.text = allowed_sort_by[sort_by]
		button.connect("pressed", self, "set_sort", [sort_by])
		sort_by_list_container.add_child(button)
		# We ensure the current sort mode is selected by default
		if sort_by == UserSettings.user_settings.sort_mode:
			sort_by_list_container.select_button(button.get_position_in_parent())
	sort_button_texture_rect.texture = IconPackLoader.get_graphic("UP", "note")
	fav_button_texture_rect.texture = IconPackLoader.get_graphic("LEFT", "note")
	if "force_url_request" in args:
		_on_PPDAudioBrowseWindow_accept()
func set_sort(sort_by):
	UserSettings.user_settings.sort_mode = sort_by
	UserSettings.save_user_settings()
	song_container.sort_by_prop = sort_by
	song_container.set_songs(SongLoader.songs.values())
	song_container.grab_focus()
	song_container.hard_arrange_all()
	sort_by_list.hide()
func _on_ugc_item_installed(type, item):
	if type == "song":
		song_container.set_songs(SongLoader.songs.values())
		song_container.hard_arrange_all()

func _on_menu_exit(force_hard_transition = false):
	._on_menu_exit(force_hard_transition)
	MouseTrap.cache_song_overlay.disconnect("done", song_container, "grab_focus")
	MouseTrap.ppd_dialog.disconnect("youtube_url_selected", self, "_on_youtube_url_selected")
	MouseTrap.ppd_dialog.disconnect("file_selected", self, "_on_ppd_audio_file_selected")
	MouseTrap.ppd_dialog.disconnect("file_selector_hidden", song_container, "grab_focus")
	MouseTrap.ppd_dialog.disconnect("popup_hide", song_container, "grab_focus")
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider as HBUGCService
		ugc.disconnect("ugc_item_installed", self, "_on_ugc_item_installed")
func _ready():
	song_container.connect("song_hovered", self, "_on_song_hovered")
	song_container.connect("difficulty_selected", self, "_on_difficulty_selected")
	$PPDAudioBrowseWindow.connect("accept", self, "_on_PPDAudioBrowseWindow_accept")
	$PPDAudioBrowseWindow.connect("cancel", song_container, "grab_focus")


func populate_buttons():
	var filter_types = {
		"all": "All",
		"official": "Official",

	}
	
	for child in filter_type_container.get_children():
		child.queue_free()
		filter_type_container.remove_child(child)
	
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		if song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER and not song is HBPPDSong:
			filter_types["community"] = "Community"
			break
	if UserSettings.user_settings.favorite_songs.size() > 0:
		filter_types["favorites"] = "Favorites"
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id] as HBSong
		if song is HBPPDSong:
			filter_types["ppd"] = "PPD"
	if not UserSettings.user_settings.filter_mode in filter_types:
		UserSettings.user_settings.filter_mode = "all"
	for filter_type in filter_types:
		var button = HBHovereableButton.new()
		button.text = filter_types[filter_type]
		filter_type_container.add_child(button)
		if filter_type == UserSettings.user_settings.filter_mode:
			filter_type_container.select_button(button.get_position_in_parent(), false)
		button.connect("hovered", self, "set_filter", [filter_type])
		
func set_filter(filter_name):
	song_container.set_filter(filter_name)
	UserSettings.user_settings.filter_mode = filter_name
	UserSettings.save_user_settings()

func _on_song_hovered(song: HBSong):
	current_song = song
	emit_signal("song_hovered", song)

func should_receive_input():
	return song_container.has_focus()
	

func is_gui_directional_press(action: String, event):
	var gui_press = false
	
	# This is so the d-pad doesn't trigger the order by list
	for mapped_event in InputMap.get_action_list(action):
		if mapped_event.device == event.device:
			if mapped_event is InputEventKey and event is InputEventKey:
				if mapped_event.scancode == event.scancode:
					gui_press = true
					break
			if mapped_event is InputEventJoypadButton and event is InputEventJoypadButton:
				if mapped_event.button_index == event.button_index:
					gui_press = true
					break
	return gui_press
func _unhandled_input(event):
	if should_receive_input():
		if event.is_action_pressed("gui_left") or event.is_action_pressed("gui_right"):
			filter_type_container._gui_input(event)
		if event.is_action_pressed("gui_cancel"):
			get_tree().set_input_as_handled()
			change_to_menu("main_menu")
		if event.is_action_pressed("note_up"):
			if not is_gui_directional_press("gui_up", event):
				get_tree().set_input_as_handled()
				show_order_by_list()
		if event.is_action_pressed("note_left"):
			if not is_gui_directional_press("gui_left", event):
				get_tree().set_input_as_handled()
				toggle_current_song_favorite()
	else:
		if event.is_action_pressed("gui_cancel") and sort_by_list.visible:
			sort_by_list.hide()
			song_container.grab_focus()
			
func toggle_current_song_favorite():
	var list_item = song_container.selected_option as HBSongListItem
	if UserSettings.is_song_favorited(current_song):
		UserSettings.remove_song_from_favorites(current_song)
		list_item.set_favorite(false)
		if UserSettings.user_settings.filter_mode == "favorites":
			if UserSettings.user_settings.favorite_songs.size() == 0:
				UserSettings.user_settings.filter_mode = "all"
				song_container.set_filter("all")
			else:
				var old_option = song_container.selected_option
				var pos = song_container.selected_option.get_position_in_parent()-1
				song_container.remove_child(old_option)
				old_option.queue_free()
				song_container.select_option(max(pos, 0))
	else:
		UserSettings.add_song_to_favorites(current_song)
		list_item.set_favorite(true)
	populate_buttons()
	UserSettings.save_user_settings()
func show_order_by_list():
	sort_by_list.show()
	sort_by_list_container.grab_focus()
	
func _on_difficulty_selected(song: HBSong, difficulty):
	print("select ", song.title, " with diff ", difficulty)
	if song is HBPPDSong and not song.has_audio() and not song.youtube_url:
		$PPDAudioBrowseWindow.popup_centered_ratio(0.5)
		return
	if song.is_cached():
		change_to_menu("pre_game", false, {"song": song, "difficulty": difficulty})
	else:
		MouseTrap.cache_song_overlay.show_download_prompt(song)
	
func _on_ppd_audio_file_selected(path: String):
	var directory = Directory.new()
	current_song.audio = path.get_file()
	var song_path = current_song.get_song_audio_res_path()
	directory.copy(path, song_path)
func _on_PPDAudioBrowseWindow_accept():
	MouseTrap.ppd_dialog.ask_for_file()
func _on_youtube_url_selected(url):
	var loader = SongLoader.get_song_loader("ppd") as SongLoaderPPD
	if loader:
		loader.set_ppd_youtube_url(current_song, url)
	song_container.grab_focus()
		
func _on_video_downloading():
	song_container.grab_focus()



func update_songs():
	$VBoxContainer/MarginContainer/VBoxContainer.set_songs(SongLoader.songs.values())
