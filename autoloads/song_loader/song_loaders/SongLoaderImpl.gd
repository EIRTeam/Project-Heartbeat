class_name SongLoaderImpl
# Base for all other song loaders

class SongLoadResult:
	enum SongLoadError {
		OK = 0,
		INVALID_PACKAGE = -1,
		GENERIC_FAILURE = -2
	}
	var error_message := ""
	var error: SongLoadError
	var song: HBSong
	
	static func make_error(_error: SongLoadError, _error_message: String) -> SongLoadResult:
		var res := SongLoadResult.new()
		res.error = _error
		res.error_message = _error_message
		return res
	static func make_ok(_song: HBSong) -> SongLoadResult:
		var res := SongLoadResult.new()
		res.error = SongLoadError.OK
		res.song = _song
		return res

var error_messages := []
var fatal_error_messages := []

enum LoadMethods {
	PACKAGE = 1,
	BARE_FOLDER = 2
}

func get_load_methods() -> int:
	return LoadMethods.BARE_FOLDER

func has_fatal_error() -> bool:
	return fatal_error_messages.size() > 0

func has_error() -> bool:
	return error_messages.size() > 0

func propagate_error(error_message: String, fatal := false):
	if fatal:
		fatal_error_messages.append(error_message)
	else:
		error_messages.append(error_message)

## Returns the file name song loader will look for
func get_meta_file_name() -> String:
	return ""

## Returns the extension of the package file is get_load_method is PACKAGE
func get_package_extension() -> String:
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
	
func load_songs_from_package_file(path: String) -> Array[SongLoadResult]:
	return []

func caching_enabled():
	return false

func get_optional_meta_files() -> Array:
	return []
