extends Node

signal all_songs_loaded

const LOG_NAME = "SongLoader"

var songs := {}
var initial_load_done = false
const SONGS_PATH = "res://songs"

const SONG_SCORES_PATH = "user://scores.json"

const BASE_DIFFICULTY_ORDER = ["easy", "normal", "hard", "extreme"]
var scores = {}

# Contains song loaders in a dict key:loader
var song_loaders = {}

func _ready():
	var dir := Directory.new()
	for dir_name in UserSettings.get_content_directories():
		var o_err = dir.open(dir_name)
		if o_err == OK:
			var songs_path = HBUtils.join_path(dir_name, "songs")
			if not dir.file_exists(songs_path):
				var err = dir.make_dir_recursive(songs_path)
				if err != OK:
					Log.log(self, "Error creating songs directory with error %s at %s" % [str(err), songs_path])
		else:
			Log.log(self, "Error opening folder to create songs folder with error %s at %s" %  [str(o_err), dir_name])

#	load_all_songs_async()
	
func load_song_meta(path: String, id: String) -> HBSong:
	var file = File.new()
	var err = file.open(path, File.READ)
	if err == OK:
		var song_json = JSON.parse(file.get_as_text())
		if song_json.error == OK:
			
			var song_instance = HBSerializable.deserialize(song_json.result) as HBSong
			song_instance.id = id
			song_instance.path = path.get_base_dir()
			Log.log(self, "Loaded song %s succesfully from %s" % [song_instance.get_visible_title(), path.get_base_dir()])
			return song_instance
		else:
			Log.log(self, "Error loading song config file on line %d: %s" % [song_json.error_line, song_json.error_string])
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
	keys.sort_custom(self, "difficulty_sort")
	
	var charts = {}
	
	for key in keys:
		charts[key] = song.charts[key]
	
	song.charts = charts
func load_songs_from_path(path):
	var dir := Directory.new()
	var value = {}
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var dir_name = dir.get_next()

		while dir_name != "":
			if dir.current_is_dir() and not dir_name.begins_with("."):
				var file = File.new()
				var song_meta : HBSong
				var song_found = false
				for loader in song_loaders.values():
					var song_meta_path = path + "/%s/%s" % [dir_name, loader.get_meta_file_name()]
					if file.file_exists(song_meta_path):
						if SongDataCache.is_song_meta_cached(dir_name, song_meta_path):
							song_meta = SongDataCache.get_cached_meta(dir_name)
							song_meta.id = dir_name
							song_meta.path = song_meta_path.get_base_dir()
						else:
							song_meta = loader.load_song_meta_from_folder(song_meta_path, dir_name)
							SongDataCache.update_cache_for_song(song_meta)
						if song_meta:
							value[dir_name] = song_meta
						song_found = true
				if not song_found:
					Log.log(self, "No loader foudn for song in directory " + dir_name, Log.LogLevel.ERROR)
						
			dir_name = dir.get_next()
		Log.log(self, "Loaded %d songs from %s" % [value.size(), path])
	else:
		Log.log(self, "An error occurred when trying to load songs from %s" % [path], Log.LogLevel.ERROR)
	return value
func load_all_songs_meta():
	
	if PlatformService.service_provider.implements_ugc:
		PlatformService.service_provider.ugc_provider.reload_ugc_songs()
	
	var song_paths = [] as Array
	
	var dir := Directory.new()
	if not HBGame.demo_mode:
		for content_dir in UserSettings.get_content_directories():
			var songs_dir = HBUtils.join_path(content_dir, "songs")
			song_paths.append(songs_dir)
	else:
		song_paths = ["res://songs"]
	
	for path in song_paths:
		print("LOADING SONGS FROM ", path)
		var loaded_songs = load_songs_from_path(path)
		for song_id in loaded_songs:
			add_song(loaded_songs[song_id])

func load_all_songs_async():
	songs = {}
#	load_all_songs_meta()
	initial_load_done = true
	
	var thread = Thread.new()
	var result = thread.start(self, "_load_all_songs_async", {"thread": thread})
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
	loader._init_loader()

func get_song_loader(loader_name: String) -> SongLoaderImpl:
	if song_loaders.has(loader_name):
		return song_loaders[loader_name]
	else:
		Log.log(self, "Error finding song loader: %s" % [loader_name])
		return null
