extends Node

signal all_songs_loaded

const LOG_NAME = "SongLoader"

var songs := {}

const SONGS_PATH = "res://songs"

const SONG_SEARCH_PATHS = ["res://songs", "user://songs"]

const SONG_SCORES_PATH = "user://scores.json"
const SCORES_KEY = "ScoresV1"
var scores = {}

var available_difficulties = []

func _ready():
	var dir := Directory.new()
	
	if not dir.file_exists("user://songs"):
		dir.make_dir_recursive("user://songs")
	
	load_all_songs_meta()
	
func load_scores():
	var dir := Directory.new()
	if dir.file_exists(SONG_SCORES_PATH):
		pass
	
func save_scores():
	var file = File.new()
	#file.get_buffer()
	file.open_encrypted_with_pass(SONG_SCORES_PATH, File.COMPRESSION_ZSTD, SCORES_KEY)
	
func load_song_meta(path: String, id: String) -> HBSong:
	var file = File.new()
	if file.open(path, File.READ) == OK:
		var song_json = JSON.parse(file.get_as_text())
		if song_json.error == OK:
			Log.log(self, "Loaded song %s succesfully" % song_json.result.title)
			
			var song_instance = HBSerializable.deserialize(song_json.result)
			song_instance.id = id
			song_instance.path = path.get_base_dir()
			return song_instance
		else:
			Log.log(self, "Error loading song config file on line %d: %s" % [song_json.error_line, song_json.error_string])
	else:
		Log.log(self, "Error loading song: %s" % path, Log.LogLevel.ERROR)
	file.close()
	return null
	
func load_ppd_song_meta(path: String, id: String) -> HBSong:
	var file = File.new()
	if file.open(path, File.READ) == OK:
		var txt = file.get_as_text()
		var song = HBPPDSong.from_ini(txt, id)
		song.id = id
		song.path = path.get_base_dir()
		
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
				if file.file_exists(song_json_path):
					song_meta = load_song_meta(song_json_path, dir_name)
					if song_meta:
						value[dir_name] = song_meta
				elif file.file_exists(song_ppd_ini_path):
					song_meta = load_ppd_song_meta(song_ppd_ini_path, dir_name)
					if song_meta:
						value[dir_name] = song_meta
						
				for difficulty in song_meta.charts:
					if not difficulty in available_difficulties:
						available_difficulties.append(difficulty)
			dir_name = dir.get_next()
	else:
		Log.log(self, "An error occurred when trying to load songs from %s" % [path], Log.LogLevel.ERROR)
	return value
func load_all_songs_meta():
	for path in SONG_SEARCH_PATHS:
		songs = HBUtils.merge_dict(songs, load_songs_from_path(path))
	emit_signal("all_songs_loaded")

func get_songs_with_difficulty(difficulty: String):
	var result = []
	for song_id in songs:
		var song = songs[song_id]
		if song.charts.has(difficulty):
			result.append(song)
	return result
