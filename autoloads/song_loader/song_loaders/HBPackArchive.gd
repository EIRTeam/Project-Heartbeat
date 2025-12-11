extends RefCounted

class_name HBPackArchive

var meta: HBPackMetadata
var zip_file: PHZipArchive
var error: int = OK
var pack_id: String

func _load(path: String) -> int:
	pack_id = path
	zip_file = PHZipArchive.new()
	
	if not zip_file.try_open_pack(ProjectSettings.globalize_path(path), false, 0):
		return FAILED
	
	if not zip_file.file_exists("meta.json"):
		printerr("Zip at %s did not contain a meta.json file!" % [path])
		return ERR_FILE_NOT_FOUND
	
	var data_str := zip_file.get_file("meta.json").get_as_text()
	var json := JSON.new()
	if json.parse(data_str) != OK:
		printerr("Error failing pack archive JSON %s at line %d", json.get_error_message(), json.get_error_line())
		return FAILED
	
	meta = HBPackMetadata.deserialize(json.data) as HBPackMetadata
	
	if not meta:
		printerr("Failed to deserialize pack archive metadata for package %s!" % [path])
		return FAILED
	return OK
	
func load_songs() -> Array[SongLoaderImpl.SongLoadResult]:
	var songs: Array[SongLoaderImpl.SongLoadResult]
	for item in meta.items:
		if item is HBPackItemSong:
			var meta_path := item.item_directory.path_join("song.json")
			if not zip_file.file_exists(meta_path):
				print("HBPackArchive: Song file at %s was in manifest but did not exist!" % [zip_file])
				songs.push_back(SongLoaderImpl.SongLoadResult.make_error(SongLoaderImpl.SongLoadResult.SongLoadError.GENERIC_FAILURE, "Song file at %s was in manifest but did not exist!" % [zip_file]))
				continue
			var song_meta_json_text := zip_file.get_file(meta_path).get_as_text()
			
			var test_json_conv = JSON.new()
			var json_err := test_json_conv.parse(song_meta_json_text)
			var song_json = test_json_conv.get_data()
			song_json["type"] = "HBSongFromPack" # HACK-ish
			if json_err == OK:
				var song_instance := HBSongFromPack.deserialize(song_json) as HBSongFromPack
				song_instance.id = pack_id + item.item_directory
				song_instance.path = item.item_directory
				song_instance.pack_archive = self
				songs.push_back(SongLoaderImpl.SongLoadResult.make_ok(song_instance))
			else:
				print(self, "HBPackArchive: Error loading song config file on line %d: %s" % [test_json_conv.get_error_line(), test_json_conv.get_error_message()])
				songs.push_back(SongLoaderImpl.SongLoadResult.make_error(SongLoaderImpl.SongLoadResult.SongLoadError.GENERIC_FAILURE, "Error loading song config file on line %d: %s" % [test_json_conv.get_error_line(), test_json_conv.get_error_message()]))
	return songs

func read_full_file(path: String) -> PackedByteArray:
	if not zip_file.file_exists(path):
		return PackedByteArray()
	var f := zip_file.get_file(path)
	return f.get_buffer(f.get_length())
static func from_path(path: String) -> HBPackArchive:
	var archive := HBPackArchive.new()
	archive.error = archive._load(path)
	return archive
