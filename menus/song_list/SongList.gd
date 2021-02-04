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
onready var folder_path = get_node("VBoxContainer/VBoxContainer2/HBoxContainer/FolderPath")
onready var folder_manager = get_node("FolderManager")
onready var add_to_prompt = get_node("VBoxContainer/Prompts/HBoxContainer/HBoxContainer/Panel8")
onready var manage_folders_prompt = get_node("VBoxContainer/Prompts/HBoxContainer/HBoxContainer/Panel9")
onready var remove_item_prompt = get_node("VBoxContainer/Prompts/HBoxContainer/HBoxContainer/Panel10")
var force_next_song_update = false
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
	if args.has("force_filter"):
		UserSettings.user_settings.filter_mode = args.force_filter
		UserSettings.save_user_settings()
	populate_buttons()
		
	set_filter(UserSettings.user_settings.filter_mode, false)
	
	var song_to_select = null
	var difficulty_to_select = null

	if args.has("song_difficulty"):
		difficulty_to_select = args.song_difficulty
	if args.has("song"):
		song_to_select = args.song
	update_songs(song_to_select, difficulty_to_select)
	
	MouseTrap.cache_song_overlay.connect("done", song_container, "grab_focus")
	MouseTrap.ppd_dialog.connect("youtube_url_selected", self, "_on_youtube_url_selected")
	MouseTrap.ppd_dialog.connect("file_selected", self, "_on_ppd_audio_file_selected")
	MouseTrap.ppd_dialog.connect("file_selector_hidden", song_container, "grab_focus")
	MouseTrap.ppd_dialog.connect("popup_hide", song_container, "grab_focus")
#	song_container.hard_arrange_all()
	
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
	#sort_button_texture_rect.texture = IconPackLoader.get_graphic("UP", "note")
	#fav_button_texture_rect.texture = IconPackLoader.get_graphic("LEFT", "note")
	if "force_url_request" in args:
		_on_PPDAudioBrowseWindow_accept()
func set_sort(sort_by):
	UserSettings.user_settings.sort_mode = sort_by
	UserSettings.save_user_settings()
	song_container.sort_by_prop = sort_by
	song_container.set_songs(SongLoader.songs.values())
	song_container.grab_focus()
	sort_by_list.hide()
func _on_ugc_item_installed(type, item):
	if type == "song":
		force_next_song_update = true

func _on_menu_exit(force_hard_transition = false):
	._on_menu_exit(force_hard_transition)
	MouseTrap.cache_song_overlay.disconnect("done", song_container, "grab_focus")
	MouseTrap.ppd_dialog.disconnect("youtube_url_selected", self, "_on_youtube_url_selected")
	MouseTrap.ppd_dialog.disconnect("file_selected", self, "_on_ppd_audio_file_selected")
	MouseTrap.ppd_dialog.disconnect("file_selector_hidden", song_container, "grab_focus")
	MouseTrap.ppd_dialog.disconnect("popup_hide", song_container, "grab_focus")
func _ready():
	song_container.connect("song_hovered", self, "_on_song_hovered")
	song_container.connect("hover_nonsong", self, "_on_non_song_hovered")
	song_container.connect("difficulty_selected", self, "_on_difficulty_selected")
	song_container.connect("updated_folders", self, "_on_folder_path_updated")
	$PPDAudioBrowseWindow.connect("accept", self, "_on_PPDAudioBrowseWindow_accept")
	$PPDAudioBrowseWindow.connect("cancel", song_container, "grab_focus")

	folder_manager.connect("closed", self, "_on_folder_manager_closed")
	folder_manager.connect("folder_selected", self, "_on_folder_selected")
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider as HBUGCService
		ugc.connect("ugc_item_installed", self, "_on_ugc_item_installed")
func _on_folder_path_updated(folders):
	var folder_str := "/"
	var ignore = true # we ignore the root
	for folder in folders:
		if ignore:
			ignore = false
			continue
		folder_str += "%s/" % [folder.folder_name]
	folder_str = folder_str.substr(0, folder_str.length()-1)
	folder_path.text_1 = folder_str

