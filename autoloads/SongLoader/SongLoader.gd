extends Node

signal all_songs_loaded

const LOG_NAME = "SongLoader"


var songs := {}
const SONGS_PATH = "res://songs"

func _ready():
	load_all_songs_meta()
	
func load_song_meta(song: String):
	var song_json_path = SongLoader.SONGS_PATH + "/%s/song.json" % song
	var file = File.new()

	if file.open(song_json_path, File.READ) == OK:
		var song_json = JSON.parse(file.get_as_text())
		if song_json.error == OK:
			Log.log(self, "Loaded song %s succesfully" % song_json.result.title)
			
			songs[song] = HBSerializable.deserialize(song_json.result)
			songs[song].id = song
		else:
			Log.log(self, "Error loading song config file on line %d: %s" % [song_json.error_line, song_json.error_string])
	else:
		Log.log(self, "Error loading song: %s" % song_json_path, Log.LogLevel.ERROR)
	file.close()
	
func get_song_data_folder(song_id):
	return SONGS_PATH + "/%s" % song_id
	
func get_song_audio_file(song_id):
	return get_song_data_folder(song_id) + "/" + songs[song_id].audio
	
func load_all_songs_meta():
	var dir := Directory.new()

	if dir.open(SONGS_PATH) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while (file_name != ""):
			if dir.current_is_dir() and not file_name.begins_with("."):
				load_song_meta(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	emit_signal("all_songs_loaded")
