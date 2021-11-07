extends WindowDialog

onready var tree = get_node("MarginContainer/HBoxContainer/Tree")

onready var change_URL_button = get_node("MarginContainer/HBoxContainer/VBoxContainer/ChangeURLButton")
onready var change_cover_button = get_node("MarginContainer/HBoxContainer/VBoxContainer/ChangeCoverButton")
onready var change_background_button = get_node("MarginContainer/HBoxContainer/VBoxContainer/ChangeBackgroundButton")

onready var change_background_dialog = get_node("ChangeBackgroundFileDialog")
onready var change_cover_dialog = get_node("ChangeCoverFileDialog")

signal error(message)

func _ready():
	tree.hide_root = true
	connect("about_to_show", self, "populate_tree")
	tree.connect("item_selected", self, "_on_item_selected")
	
	change_background_dialog.connect("file_selected", self, "_on_background_selected")
	change_cover_dialog.connect("file_selected", self, "_on_cover_selected")
	MouseTrap.ppd_dialog.connect("youtube_url_selected", self, "_on_youtube_url_selected")
	
	change_URL_button.connect("pressed", MouseTrap.ppd_dialog, "ask_for_file", [true])
	
func show_error(error: String):
	emit_signal("error", error)
	
func _on_youtube_url_selected(url):
	var loader = SongLoader.get_song_loader("ppd") as SongLoaderPPD
	if loader:
		var song = SongLoader.songs[tree.get_selected().get_meta("song_id")]
		loader.set_ppd_youtube_url(song, url)
		show_error("Succesfully set YouTube URL")
func populate_tree():
	tree.clear()
	var root = tree.create_item()
	
	change_URL_button.disabled = true
	change_cover_button.disabled = true
	change_background_button.disabled = true
	
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		if song is HBPPDSong:
			var item = tree.create_item(root)
			item.set_text(0, song.title)
			item.set_meta("song_id", song_id)
func _on_item_selected():
	var item = tree.get_selected()
	var song = SongLoader.songs[item.get_meta("song_id")] as HBPPDSong
	
	change_URL_button.disabled = false
	change_cover_button.disabled = false
	change_background_button.disabled = false
	
func get_current_meta_path():
	var meta_path = SongLoader.songs[tree.get_selected().get_meta("song_id")].path
	meta_path = HBUtils.join_path(meta_path, "ph_ext.json")
	return meta_path
	
func get_current_song_meta() -> HBPPDSong:
	var meta_path = get_current_meta_path()
	var curr_song_path = SongLoader.songs[tree.get_selected().get_meta("song_id")].path
	var file = File.new()
	var meta = HBPPDSong.new()
	if file.file_exists(meta_path):
		if file.open(meta_path, File.READ) == OK:
			var parse_result = JSON.parse(file.get_as_text())
			if parse_result.error == OK:
				meta = HBPPDSong.deserialize(parse_result.result)
	meta.path = curr_song_path
	return meta
	
func _on_background_selected(path: String):
	var dir = Directory.new()
	var extension = path.get_extension()
	var song_meta = get_current_song_meta()
	
	song_meta.background_image = "background." + extension
	
	var image_path := song_meta.get_song_background_image_res_path() as String
	
	dir.copy(path, image_path)
	song_meta.save_to_file(get_current_meta_path())
	
	SongLoader.songs[tree.get_selected().get_meta("song_id")].background_image = song_meta.background_image
	show_error("Succesfully changed background image")

func _on_cover_selected(path: String):
	var dir = Directory.new()
	var extension = path.get_extension()
	var song_meta = get_current_song_meta()
	
	song_meta.preview_image = "preview." + extension
	
	var image_path := song_meta.get_song_preview_res_path() as String
	
	dir.copy(path, image_path)
	song_meta.save_to_file(get_current_meta_path())
	
	SongLoader.songs[tree.get_selected().get_meta("song_id")].preview_image = song_meta.preview_image

	show_error("Succesfully changed cover image")