func _on_non_song_hovered():
	if UserSettings.user_settings.filter_mode == "folders":
		remove_item_prompt.hide()
		manage_folders_prompt.show()

func populate_buttons():
	var filter_types = {
		"all": "All",
		"official": "Official",

	}

	for child in filter_type_container.get_children():
		child.queue_free()
		filter_type_container.remove_child(child)
	
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id] as HBSong
		if song.comes_from_ugc():
			filter_types["workshop"] = "Workshop"
			break
	var has_local = false
	var has_editor = false
	var editor_songs_path = HBUtils.join_path(UserSettings.get_content_directories(true)[0], "editor_songs")
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		if song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER and not song is HBPPDSong:
			if song.path.begins_with(editor_songs_path):
				has_editor = true
				filter_types["editor"] = "Editor"
			else:
				has_local = true
				filter_types["local"] = "Local"
			if has_editor and has_local:
				break
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id] as HBSong
		if song is HBPPDSong:
			filter_types["ppd"] = "PPD"
	if not UserSettings.user_settings.filter_mode in filter_types and not UserSettings.user_settings.filter_mode == "folders":
		UserSettings.user_settings.filter_mode = "all"
	filter_types["folders"] = "Folders"
	for filter_type in filter_types:
		var button = HBHovereableButton.new()
		button.text = filter_types[filter_type]
		filter_type_container.add_child(button)
		if filter_type == UserSettings.user_settings.filter_mode:
			filter_type_container.select_button(button.get_position_in_parent(), false)
		button.connect("hovered", self, "set_filter", [filter_type])
		
func set_filter(filter_name, save=true):
	song_container.set_filter(filter_name)
	UserSettings.user_settings.filter_mode = filter_name
	if save:
		UserSettings.save_user_settings()
	if filter_name == "folders":
		add_to_prompt.hide()
		manage_folders_prompt.show()
		remove_item_prompt.hide()
		folder_path.show()
	else:
		add_to_prompt.show()
		manage_folders_prompt.hide()
		remove_item_prompt.hide()
		folder_path.hide()

func _on_song_hovered(song: HBSong):
	current_song = song
	emit_signal("song_hovered", song)
	if UserSettings.user_settings.filter_mode == "folders":
		manage_folders_prompt.hide()
		remove_item_prompt.show()

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
			if not event is InputEventJoypadMotion:
				filter_type_container._gui_input(event)
		if event.is_action_pressed("gui_cancel"):
			get_tree().set_input_as_handled()
			change_to_menu("main_menu")
		if event.is_action_pressed("note_up"):
			if not is_gui_directional_press("gui_up", event):
				get_tree().set_input_as_handled()
				show_order_by_list()
		if event.is_action_pressed("contextual_option"):
			if UserSettings.user_settings.filter_mode == "folders":
				var item = song_container.get_selected_item()
				if item and item is HBSongListItem:
					var folder = song_container.folder_stack[song_container.folder_stack.size()-1] as HBFolder
					folder.songs.erase(item.song.id)
					if folder.songs.size() == 0:
						song_container.navigate_back()
					else:
						song_container.update_items()
					
				else:
					folder_manager.show_manager(folder_manager.MODE.MANAGE)
			else:
				folder_manager.show_manager(folder_manager.MODE.SELECT)
	else:
		if event.is_action_pressed("gui_cancel") and sort_by_list.visible:
			sort_by_list.hide()
			song_container.grab_focus()

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

func _on_folder_manager_closed():
	if folder_manager.mode == folder_manager.MODE.MANAGE:
		song_container.go_to_root()
	song_container.grab_focus()

func update_songs(song_to_select=null, difficulty_to_select=null):
	$VBoxContainer/MarginContainer/VBoxContainer.set_songs(SongLoader.songs.values(), song_to_select, difficulty_to_select, force_next_song_update)
	force_next_song_update = false

func _on_folder_selected(folder: HBFolder):
	if not current_song.id in folder.songs:
		folder.songs.append(current_song.id)
		UserSettings.save_user_settings()
	song_container.grab_focus()

func _on_songs_reloaded():
	if song_container:
		song_container.last_filter = ""
