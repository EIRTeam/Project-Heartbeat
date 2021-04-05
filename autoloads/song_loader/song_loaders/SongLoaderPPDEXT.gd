# Song loader for PPD songs with h264 video
extends SongLoaderImpl

class_name SongLoaderPPDEXT

const OPT_META_FILE_NAME = "ph_ext.json"

func _init_loader() -> int:
	var dir := Directory.new()
	if not HBGame.has_mp4_support or not UserSettings.user_settings.ppd_songs_directory or \
			not dir.dir_exists(UserSettings.user_settings.ppd_songs_directory):
		return -1
	return OK

func get_serialized_type():
	return "PPDSongEXT"

static func load_ppd_meta(path: String, id: String):
		var file = File.new()
		
		var opt_meta_file_path = HBUtils.join_path(path.get_base_dir(), OPT_META_FILE_NAME)
		
		var opt_data = SongLoaderPPD.load_opt_file(opt_meta_file_path)
		
		if file.open(path, File.READ) == OK:
			var txt = file.get_as_text()
			var song = HBPPDSongEXT.from_ini(txt, id, null, "res://autoloads/song_loader/song_loaders/HBPPDSongEXT.gd")
			var dict = HBUtils.merge_dict(song.serialize(), opt_data)
			song = HBPPDSongEXT.deserialize(dict)
			song.id = id
			song.path = path.get_base_dir()
			# Audio file discovery
			var dir := Directory.new()
			var found_mp4 = false
			if dir.open(song.path) == OK:
				dir.list_dir_begin()
				var dir_name = dir.get_next()
				while dir_name != "":
					if not dir.current_is_dir():
						if dir_name.ends_with(".mp4"):
							song.video = dir_name
							song.audio = dir_name.get_basename() + ".ogg"
							found_mp4 = true
							break
					dir_name = dir.get_next()
			if found_mp4:
				return song
		return null

func _discover_songs_recursive(path: String, base_path = "") -> Array:
	var songs = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true)
		var dir_name = dir.get_next()
		while dir_name != "":
			var i_path = path.plus_file(dir_name)
			if dir.current_is_dir():
				var data_ini_path = i_path.plus_file("data.ini")
				if dir.file_exists(data_ini_path):
					var meta = load_ppd_meta(data_ini_path, "PPDEXT+" + base_path.plus_file(dir_name))
					meta.title = dir_name
					if meta:
						songs.append(meta)
				else:
					songs.append_array(_discover_songs_recursive(i_path, base_path.plus_file(dir_name)))
			dir_name = dir.get_next()
	return songs

func load_songs():
	return _discover_songs_recursive(UserSettings.user_settings.ppd_songs_directory)

# If true this loader manages discovery by itself
func uses_custom_load_paths():
	return true
	
func caching_enabled():
	return false
