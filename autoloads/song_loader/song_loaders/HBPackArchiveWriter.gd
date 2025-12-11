class_name HBPackArchiveWriter

signal song_add_completed

var zip := ZIPPacker.new()

var pack_meta := HBPackMetadata.new()

func _init(_write_path: String) -> void:
	zip.open(_write_path)

func add_song(song: HBSong, meta: HBPackItemSong):
	var source_dir := DirAccess.open(song.path)
	source_dir.list_dir_begin()
	var file_name = source_dir.get_next()

	var song_meta_copy: HBSong = song.clone()

	while file_name != "":
		if not source_dir.current_is_dir():
			zip.start_file(song.id.path_join(file_name))
			var fa := FileAccess.open(song.path.path_join(file_name), FileAccess.READ)
			zip.write_file(fa.get_buffer(fa.get_length()))
			zip.close_file()
		file_name = source_dir.get_next()

	meta.item_directory = song.id
	pack_meta.items.push_back(meta)

func close():
	zip.start_file("meta.json")
	zip.write_file(JSON.stringify(pack_meta.serialize(), "  ").to_utf8_buffer())
	zip.close_file()
	zip.close()
