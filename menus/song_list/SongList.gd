extends HBMenu

class_name HBSongListMenu

signal song_hovered(song)
var current_difficulty
var current_song: HBSong
onready var difficulty_list = get_node("VBoxContainer/DifficultyList")
onready var scroll_container = get_node("VBoxContainer/MarginContainer/ScrollContainer")
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	scroll_container.grab_focus()
	if args.has("song_difficulty"):
#		_select_difficulty(args.song_difficulty)
		for i in range(difficulty_list.get_child_count()):
			var button = difficulty_list.get_child(i)
			if button.get_meta("difficulty") == args.song_difficulty:
				difficulty_list.select_button(i)
	else:
		difficulty_list.select_button(0)
	if args.has("song"):
		$VBoxContainer/MarginContainer/ScrollContainer.select_song_by_id(args.song)
	MouseTrap.cache_song_overlay.connect("video_downloaded", self, "_on_video_downloaded")
	MouseTrap.cache_song_overlay.connect("user_rejected", scroll_container, "grab_focus")
	MouseTrap.cache_song_overlay.connect("download_error", scroll_container, "grab_focus")
	MouseTrap.ppd_dialog.connect("youtube_url_selected", self, "_on_youtube_url_selected")
	MouseTrap.ppd_dialog.connect("file_selected", self, "_on_ppd_audio_file_selected")
	MouseTrap.ppd_dialog.connect("file_selector_hidden", scroll_container, "grab_focus")
	MouseTrap.ppd_dialog.connect("popup_hide", scroll_container, "grab_focus")

func _on_menu_exit(force_hard_transition = false):
	._on_menu_exit(force_hard_transition)
	MouseTrap.cache_song_overlay.disconnect("video_downloaded", self, "_on_video_downloaded")
	MouseTrap.cache_song_overlay.disconnect("user_rejected", scroll_container, "grab_focus")
	MouseTrap.cache_song_overlay.disconnect("download_error", scroll_container, "grab_focus")
	MouseTrap.ppd_dialog.disconnect("youtube_url_selected", self, "_on_youtube_url_selected")
	MouseTrap.ppd_dialog.disconnect("file_selected", self, "_on_ppd_audio_file_selected")
	MouseTrap.ppd_dialog.disconnect("file_selector_hidden", scroll_container, "grab_focus")
	MouseTrap.ppd_dialog.disconnect("popup_hide", scroll_container, "grab_focus")
func _ready():
	$VBoxContainer/MarginContainer/ScrollContainer.connect("song_hovered", self, "_on_song_hovered")
	for difficulty in SongLoader.available_difficulties:
		var button = HBHovereableButton.new()
		button.focus_mode = FOCUS_NONE
		button.text = difficulty.capitalize()
		button.connect("hovered", self, "_select_difficulty", [difficulty])
		button.set_meta("difficulty", difficulty)
		difficulty_list.add_child(button)
	$PPDAudioBrowseWindow.connect("accept", self, "_on_PPDAudioBrowseWindow_accept")
	$PPDAudioBrowseWindow.connect("cancel", scroll_container, "grab_focus")
	scroll_container.connect("song_selected", self, "_on_song_selected")
	
func _on_song_hovered(song: HBSong):
	emit_signal("song_hovered", song)

func should_receive_input():
	return scroll_container.has_focus()

func _gui_input(event):
	if event.is_action_pressed("gui_cancel"):
		get_tree().set_input_as_handled()
		change_to_menu("main_menu")
func _unhandled_input(event):
	if should_receive_input():
		if event.is_action_pressed("gui_left") or event.is_action_pressed("gui_right"):
			$VBoxContainer/DifficultyList._gui_input(event)

func _on_song_selected(song: HBSong):
	current_song = song
	if song is HBPPDSong and not song.has_audio() and not song.youtube_url:
		$PPDAudioBrowseWindow.popup_centered_ratio(0.5)
		return
	if song.is_cached():
		change_to_menu("pre_game", false, {"song": song, "difficulty": current_difficulty})
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
	scroll_container.grab_focus()
		
func _on_video_downloaded(id, result, song):
	_on_song_hovered(song)
	scroll_container.grab_focus()
#	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song, current_difficulty)



func _select_difficulty(difficulty: String):
	current_difficulty = difficulty
	$VBoxContainer/MarginContainer/ScrollContainer.set_songs(SongLoader.get_songs_with_difficulty(difficulty), difficulty)
