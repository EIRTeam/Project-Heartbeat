extends HBMenu

class_name HBSongListMenu

signal song_hovered(song)
var current_difficulty
var current_song: HBSong
var pevent_pregame_screen = false
#onready var difficulty_list = get_node("VBoxContainer/DifficultyList")
@onready var song_container = get_node("VBoxContainer/MarginContainer/VBoxContainer")
@onready var filter_type_container = get_node("VBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer")
@onready var sort_by_list = get_node("CenterContainer/SortByPanel")
@onready var sort_by_list_container = get_node("CenterContainer/SortByPanel/MarginContainer/VBoxContainer")
@onready var folder_path = get_node("VBoxContainer/VBoxContainer2/HBoxContainer/FolderPath")
@onready var folder_manager = get_node("FolderManager")
@onready var add_to_prompt = get_node("VBoxContainer/Prompts/HBoxContainer/HBoxContainer/Panel8")
@onready var manage_folders_prompt = get_node("VBoxContainer/Prompts/HBoxContainer/HBoxContainer/Panel9")
@onready var remove_item_prompt = get_node("VBoxContainer/Prompts/HBoxContainer/HBoxContainer/Panel10")
@onready var song_count_indicator = get_node("SongCountIndicator")
@onready var search_text_input = get_node("SearchTextInput")
@onready var sort_by_option_button: HBHovereableOptionButton = get_node("CenterContainer/SortByPanel/MarginContainer/VBoxContainer/OptionButton")
@onready var sort_mode_label: Label = get_node("VBoxContainer/VBoxContainer2/HBoxContainer/PanelContainer/HBoxContainer2/Label")
@onready var has_media_checkbox: CheckBox = get_node("CenterContainer/SortByPanel/MarginContainer/VBoxContainer/HasMediaCheckbox")
@onready var has_media_filter_texture_rect := get_node("VBoxContainer/VBoxContainer2/HBoxContainer/PanelContainer/HBoxContainer2/TextureRect2")

var force_next_song_update = false

var allowed_sort_by = {
	"title": tr("Title"),
	"artist": tr("Artist"),
	"highest_score": tr("Highest Difficulty"),
	"lowest_score": tr("Lowest Difficulty"),
	"creator": tr("Chart Creator"),
	"bpm": tr("BPM"),
	"_added_time": tr("Last Subscribed"),
	"_times_played": tr("Times played"),
	"_released_time": tr("Last released"),
	"_updated_time": tr("Last updated")
}

func populate_sort_by_list():
	var workshop_only_sort_by = ["_added_time", "_released_time", "_updated_time"]
	
	sort_by_option_button.clear()
	sort_by_option_button.set_block_signals(true)
	for sort_by in allowed_sort_by:
		if sort_by in workshop_only_sort_by and not UserSettings.user_settings.filter_mode == "workshop":
			continue
		sort_by_option_button.add_item(allowed_sort_by[sort_by], sort_by)
		# We ensure the current sort mode is selected by default
		var current_sort_mode = UserSettings.user_settings.sort_mode
		if UserSettings.user_settings.filter_mode == "workshop":
			current_sort_mode = UserSettings.user_settings.workshop_tab_sort_mode
		if sort_by == current_sort_mode:
			sort_by_option_button.selected_item = sort_by_option_button.get_item_count()-1
	sort_by_option_button.set_block_signals(false)

func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	if PlatformService.service_provider.implements_ugc:
		PlatformService.service_provider.ugc_provider.connect("ugc_song_meta_updated", Callable(self, "_on_ugc_song_meta_updated"))
#	populate_difficulties()
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
		
	sort_by_list.hide()
		
	has_media_checkbox.set_block_signals(true)
	has_media_checkbox.button_pressed = UserSettings.user_settings.filter_has_media
	has_media_checkbox.set_block_signals(false)
	has_media_filter_texture_rect.visible = UserSettings.user_settings.filter_has_media
		
	set_filter(UserSettings.user_settings.filter_mode, false)
	
	var song_to_select = null
	var difficulty_to_select = null

	if args.has("song_difficulty"):
		difficulty_to_select = args.song_difficulty
	if args.has("song"):
		song_to_select = args.song
	update_songs(song_to_select, difficulty_to_select)
	MouseTrap.cache_song_overlay.connect("done", Callable(song_container, "grab_focus").bind(), CONNECT_DEFERRED)
	MouseTrap.ppd_dialog.connect("youtube_url_selected", Callable(self, "_on_youtube_url_selected"))
	MouseTrap.ppd_dialog.connect("file_selected", Callable(self, "_on_ppd_audio_file_selected"))
	MouseTrap.ppd_dialog.connect("file_selector_hidden", Callable(song_container, "grab_focus").bind(), CONNECT_DEFERRED)
	MouseTrap.ppd_dialog.connect("popup_hide", Callable(song_container, "grab_focus").bind(), CONNECT_DEFERRED)
