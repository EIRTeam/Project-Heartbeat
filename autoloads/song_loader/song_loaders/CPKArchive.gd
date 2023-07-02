class_name CPKArchive

const KEY := [
	0xCF, 0x53, 0xBF, 0x9C, 0x37, 0x67, 0xAF, 0xB0, 0x35, 0x54, 0x4E, 0xB9, 0x96, 0xAA, 0x24, 0x39,
	0x26, 0x5D, 0x40, 0x89, 0x7E, 0xD0, 0x1C, 0x3A, 0x6B, 0xA6, 0x5D, 0xD5, 0xFD, 0x6C, 0x19, 0xA3
]

const IV := [
	0xC2, 0x55, 0xFD, 0x73, 0xD8, 0x30, 0xFA, 0xEF, 0xD5, 0x32, 0x08, 0x54, 0xA2, 0x26, 0x44, 0x14
]

const BLOCK_SIZE := 16

class CPKEntry:
	var name := ""
	var position := 0
	var length := 0

var has_error := false
var error_message := ""

var entries := {}

var file: FileAccess

var roms_found := []

func propagate_error(error_m: String):
	has_error = true
	error_message = error_m
	push_error(error_m)

func read_table_from_chunk(expected_signature: String) -> Array:
	var table = CriUTFTable.new()
	return table.read_from_chunk(file, expected_signature)
	
func open(_file: FileAccess):
	
	file = _file
	
	var cpk := read_table_from_chunk("CPK ")[0] as Dictionary
	
	var toc_offset: int = cpk.get("TocOffset")
	var content_offset: int = cpk.get("ContentOffset")
	var alignment: int = cpk.get("Align")
	
	file.seek(toc_offset)
	
	var toc = read_table_from_chunk("TOC ")
	
	for row in toc:
		var entry := CPKEntry.new()
		entry.name = row.get("DirName").path_join(row.get("FileName")).replace("\\", "/")
		
		entry.position = row.get("FileOffset")
		entry.length = row.get("FileSize")
		
		if content_offset < toc_offset:
			entry.position += content_offset
		else:
			entry.position += toc_offset
			
		entry.position = HBUtils.align(entry.position, alignment)
		
		var rom := entry.name.split("/")[0]
		if rom.begins_with("rom_"):
			if not rom in roms_found:
				roms_found.append(rom)
		
		entries[entry.name] = entry
func load_file(file_path: String) -> StreamPeerBuffer:
	file_path = get_file_rom_path(file_path)
	if not file_path:
		return StreamPeerBuffer.new()
	var aes_context := AESContext.new()
	aes_context.start(AESContext.MODE_CBC_DECRYPT, KEY, IV)
	
	var entry := entries[file_path] as CPKEntry

	file.seek(entry.position)

	var out := PackedByteArray()
	out.resize(entry.length)

	var file_buff := file.get_buffer(entry.length)
	var unenc_buffer := aes_context.update(file_buff)
	unenc_buffer.resize(unenc_buffer.size() - unenc_buffer[-1])
	
	var spb := StreamPeerBuffer.new()
	spb.data_array = unenc_buffer
	
	return spb

func load_text_file(file_path: String) -> String:
	return load_file(file_path).data_array.get_string_from_utf8()

func get_file_rom_paths(file_path: String) -> Array:
	var rom_paths := []
	for rom in roms_found:
		var rom_path := rom.path_join(file_path) as String
		if has_file_internal(rom_path):
			rom_paths.append(rom_path)
			break
	return rom_paths

func has_file_internal(file_path: String) -> bool:
	return file_path in entries

func get_file_rom_path(file_path: String) -> String:
	if has_file_internal(file_path):
		return file_path
	var paths := get_file_rom_paths(file_path)
	if paths.size() > 0:
		return paths[0]
	else:
		return ""

func has_file(file_path: String) -> bool:
	return has_file_internal(file_path) or get_file_rom_paths(file_path).size() > 0
