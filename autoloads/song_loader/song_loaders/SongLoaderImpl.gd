class_name SongLoaderImpl
# Base for all other song loaders

# Returns the file name song loader will look for
func get_meta_file_name() -> String:
	return ""

func _init_loader():
	pass

func load_song_meta_from_folder(path: String, id: String):
	pass
