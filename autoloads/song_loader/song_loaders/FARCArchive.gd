class_name FARCArchive

const KEY := [
	0x13, 0x72, 0xD5, 0x7B, 0x6E, 0x9E, 0x31, 0xEB, 0xA2, 0x39, 0xB8, 0x3C, 0x15, 0x57, 0xC6, 0xBB
]

const BLOCK_SIZE := 16

var spb := StreamPeerBuffer.new()

var has_error := false
var error_message := ""

var alignment := 0

var entries := {}

enum BINARY_FORMAT {
	FT,
	DT
}

class Entry:
	var name := ""
	var position := 0
	var unpacked_length := 0
	var compressed_length := 0
	var length := 0
	var is_compressed := false
	var is_encrypted := false
	var is_ft := false

func read_string() -> String:
	var curr_offset := spb.get_position()
	
	var out_str := ""
	
	var str_size := 0
	
	while spb.get_available_bytes() != 0:
		var byte := spb.get_8()
		str_size += 1
		if byte == 0x00:
			break
	
	spb.seek(curr_offset)
	
	out_str = spb.get_utf8_string(str_size)
	
	return out_str

func propagate_error(err_msg: String):
	has_error = true
	error_message = err_msg
	push_error(error_message)

func _decrypt_farc():
	spb.seek(0x10)
	var iv := spb.get_data(0x10)[1] as PackedByteArray
	var aes_context := AESContext.new()
	aes_context.start(AESContext.MODE_CBC_DECRYPT, KEY, iv)
	
	var encrypted_start := spb.get_position()
	var encrypted_length := spb.get_size()-spb.get_position()
	var pba = aes_context.update(spb.get_data(encrypted_length)[1])
	
	spb.seek(encrypted_start)
	spb.put_data(pba)
	spb.seek(encrypted_start)
	alignment = spb.get_32()
func open(_spb: StreamPeerBuffer):
	spb = _spb
	spb.big_endian = true
	
	var signature := spb.get_data(4)[1].get_string_from_utf8() as String
	if not signature in ["FARC", "FArC", "FArc"]:
		propagate_error("Invalid FARC file (wrong signature, expected FARC/FArC/FArc)")
		return
	
	var header_size := spb.get_u32() + 0x08
	
	# Might want to implement other farc types in the future
	if signature == "FARC":
		var flags := spb.get_32()
		var is_compressed := ( flags & 2 ) != 0
		var is_encrypted := ( flags & 4 ) != 0
		var _padding := spb.get_32()
		alignment = spb.get_32()
		
		var format = BINARY_FORMAT.FT if is_encrypted && ( alignment & ( alignment - 1 ) ) != 0 else BINARY_FORMAT.DT
		if format == BINARY_FORMAT.FT:
			_decrypt_farc()
		format = BINARY_FORMAT.FT if spb.get_32() == 1 else BINARY_FORMAT.DT
		
		var entry_count = spb.get_32()
		
		if format == BINARY_FORMAT.FT:
			_padding = spb.get_32()
		
		while spb.get_position() < header_size:
			var name := read_string()
			var offset := spb.get_u32()
			var compressed_size := spb.get_u32()
			var uncompressed_size := spb.get_u32()
			
			if format == BINARY_FORMAT.FT:
				flags = spb.get_32()
				is_compressed = ( flags & 2 ) != 0
				is_encrypted = ( flags & 4 ) != 0
				
			var fixed_size := 0
			
			if is_encrypted:
				fixed_size = HBUtils.align(compressed_size if is_compressed else uncompressed_size, 16)
			elif is_compressed:
				fixed_size = compressed_size
			else:
				fixed_size = uncompressed_size
				
			fixed_size = min(fixed_size, spb.get_size()-offset)
			
			var entry := Entry.new()
			entry.name = name
			entry.position = offset
			entry.unpacked_length = uncompressed_size
			entry.compressed_length = min(compressed_size, spb.get_size()-offset)
			entry.length = fixed_size
			entry.is_compressed = is_compressed and compressed_size != uncompressed_size
			entry.is_encrypted = is_encrypted
			entry.is_ft = format == BINARY_FORMAT.FT
			
			entries[entry.name] = entry
			
			entry_count -= 1
			if entry_count == 0:
				break
	elif signature == "FArC":
		var _alignment = spb.get_32()
		
		while spb.get_position() < header_size:
			var name = read_string()
			var offset := spb.get_u32()
			var compressed_size := spb.get_u32()
			var uncompressed_size := spb.get_u32()
			var fixed_size = min(compressed_size, spb.get_size() - offset)
			
			var entry := Entry.new()
			entry.name = name
			entry.position = offset
			entry.unpacked_length = uncompressed_size
			entry.compressed_length = fixed_size
			entry.length = fixed_size
			entry.is_compressed = compressed_size != uncompressed_size
			
			entries[entry.name] = entry
	elif signature == "FArc":
		var _alignment = spb.get_32()
		while spb.get_position() < header_size:
			var name = read_string()
			var offset := spb.get_u32()
			var size := spb.get_u32()
			var fixed_size = min(size, spb.get_size() - offset)
			
			var entry := Entry.new()
			entry.name = name
			entry.position = offset
			entry.unpacked_length = fixed_size
			entry.length = fixed_size
			
			entries[entry.name] = entry


func get_file_buffer(file_path: String) -> StreamPeerBuffer:
	var entry := entries.get(file_path) as Entry
	
	var new_spb := StreamPeerBuffer.new()
	
	if not entry:
		propagate_error("Entry %s not found" % [file_path])
		return new_spb
	
	if entry.is_ft and entry.is_encrypted:
		spb.seek(entry.position + 16)
	else:
		spb.seek(entry.position)
	var data := spb.get_data(entry.length)[1] as PackedByteArray
	if entry.is_compressed:
		new_spb.data_array = data.decompress(entry.unpacked_length, FileAccess.COMPRESSION_GZIP)
	else:
		entry.data_array = data
	
	return new_spb
