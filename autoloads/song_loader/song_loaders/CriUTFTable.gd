class_name CriUTFTable

enum ENCODING {
	SHIFT_JIS,
	UTF8
}

enum FIELD_TYPES {
	TYPE_U8,
	TYPE_8,
	TYPE_U16,
	TYPE_16,
	TYPE_U32,
	TYPE_32,
	TYPE_U64,
	TYPE_64,
	TYPE_FLOAT,
	TYPE_DOUBLE,
	TYPE_STRING,
	TYPE_BYTE_ARRAY
}

var SIGNATURE := PackedByteArray([0x40, 0x55, 0x54, 0x46])

var has_error := false
var error_message := ""

var table_encoding: int = ENCODING.SHIFT_JIS

var rows_offset := 0
var string_pool_offset := 0
var data_pool_offset := 0
var name_offset := 0
var field_count := 0
var row_stride := 0
var row_count := 0

var base_offset := 0

func propagate_error(err: String):
	has_error = true
	error_message = err
	push_error(error_message)

class Field:
	var type: int
	var name: String
	var has_default_value: bool
	var default_value
	var is_valid: bool

func read_string(data: StreamPeerBuffer, encoding := ENCODING.SHIFT_JIS):
	var offset := data.get_u32()
	var curr_offset := data.get_position()
	if offset == 0:
		data.seek(curr_offset)
		return ""
	
	
	data.seek(string_pool_offset + offset + base_offset)
	
	var out_str := ""
	
	var str_size := 0
	
	while data.get_available_bytes() != 0:
		var byte := data.get_8()
		str_size += 1
		if byte == 0x00:
			break
	
	data.seek(string_pool_offset + offset + base_offset)
	
	if encoding == ENCODING.SHIFT_JIS:
		# HACK, most UTF table strings can be interpreted as ASCII even in S-JIS decode mode,
		# which is faster we only fallback to shift-jis conversion when needed, however 
		# we need the string size because StreamPeerBuffer is retarded
		out_str = data.get_string(str_size) 
		if out_str == "":
			data.seek(string_pool_offset + offset + base_offset)
			out_str = HBUtils.sj2utf(data.get_data(str_size)[1]).get_string_from_utf8()
	else:
		out_str = data.get_utf8_string(str_size)
	
	data.seek(curr_offset)
	return out_str
	

func read(data: StreamPeerBuffer):
	data.big_endian = true
	var magic := data.get_data(4)[1] as PackedByteArray
	if magic != SIGNATURE:
		propagate_error("Invalid UTF table signature, expected @UTF")
		return
	
	var _length := data.get_32()
	
	base_offset = 8
	
	table_encoding = data.get_u16()
	
	rows_offset = data.get_u16()
	string_pool_offset = data.get_u32()
	data_pool_offset = data.get_u32()
	name_offset = data.get_u32()
	field_count = data.get_u16()
	row_stride = data.get_u16()
	row_count = data.get_32()
	
	var fields := []
	
	for _i in range(field_count):
		var flags := data.get_u8()
		
		var field := Field.new()
		
		field.type = FIELD_TYPES.values()[flags & 0xF]
		field.name = read_string(data) if (flags & 0x10) != 0 else ""
		field.has_default_value = (flags & 0x20) != 0
		
		if field.has_default_value:
			field.default_value = read_value(data, field.type)
		field.is_valid = (flags & 0x40) != 0
		
		fields.append(field)
		
	var rows := []
	
	var _old_position := data.get_position()
	
	for i in range(row_count):
		var row := {}
		
		data.seek(base_offset + rows_offset + i * row_stride)
		
		for field in fields:
			var value
			
			if field.has_default_value:
				value = field.default_value
			elif field.is_valid:
				value = read_value(data, field.type)
			row[field.name] = value
		rows.append(row)
	return rows
func read_value(data: StreamPeerBuffer, value_type: int):
	var value
	match value_type:
		FIELD_TYPES.TYPE_U8:
			value = data.get_u8()
		FIELD_TYPES.TYPE_8:
			value = data.get_8()
		FIELD_TYPES.TYPE_U16:
			value = data.get_u16()
		FIELD_TYPES.TYPE_16:
			value = data.get_16()
		FIELD_TYPES.TYPE_U32:
			value = data.get_u32()
		FIELD_TYPES.TYPE_32:
			value = data.get_32()
		FIELD_TYPES.TYPE_U64:
			value = data.get_u64()
		FIELD_TYPES.TYPE_64:
			value = data.get_64()
		FIELD_TYPES.TYPE_FLOAT:
			value = data.get_float()
		FIELD_TYPES.TYPE_DOUBLE:
			value = data.get_double()
		FIELD_TYPES.TYPE_STRING:
			value = read_string(data)
		FIELD_TYPES.TYPE_BYTE_ARRAY:
			var offset := data.get_u32()
			var length := data.get_32()
			
			var out_position := data.get_position()
			
			var bytes: PackedByteArray
			
			if offset > 0:
				data.seek(base_offset + data_pool_offset + offset)
				var o := data.get_data(length)
				if o[0] != OK:
					propagate_error("Error reading binary data %d" % [o[0]])
				bytes = o[1]
			value = bytes
			data.seek(out_position)
	return value
		
func read_bytes(file: FileAccess, length: int):
	var row_bytes := file.get_buffer(length)
	if row_bytes.slice(0, 3) != SIGNATURE:
		# Masked!?
		var curr := 25951
		for i in range(length):
			row_bytes[i] ^= curr & 0xFF
			curr *= 16661
	var spb := StreamPeerBuffer.new()
	spb.data_array = row_bytes
	return read(spb)
func read_from_chunk(file: FileAccess, expected_signature: String):
	var b := file.get_buffer(4)
	if (b.get_string_from_utf8() != expected_signature):
		propagate_error("Invalid signature, expected %s" % [expected_signature])
	file.get_buffer(4)
	var length := file.get_32()
	file.get_buffer(4)
	var a = read_bytes(file, length)
	return a
