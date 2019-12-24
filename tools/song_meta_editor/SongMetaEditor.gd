extends Control

onready var song_list = get_node("HSplitContainer/VBoxContainer/SongList")
onready var song_meta_editor = get_node("HSplitContainer/SongMetaEditor")
onready var create_song_popup = get_node("CreateSongDialog")
const LOG_NAME = "SongMetaEditor"

func _ready():
	update_user_song_list()
	song_meta_editor.hide()

func update_user_song_list():
	var dir := Directory.new()
	for song_id in SongLoader.songs:
		var song := SongLoader.songs[song_id] as HBSong
		if song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.USER:
			song_list.add_song(song)

func _on_CreateSongDialog_confirmed():
	if $CreateSongDialog/LineEdit.text != "":
		var song_name = HBUtils.get_valid_filename($CreateSongDialog/LineEdit.text)
		if song_name != "":
			var dir := Directory.new()
			
			var song_meta = HBSong.new()
			song_meta.title = $CreateSongDialog/LineEdit.text
			song_meta.id = song_name
			song_meta.path = "user://songs/%s" % song_name
			song_meta.save_song()
			song_list.add_song(song_meta)


func _on_AddButton_pressed():
	create_song_popup.popup_centered_ratio(0.25)



func _on_SongList_song_selected(song: HBSong):
	song_meta_editor.show()
	song_meta_editor.song_meta = song
	song_list.get_selected().set_text(0, song.title)


func _on_BackButton_pressed():
	get_tree().change_scene_to(load("res://menus/MainMenu3D.tscn"))


func _on_FolderButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://"))