#	song_container.hard_arrange_all()
	#sort_button_texture_rect.texture = IconPackLoader.get_graphic("UP", "note")
	#fav_button_texture_rect.texture = IconPackLoader.get_graphic("LEFT", "note")
	if "force_url_request" in args:
		_on_PPDAudioBrowseWindow_accept()
	song_container.grab_focus()

	
func _on_ugc_song_meta_updated():
	if UserSettings.user_settings.workshop_tab_sort_mode in ["_added_time", "_updated_time", "_released_time"] \
			and UserSettings.user_settings.filter_mode == "workshop":
		song_container.set_songs(SongLoader.songs.values(), null, null, true)
	
func set_sort(sort_by):
	if UserSettings.user_settings.filter_mode == "workshop":
		UserSettings.user_settings.workshop_tab_sort_mode = sort_by
	else:
		UserSettings.user_settings.sort_mode = sort_by
	UserSettings.save_user_settings()
	song_container.sort_by_prop = sort_by
	song_container.set_songs(SongLoader.songs.values(), null, null, true)
	update_sort_label(sort_by)
func update_sort_label(sort_by):
	sort_mode_label.text = tr("Sorting by %s") % [allowed_sort_by[sort_by]]
	
#	song_container.grab_focus()
#	sort_by_list.hide()
func _on_ugc_item_installed(type, item):
	if type == "song":
		force_next_song_update = true

func _on_menu_exit(force_hard_transition = false):
	super._on_menu_exit(force_hard_transition)
	MouseTrap.cache_song_overlay.disconnect("done", Callable(song_container, "grab_focus"))
	MouseTrap.ppd_dialog.disconnect("youtube_url_selected", Callable(self, "_on_youtube_url_selected"))
	MouseTrap.ppd_dialog.disconnect("file_selected", Callable(self, "_on_ppd_audio_file_selected"))
	MouseTrap.ppd_dialog.disconnect("file_selector_hidden", Callable(song_container, "grab_focus"))
	MouseTrap.ppd_dialog.disconnect("popup_hide", Callable(song_container, "grab_focus"))
	if PlatformService.service_provider.implements_ugc:
		PlatformService.service_provider.ugc_provider.disconnect("ugc_song_meta_updated", Callable(self, "_on_ugc_song_meta_updated"))
	HBGame.rich_presence.update_activity({
		"state": "On main menu"
	})
func set_media_checkbox(pressed: bool):
	UserSettings.user_settings.filter_has_media = pressed
	UserSettings.save_user_settings()
	song_container.set_songs(SongLoader.songs.values(), null, null, true)
	has_media_filter_texture_rect.visible = pressed
func _ready():
	super._ready()
	has_media_checkbox.connect("toggled", Callable(self, "set_media_checkbox"))
	sort_by_option_button.connect("selected", Callable(self, "set_sort"))
	song_container.connect("song_hovered", Callable(self, "_on_song_hovered"))
	song_container.connect("hover_nonsong", Callable(self, "_on_non_song_hovered"))
	song_container.connect("difficulty_selected", Callable(self, "_on_difficulty_selected"))
	song_container.connect("updated_folders", Callable(self, "_on_folder_path_updated"))
	$PPDAudioBrowseWindow.connect("accept", Callable(self, "_on_PPDAudioBrowseWindow_accept"))
	$PPDAudioBrowseWindow.connect("cancel", Callable(song_container, "grab_focus"))

	folder_manager.connect("closed", Callable(self, "_on_folder_manager_closed"))
	folder_manager.connect("folder_selected", Callable(self, "_on_folder_selected"))
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider as HBUGCService
		ugc.connect("ugc_item_installed", Callable(self, "_on_ugc_item_installed"))
	search_text_input.connect("entered", Callable(self, "_on_search_entered"))
	search_text_input.connect("cancel", Callable(song_container, "grab_focus"))
	
