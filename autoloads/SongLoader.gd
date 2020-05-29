extends Node

signal all_songs_loaded

const LOG_NAME = "SongLoader"

var songs := {}
var initial_load_done = false
const SONGS_PATH = "res://songs"

const SONG_SEARCH_PATHS = ["res://songs", "user://songs"]

const SONG_SCORES_PATH = "user://scores.json"
const PPD_YOUTUBE_URL_LIST_PATH = "user://ppd_youtube.json"
var ppd_youtube_url_list = {}
const BASE_DIFFICULTY_ORDER = ["easy", "normal", "hard", "extreme"]
var scores = {}

func _ready():
	var dir := Directory.new()
	dir.open("user://")
	if not dir.file_exists("user://songs"):
		var err = dir.make_dir_recursive("user://songs")
		if err != OK:
			Log.log(self, "Error creating songs directory", err)
	if dir.file_exists(PPD_YOUTUBE_URL_LIST_PATH):
		load_ppd_youtube_url_list()
	load_all_songs_async()
	
func load_song_meta(path: String, id: String) -> HBSong:
	var file = File.new()
	var err = file.open(path, File.READ)
	if err == OK:
		var song_json = JSON.parse(file.get_as_text())
		if song_json.error == OK:
			
			var song_instance = HBSerializable.deserialize(song_json.result) as HBSong
			song_instance.id = id
			song_instance.path = path.get_base_dir()
			Log.log(self, "Loaded song %s succesfully" % song_instance.get_visible_title())
			return song_instance
		else:
			Log.log(self, "Error loading song config file on line %d: %s" % [song_json.error_line, song_json.error_string])
	else:
		Log.log(self, "Error loading song: %s with error %d" % [path, err], Log.LogLevel.ERROR)
	file.close()
	return null
	
func load_ppd_song_meta(path: String, id: String) -> HBSong:
	var file = File.new()
	if file.open(path, File.READ) == OK:
		var txt = file.get_as_text()
		var song = HBPPDSong.from_ini(txt, id)
		song.id = id
		song.path = path.get_base_dir()
		if id in ppd_youtube_url_list:
			song.youtube_url = ppd_youtube_url_list[id]
		# Audio file discovery
		var dir := Directory.new()
		if dir.open(song.path) == OK:
			dir.list_dir_begin()
			var dir_name = dir.get_next()
			while dir_name != "":
				if not dir.current_is_dir():
					if dir_name.ends_with(".ogg"):
						song.audio = dir_name
						break
				dir_name = dir.get_next()
		
		return song
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
				var song_json_path = path + "/%s/song.json" % dir_name
				var song_ppd_ini_path = path + "/%s/data.ini" % dir_name
				var file = File.new()
				var song_meta : HBSong
				var song_found = false
				if file.file_exists(song_json_path):
					song_meta = load_song_meta(song_json_path, dir_name)
					if song_meta:
						value[dir_name] = song_meta
					song_found = true
				elif file.file_exists(song_ppd_ini_path):
					song_meta = load_ppd_song_meta(song_ppd_ini_path, dir_name)
					if song_meta:
						value[dir_name] = song_meta
					song_found = true
				if not song_found:
					Log.log(self, "Invalid song found in directory " + dir_name, Log.LogLevel.ERROR)
						
			dir_name = dir.get_next()
	else:
		Log.log(self, "An error occurred when trying to load songs from %s" % [path], Log.LogLevel.ERROR)
	return value
func load_all_songs_meta():
	for path in SONG_SEARCH_PATHS:
		var loaded_songs = load_songs_from_path(path)
		for song_id in loaded_songs:
			add_song(loaded_songs[song_id])
	emit_signal("all_songs_loaded")

func load_all_songs_async():
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
	print("LOADED SHIT")
	emit_signal("all_songs_loaded")

func get_songs_with_difficulty(difficulty: String):
	var result = []
	for song_id in songs:
		var song = songs[song_id]
		if song.charts.has(difficulty):
			result.append(song)
	return result
	
func load_ppd_youtube_url_list():
	var file = File.new()
	if file.open(PPD_YOUTUBE_URL_LIST_PATH, File.READ) == OK:
		var result = JSON.parse(file.get_as_text()) as JSONParseResult
		if result.error == OK:
			ppd_youtube_url_list = result.result
		else:
			Log.log(self, "Error loading PPD URL list " + str(result.error))

func save_ppd_youtube_url_list():
	var file = File.new()
	if file.open(PPD_YOUTUBE_URL_LIST_PATH, File.WRITE) == OK:
		file.store_string(JSON.print(ppd_youtube_url_list))

func set_ppd_youtube_url(song: HBSong, url: String):
	ppd_youtube_url_list[song.id] = url
	song.youtube_url = url
	save_ppd_youtube_url_list()
