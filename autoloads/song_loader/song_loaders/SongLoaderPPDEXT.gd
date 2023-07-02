# Song loader for PPD songs with h264 video
extends SongLoaderImpl

class_name SongLoaderPPDEXT

const OPT_META_FILE_NAME = "ph_ext.json"

func _init_loader() -> int:
	if not HBGame.has_mp4_support or not UserSettings.user_settings.ppd_songs_directory or \
			not DirAccess.dir_exists_absolute(UserSettings.user_settings.ppd_songs_directory):
		return -1
	return OK

func get_serialized_type():
	return "PPDSongEXT"

static func load_ppd_meta(path: String, id: String):
		
		var opt_meta_file_path = HBUtils.join_path(path.get_base_dir(), OPT_META_FILE_NAME)
		
		var opt_data = SongLoaderPPD.load_opt_file(opt_meta_file_path)
		
		var file = FileAccess.open(path, FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			var txt = file.get_as_text()
			var song = HBPPDSongEXT.from_ini(txt, id, null, "res://autoloads/song_loader/song_loaders/HBPPDSongEXT.gd")
			var dict = HBUtils.merge_dict(song.serialize(), opt_data)
			song = HBPPDSongEXT.deserialize(dict)
			song.id = id
			song.path = path.get_base_dir()
			# Audio file discovery
			var found_mp4 = false
			var found_wav = false
			var dir := DirAccess.open(song.path)
			if DirAccess.get_open_error() == OK:
				dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
				var dir_name = dir.get_next()
				while dir_name != "":
					if not dir.current_is_dir():
						if dir_name.ends_with(".mp4") or dir_name.ends_with(".flv") or dir_name.ends_with(".avi") or dir_name.ends_with(".webm"):
							song.video = dir_name
							song.audio = dir_name.get_basename() + ".ogg"
							found_mp4 = true
							break
						if dir_name.ends_with(".wav"):
							song.audio = dir_name
							found_wav = true
					dir_name = dir.get_next()
			if found_mp4 or found_wav:
				return song
		return null

func _discover_songs_recursive(path: String, base_path = "") -> Array:
	var songs = []
	var dir = DirAccess.open(path)
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var dir_name = dir.get_next()
		while dir_name != "":
			var i_path = path.path_join(dir_name)
			if dir.current_is_dir():
				var data_ini_path = i_path.path_join("data.ini")
				print(data_ini_path)
				print("File exists", data_ini_path, dir.file_exists(data_ini_path))
				if dir.file_exists(data_ini_path):
					var meta = load_ppd_meta(data_ini_path, "PPDEXT+" + base_path.path_join(dir_name))
					if meta:
						meta.title = dir_name
						songs.append(meta)
					else:
						print("Error loading PPD EXT song %s" % [dir_name])
				else:
					songs.append_array(_discover_songs_recursive(i_path, base_path.path_join(dir_name)))
			dir_name = dir.get_next()
	return songs

func load_songs():
	return _discover_songs_recursive(UserSettings.user_settings.ppd_songs_directory)

# If true this loader manages discovery by itself
func uses_custom_load_paths():
	return true
	
func caching_enabled():
	return false
