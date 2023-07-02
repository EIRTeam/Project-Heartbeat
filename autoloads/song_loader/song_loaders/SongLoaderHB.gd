# Project Heartbeat-style song song loading code
extends SongLoaderImpl

class_name SongLoaderHB

const LOG_NAME = "SongLoaderHB"

func get_meta_file_name() -> String:
	return "song.json"

func load_song_meta_from_folder(path: String, id: String):
	var file = FileAccess.open(path, FileAccess.READ)
	var err = FileAccess.get_open_error()
	if err == OK:
		var test_json_conv = JSON.new()
		var json_err := test_json_conv.parse(file.get_as_text())
		var song_json = test_json_conv.get_data()
		if json_err == OK:
			
			var song_instance = HBSerializable.deserialize(song_json) as HBSong
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
	if not HBGame.platform_settings is HBPlatformSettingsDesktop:
		return false
	else:
		return true
