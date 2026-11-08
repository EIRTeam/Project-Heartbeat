extends RefCounted

class_name HBPackArchive

var meta: HBPackMetadata
var zip_file: PHZipArchive
var error: int = OK
var pack_id: String

const MAX_METADATA_SIZE := 16 * 1024 * 1024
const MAX_BUFFERED_ASSET_SIZE := 512 * 1024 * 1024

func _load(path: String) -> int:
	pack_id = path
	zip_file = PHZipArchive.new()
	
	if not zip_file.try_open_pack(ProjectSettings.globalize_path(path), false, 0):
		return FAILED
	
	if not zip_file.file_exists("meta.json"):
		printerr("Zip at %s did not contain a meta.json file!" % [path])
		return ERR_FILE_NOT_FOUND
	
	var metadata_file := zip_file.get_file("meta.json")
	if metadata_file == null or not metadata_file.is_open():
		return ERR_FILE_CANT_OPEN
	if metadata_file.get_length() > MAX_METADATA_SIZE:
		printerr("Metadata in zip at %s is too large!" % [path])
		return ERR_OUT_OF_MEMORY
	var data_str := metadata_file.get_as_text()
	var json := JSON.new()
	if json.parse(data_str) != OK:
		printerr("Error failing pack archive JSON %s at line %d", json.get_error_message(), json.get_error_line())
		return FAILED
	
	if not json.data is Dictionary:
		printerr("Metadata in zip at %s was not a JSON object!" % [path])
		return ERR_FILE_CORRUPT
	meta = HBPackMetadata.deserialize(json.data) as HBPackMetadata
	
	if not meta:
		printerr("Failed to deserialize pack archive metadata for package %s!" % [path])
		return FAILED
	return OK
	
func load_songs() -> Array[SongLoaderImpl.SongLoadResult]:
	var songs: Array[SongLoaderImpl.SongLoadResult]
	if meta == null or zip_file == null:
		return songs
	for item in meta.items:
		if item is HBPackItemSong:
			var meta_path := item.item_directory.path_join("song.json")
			if not zip_file.file_exists(meta_path):
				print("HBPackArchive: Song file at %s was in manifest but did not exist!" % [zip_file])
				songs.push_back(SongLoaderImpl.SongLoadResult.make_error(SongLoaderImpl.SongLoadResult.SongLoadError.GENERIC_FAILURE, "Song file at %s was in manifest but did not exist!" % [zip_file]))
				continue
			var song_meta_file := zip_file.get_file(meta_path)
			if song_meta_file == null or not song_meta_file.is_open():
				songs.push_back(SongLoaderImpl.SongLoadResult.make_error(SongLoaderImpl.SongLoadResult.SongLoadError.GENERIC_FAILURE, "Could not open %s" % meta_path))
				continue
			if song_meta_file.get_length() > MAX_METADATA_SIZE:
				songs.push_back(SongLoaderImpl.SongLoadResult.make_error(SongLoaderImpl.SongLoadResult.SongLoadError.GENERIC_FAILURE, "Song metadata is too large: %s" % meta_path))
				continue
			var song_meta_json_text := song_meta_file.get_as_text()
			
			var test_json_conv = JSON.new()
			var json_err := test_json_conv.parse(song_meta_json_text)
			if json_err == OK and test_json_conv.data is Dictionary:
				var song_json: Dictionary = test_json_conv.data
				song_json["type"] = "HBSongFromPack" # HACK-ish
				var song_instance := HBSongFromPack.deserialize(song_json) as HBSongFromPack
				if song_instance == null:
					songs.push_back(SongLoaderImpl.SongLoadResult.make_error(SongLoaderImpl.SongLoadResult.SongLoadError.GENERIC_FAILURE, "Could not deserialize %s" % meta_path))
					continue
				song_instance.id = pack_id + item.item_directory
				song_instance.path = item.item_directory
				song_instance.pack_archive = self
				songs.push_back(SongLoaderImpl.SongLoadResult.make_ok(song_instance))
			else:
				print(self, "HBPackArchive: Error loading song config file on line %d: %s" % [test_json_conv.get_error_line(), test_json_conv.get_error_message()])
				songs.push_back(SongLoaderImpl.SongLoadResult.make_error(SongLoaderImpl.SongLoadResult.SongLoadError.GENERIC_FAILURE, "Error loading song config file on line %d: %s" % [test_json_conv.get_error_line(), test_json_conv.get_error_message()]))
	return songs

func read_full_file(path: String) -> PackedByteArray:
	if zip_file == null or not zip_file.file_exists(path):
		return PackedByteArray()
	var f := zip_file.get_file(path)
	if f == null or not f.is_open() or f.get_length() > MAX_BUFFERED_ASSET_SIZE:
		return PackedByteArray()
	return f.get_buffer(f.get_length())
static func from_path(path: String) -> HBPackArchive:
	var archive := HBPackArchive.new()
	archive.error = archive._load(path)
	return archive
