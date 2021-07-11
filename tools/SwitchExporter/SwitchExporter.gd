extends Control

onready var tree = get_node("WindowDialog/MarginContainer/VBoxContainer/Tree")
onready var export_button = get_node("WindowDialog/MarginContainer/VBoxContainer/ExportButton")
onready var window_dialog = get_node("WindowDialog")
onready var close_button = get_node("WindowDialog/MarginContainer/VBoxContainer/CloseButton")
var selected_items = []

func populate_tree():
	tree.clear()
	tree.set_column_expand(1, true)
	tree.set_column_expand(0, false)
	tree.set_column_min_width(0, 45)
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
			elif not song is HBPPDSong and not song is SongLoaderDSC.HBSongDSC:
				song_item = tree.create_item(editor_item)
			
			if song_item:
				song_item.set_meta("song", song)
				song_item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
				song_item.set_text(1, song.get_visible_title())
				song_item.set_selectable(0, false)
				song_item.set_editable(0, true)
	export_button.disabled = true
func _ready():
	connect("resized", self, "_on_resized")
	tree.connect("item_edited", self, "_on_item_edited")
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	populate_tree()
	window_dialog.popup_centered()
	window_dialog.get_close_button().connect("pressed", self, "_return_to_main_menu")
	close_button.connect("pressed", self, "_return_to_main_menu")

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
	get_tree().change_scene_to(load("res://menus/MainMenu3D.tscn"))

func _on_FileDialog_dir_selected(dir_path: String):
	var dir = Directory.new()
	for item in selected_items:
		var song = item.get_meta("song") as HBSong
		var song_dir = dir_path.plus_file(song.id)
		if not dir.dir_exists(song_dir):
			dir.make_dir_recursive(song_dir)
		
		if dir.open(song.path) == OK:
			dir.list_dir_begin()
			var dir_name = dir.get_next()
			while dir_name != "":
				if not dir.current_is_dir():
					var lower_dir_name = dir_name.to_lower()
					if lower_dir_name.ends_with(".json") or \
							lower_dir_name.ends_with(".ogg") or \
							lower_dir_name.ends_with(".jpg") or lower_dir_name.ends_with(".png"):
						dir.copy(song.path.plus_file(dir_name), song_dir.plus_file(dir_name))
				dir_name = dir.get_next()
		if song.youtube_url:
			var song_meta = song.serialize()
			song_meta["use_youtube_for_audio"] = false
			song_meta["use_youtube_for_video"] = false
			song_meta["youtube_url"] = ""
			song_meta["audio"] = "audio.ogg"
			var f = File.new()
			f.open(song_dir.plus_file("song.json"), File.WRITE)
			f.store_string(to_json(song_meta))
			dir.copy(YoutubeDL.get_audio_path(YoutubeDL.get_video_id(song.youtube_url)), song_dir.plus_file("audio.ogg"))


func _on_Label_meta_clicked(meta):
	OS.shell_open(meta)
