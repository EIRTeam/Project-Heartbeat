extends Node

signal all_songs_loaded

const LOG_NAME = "SongLoader"

var songs := {}
var initial_load_done = false
const SONGS_PATH = "res://songs"

const BASE_DIFFICULTY_ORDER = ["easy", "normal", "hard", "extreme", "extra extreme"]
var scores = {}

# Contains song loaders in a dict key:loader
var song_loaders = {}

func init_song_loader():
	for dir_name in UserSettings.get_content_directories():
		var dir := DirAccess.open(dir_name)
		var o_err = DirAccess.get_open_error()
		if o_err == OK:
			var song_paths = [HBUtils.join_path(dir_name, "songs"), HBUtils.join_path(dir_name, "editor_songs")]
			for songs_path in song_paths:
				if not dir.file_exists(songs_path):
					var err = dir.make_dir_recursive(songs_path)
					if err != OK:
						Log.log(self, "Error creating songs directory with error %s at %s" % [str(err), songs_path])
		else:
			Log.log(self, "Error opening folder to create songs folder with error %s at %s" %  [str(o_err), dir_name])

#	load_all_songs_async()
	
func load_song_meta(path: String, id: String) -> HBSong:
	var file = FileAccess.open(path, FileAccess.READ)
	var err = FileAccess.get_open_error()
	if err == OK:
		var test_json_conv = JSON.new()
		var json_error = test_json_conv.parse(file.get_as_text())
		var song_json = test_json_conv.get_data()
		if json_error == OK:
			
			var song_instance = HBSerializable.deserialize(song_json) as HBSong
			song_instance.id = id
			song_instance.path = path.get_base_dir()
			Log.log(self, "Loaded song %s succesfully from %s" % [song_instance.get_visible_title(), path.get_base_dir()])
			return song_instance
		else:
			Log.log(self, "Error loading song config file on line %d: %s" % [test_json_conv.get_error_line(), test_json_conv.get_error_message()])
	else:
		Log.log(self, "Error loading song: %s with error %d" % [path, err], Log.LogLevel.ERROR)
	file.close()
	return null
	
func difficulty_sort(a: String, b: String):
	var a_i = BASE_DIFFICULTY_ORDER.find(a.to_lower())
	var b_i = BASE_DIFFICULTY_ORDER.find(b.to_lower())
	return a_i > b_i
func add_song(song: HBSong):
	songs[song.id] = song
	var keys = song.charts.keys()
	keys.sort_custom(Callable(self, "difficulty_sort"))
	
	var charts = {}
	
	for key in keys:
		charts[key] = song.charts[key]
	
	song.charts = charts
func load_songs_from_path(path):
	var value = {}
	var dir := DirAccess.open(path)
	var err := DirAccess.get_open_error()
	if err == OK:
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var dir_name = dir.get_next()

		while dir_name != "":
			if dir.current_is_dir() and not dir_name.begins_with("."):
				var song_meta : HBSong
				var song_found = false
				for loader in song_loaders.values():
					if not loader.uses_custom_load_paths():
						var song_meta_path = path + "/%s/%s" % [dir_name, loader.get_meta_file_name()]
						if FileAccess.file_exists(song_meta_path):
							song_meta = loader.load_song_meta_from_folder(song_meta_path, dir_name)
							if song_meta:
								value[dir_name] = song_meta
							song_found = true
				if not song_found:
					Log.log(self, "No loader found for song in directory " + dir_name, Log.LogLevel.ERROR)
						
			dir_name = dir.get_next()
		Log.log(self, "Loaded %d songs from %s" % [value.size(), path])
	else:
		Log.log(self, "An error occurred when trying to load songs from %s" % [path], Log.LogLevel.ERROR)
	return value
func load_all_songs_meta():
	
	if PlatformService.service_provider.implements_ugc:
		PlatformService.service_provider.ugc_provider.reload_ugc_songs()
	
	var song_paths = [] as Array
	
	if not HBGame.demo_mode:
		for content_dir in UserSettings.get_content_directories():
			var songs_dir = HBUtils.join_path(content_dir, "songs")
			var editor_songs_dir = HBUtils.join_path(content_dir, "editor_songs")
			song_paths.append(songs_dir)
			song_paths.append(editor_songs_dir)
	else:
		song_paths = ["res://songs"]
	
	for path in song_paths:
		var loaded_songs = load_songs_from_path(path)
		for song_id in loaded_songs:
			add_song(loaded_songs[song_id])
	for loader in song_loaders.values():
		if loader.uses_custom_load_paths():
			var s = loader.load_songs()
			for song in s:
				add_song(song)
	initial_load_done = true
	emit_signal("all_songs_loaded")
func load_all_songs_async():
	songs = {}
#	load_all_songs_meta()
	initial_load_done = true
	
	var thread = Thread.new()
	var result = thread.start(Callable(self, "_load_all_songs_async").bind({"thread": thread}))
	if result != OK:
		Log.log(self, "Error starting thread for song loader: " + str(result), Log.LogLevel.ERROR)

func _load_all_songs_async(userdata):
	load_all_songs_meta()
	call_deferred("_songs_loaded", userdata.thread)

func _songs_loaded(thread: Thread):
	thread.wait_to_finish() # Windows breaks if you don't do this
	initial_load_done = true
	emit_signal("all_songs_loaded")

func get_songs_with_difficulty(difficulty: String):
	var result = []
	for song_id in songs:
		var song = songs[song_id]
		if song.charts.has(difficulty):
			result.append(song)
	return result

func add_song_loader(id: String, loader: SongLoaderImpl):
	song_loaders[id] = loader
	var err = loader._init_loader()
	if err != OK:
		song_loaders.erase(id)

func get_song_loader(loader_name: String) -> SongLoaderImpl:
	if song_loaders.has(loader_name):
		return song_loaders[loader_name]
	else:
		Log.log(self, "Error finding song loader: %s" % [loader_name])
		return null
