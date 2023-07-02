# PPD pack file reader
extends Node

class_name PPDPack

const LOG_NAME = "PDPack"

var file_name_lengths = []
var file_sizes = []
var file_names = []
var file_offsets = []
var header_offset = 0
var path
var file
var valid = true
const SIGNATURE = "PPDPACKV1"
func _init(_path: String):
	path = _path
	
	file = FileAccess.open(path, FileAccess.READ)
	
	var signature = file.get_buffer(SIGNATURE.length()).get_string_from_ascii()
	if signature != SIGNATURE:
		Log.log(self, "Erorr when loading pack, signature doesn't match", Log.LogLevel.ERROR)
		valid = false
	
	var length = file.get_8()
	while length > 0:
		file_name_lengths.append(length)
		length = file.get_8()
		
	for name_length in file_name_lengths:
		var file_name = file.get_buffer(name_length)
		file_names.append(file_name)
		var size = file.get_32()
		file_sizes.append(size)
	header_offset = file.get_position()
#	var last_index = header_offset + size_sum
	# Read file
	var offset = header_offset
	file_offsets.append(header_offset)
	for i in range(file_sizes.size()-1):
		offset += file_sizes[i]
		file_offsets.append(offset)
	file.seek(offset)
	
func get_file_index(file_name: String):
	var index = -1
	for i in range(file_names.size()):
		if file_name == file_names[i].get_string_from_utf8():
			index = i
	return index
