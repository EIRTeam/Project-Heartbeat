extends Tree

signal package_selected(package_folder_name)
signal song_selected(song, song_id, package_name)
const DEV_PACKAGE_DIR = "user://dev_packages"
func _ready():
	create_item()
	connect("item_selected", self, "_on_item_selected")

func add_song(parent: TreeItem, song: HBSong, song_id: String, package_name: String):
		var song_item := create_item(parent)
		song_item.set_text(0, song.title)
		song_item.set_meta("song", song)
		song_item.set_meta("song_id", song_id)
		song_item.set_meta("song_package", package_name)

func add_package(package_folder_name: String, package_meta: HBPackageMeta):
	var item := create_item()
	item.set_text(0, package_meta.name)
	item.set_meta("package_folder_name", package_folder_name)
	
	var dir = Directory.new()
	var songs_dir = DEV_PACKAGE_DIR + "/%s/songs" % [package_folder_name]
	if dir.dir_exists(songs_dir):
		var songs = SongLoader.load_songs_from_path(songs_dir)
		for song_id in songs:
			var song := songs[song_id] as HBSong
			add_song(item, song, song_id, package_folder_name)
	
func _on_item_selected():
	# Only packages are children of root
	if get_selected().get_parent() == get_root():
		emit_signal("package_selected", get_selected_package_name())
	else:
		var song = get_selected().get_meta("song")
		var song_id = get_selected().get_meta("song_id")
		var song_package = get_selected().get_meta("song_package")
		emit_signal("song_selected", song, song_id, song_package)
		
func is_selected_a_package():
	if not get_selected():
		return false
	return get_selected().get_parent() == get_root()
func get_selected_package_name():
	return get_selected().get_meta("package_folder_name")

func get_selected_song():
	return get_selected().get_meta("song")

func get_selected_song_id():
	return get_selected().get_meta("song_id")

func get_selected_song_package_name():
	return get_selected().get_meta("song_package")
