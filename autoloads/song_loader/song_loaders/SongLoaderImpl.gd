class_name SongLoaderImpl
# Base for all other song loaders

var error_messages := []
var fatal_error_messages := []

func has_fatal_error() -> bool:
	return fatal_error_messages.size() > 0

func has_error() -> bool:
	return error_messages.size() > 0

func propagate_error(error_message: String, fatal := false):
	if fatal:
		fatal_error_messages.append(error_message)
	else:
		error_messages.append(error_message)

# Returns the file name song loader will look for
func get_meta_file_name() -> String:
	return ""

func _init_loader() -> int:
	return OK

func load_song_meta_from_folder(path: String, id: String):
	pass

# If true this loader manages discovery by itself
func uses_custom_load_paths():
	return false
	
# Used for loaders that custom load songs
func load_songs() -> Array:
	return []

func caching_enabled():
	return false

func get_optional_meta_files() -> Array:
	return []
