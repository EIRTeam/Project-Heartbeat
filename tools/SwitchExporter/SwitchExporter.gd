extends Control

@onready var tree = get_node("Window/MarginContainer/VBoxContainer/Tree")
@onready var export_button = get_node("Window/MarginContainer/VBoxContainer/ExportButton")
@onready var window_dialog = get_node("Window")
@onready var close_button = get_node("Window/MarginContainer/VBoxContainer/CloseButton")
var selected_items = []

func populate_tree():
	tree.clear()
	tree.set_column_expand(1, true)
	tree.set_column_expand(0, false)
	tree.set_column_custom_minimum_width(0, 45)
	var root = tree.create_item()
	var workshop_item = tree.create_item(root)
	workshop_item.set_text(0, "Workshop songs")
	workshop_item.set_expand_right(0, true)
	var local_item = tree.create_item(root)
	local_item.set_text(0, "Local songs")
	local_item.set_expand_right(0, true)
	var editor_item = tree.create_item(root)
	editor_item.set_text(0, "Editor songs")
	editor_item.set_expand_right(0, true)
	
	var editor_songs_path = HBUtils.join_path(UserSettings.get_content_directories(true)[0], "editor_songs")
	
	for song_id in SongLoader.songs:
		var song_item: TreeItem
		var song: HBSong = SongLoader.songs[song_id]
		
		if song.is_cached():
			if song.comes_from_ugc():
				song_item = tree.create_item(workshop_item)
			elif song.path.begins_with(editor_songs_path):
				song_item = tree.create_item(editor_item)
			elif not song is HBPPDSong and not song is SongLoaderDSC.HBSongDSC and \
					not song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN:
				song_item = tree.create_item(editor_item)
			
			if song_item:
				song_item.set_meta("song", song)
				song_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
				song_item.set_text(1, song.get_visible_title())
				song_item.set_selectable(0, false)
				song_item.set_editable(0, true)
	export_button.disabled = true
func _ready():
	connect("resized", Callable(self, "_on_resized"))
	tree.connect("item_edited", Callable(self, "_on_item_edited"))
	populate_tree()
	window_dialog.popup_centered()
	window_dialog.close_requested.connect(self._return_to_main_menu)
	close_button.connect("pressed", Callable(self, "_return_to_main_menu"))
	
	$FileDialog.set_current_dir(UserSettings.user_settings.last_switch_export_dir)

func _on_item_edited():
	var item: TreeItem = tree.get_edited()
	if item.is_checked(0):
		selected_items.append(item)
	else:
		selected_items.erase(item)
	export_button.disabled = selected_items.size() == 0

func _on_resized():
	window_dialog.popup_centered()

func _return_to_main_menu():
	get_tree().change_scene_to_packed(load("res://menus/MainMenu3D.tscn"))

func _on_FileDialog_dir_selected(dir_path: String):
	for item in selected_items:
		var song = item.get_meta("song") as HBSong
		var song_dir = dir_path.path_join(song.id)
		if not DirAccess.dir_exists_absolute(song_dir):
			DirAccess.make_dir_recursive_absolute(song_dir)
		var dir := DirAccess.open(song.path)
		if DirAccess.get_open_error() == OK:
			dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
			var dir_name = dir.get_next()
			while dir_name != "":
				if not dir.current_is_dir():
					var lower_dir_name = dir_name.to_lower()
					if lower_dir_name.ends_with(".json") or \
							lower_dir_name.ends_with(".ogg") or \
							lower_dir_name.ends_with(".jpg") or lower_dir_name.ends_with(".png"):
						dir.copy(song.path.path_join(dir_name), song_dir.path_join(dir_name))
				dir_name = dir.get_next()
		if song.youtube_url:
			var song_meta = song.serialize()
			song_meta["use_youtube_for_audio"] = false
			song_meta["use_youtube_for_video"] = false
			song_meta["youtube_url"] = ""
			song_meta["audio"] = "audio.ogg"
			var f = FileAccess.open(song_dir.path_join("song.json"), FileAccess.WRITE)
			f.store_string(JSON.new().stringify(song_meta))
			dir.copy(YoutubeDL.get_audio_path(YoutubeDL.get_video_id(song.youtube_url)), song_dir.path_join("audio.ogg"))
	
	UserSettings.user_settings.last_switch_export_dir = dir_path
	UserSettings.save_user_settings()


func _on_Label_meta_clicked(meta):
	OS.shell_open(meta)
