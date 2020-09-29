# Project Heartbeat-style song song loading code
extends SongLoaderImpl

class_name SongLoaderHB

const LOG_NAME = "SongLoaderHB"

func get_meta_file_name() -> String:
	return "song.json"

func load_song_meta_from_folder(path: String, id: String):
	var file = File.new()
	var err = file.open(path, File.READ)
	if err == OK:
		var song_json = JSON.parse(file.get_as_text())
		if song_json.error == OK:
			
			var song_instance = HBSerializable.deserialize(song_json.result) as HBSong
			song_instance.id = id
			song_instance.path = path.get_base_dir()
			return song_instance
		else:
			Log.log(self, "Error loading song config file on line %d: %s" % [song_json.error_line, song_json.error_string])
	else:
		Log.log(self, "Error loading song: %s with error %d" % [path, err], Log.LogLevel.ERROR)
	file.close()
	return null
	
func caching_enabled():
	return true
