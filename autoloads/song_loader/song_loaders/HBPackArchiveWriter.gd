class_name HBPackArchiveWriter

signal song_add_completed

const CHUNK_SIZE := 16 * 1024 * 1024

var zip := PHZIPPacker.new()
var open_error: int = OK
var closed := false

var pack_meta := HBPackMetadata.new()

func _init(_write_path: String) -> void:
	open_error = zip.open(_write_path)

func get_open_error() -> int:
	return open_error

func add_song(song: HBSong, meta: HBPackItemSong) -> int:
	if open_error != OK or closed:
		return open_error if open_error != OK else ERR_UNCONFIGURED
	var source_dir := DirAccess.open(song.path)
	if source_dir == null:
		return DirAccess.get_open_error()
	source_dir.list_dir_begin()
	var file_name = source_dir.get_next()

	while file_name != "":
		if not source_dir.current_is_dir():
			var fa := FileAccess.open(song.path.path_join(file_name), FileAccess.READ)
			if fa == null:
				source_dir.list_dir_end()
				return FileAccess.get_open_error()
			var start_error := zip.start_file(song.id.path_join(file_name))
			if start_error != OK:
				source_dir.list_dir_end()
				return start_error
			var file_length := fa.get_length()
			while fa.get_position() < file_length:
				var remaining := file_length - fa.get_position()
				var requested := min(remaining, CHUNK_SIZE)
				var data := fa.get_buffer(requested)
				if data.size() != requested:
					zip.close_file()
					source_dir.list_dir_end()
					return ERR_FILE_CANT_READ
				var write_error := zip.write_file(data)
				if write_error != OK:
					zip.close_file()
					source_dir.list_dir_end()
					return write_error
			var close_error := zip.close_file()
			if close_error != OK:
				source_dir.list_dir_end()
				return close_error
		file_name = source_dir.get_next()
	source_dir.list_dir_end()

	meta.item_directory = song.id
	pack_meta.items.push_back(meta)
	return OK

func close() -> int:
	if closed:
		return OK
	if open_error != OK:
		closed = true
		return open_error
	var start_error := zip.start_file("meta.json")
	if start_error != OK:
		return start_error
	var write_error := zip.write_file(JSON.stringify(pack_meta.serialize(), "  ").to_utf8_buffer())
	if write_error != OK:
		zip.close_file()
		return write_error
	var close_file_error := zip.close_file()
	if close_file_error != OK:
		return close_file_error
	var close_error := zip.close()
	if close_error == OK:
		closed = true
	return close_error