func _on_search_entered(text: String):
	song_container.search_term = text.to_lower()
	force_next_song_update = true
	update_songs()
	search_text_input.hide()
	song_container.grab_focus()
	
	if song_container.filter_by == "folders":
		song_container.update_items()
	
	update_path_label()
	
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
	var has_dsc = false
	var has_mmplus = false
	var has_mmplus_mod = false
	var editor_songs_path = HBUtils.join_path(UserSettings.get_content_directories(true)[0], "editor_songs")
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		if song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER and not song is HBPPDSong:
			if song.path.begins_with(editor_songs_path):
				has_editor = true
				filter_types["editor"] = "Editor"
			elif song is SongLoaderDSC.HBSongMMPLUS and not song.is_built_in:
				has_mmplus_mod = true
				filter_types["mmplus_mod"] = "MM+ (Mod)"
			elif song is SongLoaderDSC.HBSongMMPLUS:
				has_mmplus = true
				filter_types["mmplus"] = "MM+"
			elif song is SongLoaderDSC.HBSongDSC:
				has_dsc = true
				filter_types["dsc"] = "DSC"
			else:
				has_local = true
				filter_types["local"] = "Local"
			if has_editor and has_local and has_dsc and has_mmplus and has_mmplus_mod:
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
			filter_type_container.select_button(button.get_index(), false)
		button.connect("hovered", Callable(self, "set_filter").bind(filter_type))
		
func set_filter(filter_name, save=true):
	song_container.search_term = ""
	song_container.set_filter(filter_name)
	var old_filter_mode = UserSettings.user_settings.filter_mode
	UserSettings.user_settings.filter_mode = filter_name
	if save:
		UserSettings.save_user_settings()
	if old_filter_mode != filter_name:
		if filter_name == "workshop":
			set_sort(UserSettings.user_settings.workshop_tab_sort_mode)
		else:
			set_sort(UserSettings.user_settings.sort_mode)
	if filter_name == "workshop":
		update_sort_label(UserSettings.user_settings.workshop_tab_sort_mode)
	else:
		update_sort_label(UserSettings.user_settings.sort_mode)
	update_path_label()
func update_path_label():
	if UserSettings.user_settings.filter_mode == "folders":
		add_to_prompt.hide()
		manage_folders_prompt.show()
		remove_item_prompt.hide()
	else:
		add_to_prompt.show()
		manage_folders_prompt.hide()
		remove_item_prompt.hide()
		folder_path.text_1 = ""
	if song_container.search_term:
		folder_path.text_2 = tr("Search: \"%s\"" % [song_container.search_term])
		if folder_path.text_1:
			folder_path.text_2 = " |  " + folder_path.text_2
	else:
		folder_path.text_2 = ""

func _on_song_hovered(song: HBSong):
	current_song = song
	emit_signal("song_hovered", song)
	if UserSettings.user_settings.filter_mode == "folders":
		manage_folders_prompt.hide()
		remove_item_prompt.show()
	song_count_indicator.text = "%d/%d" % [song_container.filtered_song_items.keys().find(song)+1, song_container.filtered_song_items.size()]

	HBGame.rich_presence.update_activity({
		"state": "In song list",
		"details": "%s" % [current_song.title],
		"start_timestamp": Time.get_unix_time_from_system()
	})

func should_receive_input(event):
	var shift = false
	if event is InputEventKey:
		shift = event.shift_pressed
	
	return song_container.has_focus() and not shift
	
func _unhandled_input(event):
	if should_receive_input(event):
		if event.is_action_pressed("gui_left") or event.is_action_pressed("gui_right"):
			if not event is InputEventJoypadMotion:
				filter_type_container._gui_input(event)
		elif event.is_action_pressed("gui_search"):
			search_text_input.line_edit.text = song_container.search_term
			search_text_input.line_edit.caret_column = song_container.search_term.length()
			search_text_input.popup_centered()
		elif event.is_action_pressed("gui_cancel"):
			HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
			get_viewport().set_input_as_handled()
			if song_container.search_term:
				song_container.search_term = ""
				update_path_label()
				force_next_song_update = true
				update_songs()
			else:
				change_to_menu("main_menu")
		elif event.is_action_pressed("gui_sort_by"):
			get_viewport().set_input_as_handled()
			show_order_by_list()
		elif event.is_action_pressed("contextual_option"):
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
			HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
			sort_by_list.hide()
			song_container.grab_focus()

func show_order_by_list():
	populate_sort_by_list()
	sort_by_list.show()
	sort_by_list_container.select_button(1)
	sort_by_list_container.grab_focus()
	
func _on_difficulty_selected(song: HBSong, difficulty):
	if song is HBPPDSong and not song is HBPPDSongEXT and not song.has_audio() and not song.youtube_url:
		$PPDAudioBrowseWindow.popup_centered_ratio(0.5)
		return
	if song.is_cached() or (song is HBPPDSongEXT and song.has_audio()):
		change_to_menu("pre_game", false, {"song": song, "difficulty": difficulty})
	else:
		MouseTrap.cache_song_overlay.show_download_prompt(song)
	
func _on_ppd_audio_file_selected(path: String):
	current_song.audio = path.get_file()
	var song_path = current_song.get_song_audio_res_path()
	DirAccess.copy_absolute(path, song_path)
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
