extends HBMenu

class_name HBSongListMenu

signal song_hovered(song)
var current_difficulty
var current_song: HBSong
#onready var difficulty_list = get_node("VBoxContainer/DifficultyList")
onready var song_container = get_node("VBoxContainer/MarginContainer/VBoxContainer")
onready var filter_type_container = get_node("VBoxContainer/VBoxContainer2/HBoxContainer/VBoxContainer")
onready var sort_by_list = get_node("Panel")
onready var sort_by_list_container = get_node("Panel/MarginContainer/VBoxContainer")
onready var sort_button_texture_rect = get_node("VBoxContainer/VBoxContainer2/HBoxContainer/HBoxContainer/Panel/HBoxContainer2/SortButton")
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
#			sort_by_list_container.selected_button
	sort_button_texture_rect.texture = IconPackLoader.get_icon(HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.LEFT), "note")
func set_sort(sort_by):
	UserSettings.user_settings.sort_mode = sort_by
	UserSettings.save_user_settings()
	song_container.sort_by_prop = sort_by
	song_container.set_songs(SongLoader.songs.values())
	song_container.grab_focus()
	sort_by_list.hide()
func _on_ugc_item_installed(type, item):
	if type == "song":
		song_container.set_songs(SongLoader.songs, true)
		song_container.hard_arrange_all()
#	populate_difficulties(false)
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
	song_container.connect("song_selected", self, "_on_song_selected")
	var filter_types = {
		"all": "All",
		"official": "Official",

	}
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		if song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER:
			filter_types["community"] = "Community"
			break
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		if song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER:
			filter_types["ppd"] = "PPD"
			break
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
#func populate_difficulties(fire_event=true):
#	for child in difficulty_list.get_children():
#		difficulty_list.remove_child(child)
#		child.queue_free()
#	for difficulty in SongLoader.available_difficulties:
#		var button = HBHovereableButton.new()
#		button.focus_mode = FOCUS_NONE
#		button.text = difficulty.capitalize()
#		button.connect("hovered", self, "_select_difficulty", [difficulty])
#		button.set_meta("difficulty", difficulty)
#		difficulty_list.add_child(button)
#	if current_difficulty:
#		for i in range(difficulty_list.get_child_count()):
#			var button = difficulty_list.get_child(i)
#			if button.get_meta("difficulty") == current_difficulty:
#				difficulty_list.select_button(i, fire_event)
func _on_song_hovered(song: HBSong):
	current_song = song
	emit_signal("song_hovered", song)

func should_receive_input():
	return song_container.has_focus()
	

func _unhandled_input(event):
	if should_receive_input():
		if event.is_action_pressed("gui_left") or event.is_action_pressed("gui_right"):
			filter_type_container._gui_input(event)
		if event.is_action_pressed("gui_cancel"):
			get_tree().set_input_as_handled()
			change_to_menu("main_menu")
		if event.is_action_pressed("note_left"):
			show_order_by_list()
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
	SongLoader.set_ppd_youtube_url(current_song, url)
	song_container.grab_focus()
		
func _on_video_downloading():
	song_container.grab_focus()
#	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song, current_difficulty)



func update_songs():
	$VBoxContainer/MarginContainer/VBoxContainer.set_songs(SongLoader.songs.values())
