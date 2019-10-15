extends Node

signal all_songs_loaded

const LOG_NAME = "SongLoader"


var songs := {}

const SONGS_PATH = "res://songs"

func _ready():
	pass
#	load_all_songs_meta()
	
func load_song_meta(path: String, id: String) -> HBSong:
	var file = File.new()
	if file.open(path, File.READ) == OK:
		var song_json = JSON.parse(file.get_as_text())
		if song_json.error == OK:
			Log.log(self, "Loaded song %s succesfully" % song_json.result.title)
			
			var song_instance = HBSerializable.deserialize(song_json.result)
			song_instance.id = id
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
		print("An error occurred when trying to access the path.")
	return value
func load_all_songs_meta():
	songs = load_songs_from_path(SongLoader.SONGS_PATH)
	emit_signal("all_songs_loaded")
