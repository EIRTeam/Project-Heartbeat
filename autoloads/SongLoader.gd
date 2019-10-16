extends Node

signal all_songs_loaded

const LOG_NAME = "SongLoader"


var songs := {}

const SONGS_PATH = "res://songs"

const SONG_SEARCH_PATHS = ["res://songs", "user://songs"]

func _ready():
	var dir = Directory.new()
	for path in SONG_SEARCH_PATHS:
		print(dir.make_dir_recursive(path))
	load_all_songs_meta()
	
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
	
func load_songs_from_path(path):
	var dir := Directory.new()
	var value = {}
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while (file_name != ""):
			if dir.current_is_dir() and not file_name.begins_with("."):
				var song_json_path = path + "/%s/song.json" % file_name
				
				var song_meta : HBSong = load_song_meta(song_json_path, file_name)
				if song_meta:
					value[file_name] = song_meta
			file_name = dir.get_next()
	else:
		Log.log(self, "An error occurred when trying to load songs from %s" % [path], Log.LogLevel.ERROR)
	return value
func load_all_songs_meta():
	for path in SONG_SEARCH_PATHS:
		songs = HBUtils.merge_dict(songs, load_songs_from_path(path))
	emit_signal("all_songs_loaded")
