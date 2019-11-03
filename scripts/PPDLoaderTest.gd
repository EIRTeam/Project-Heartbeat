extends Control

func _ready():
	var chart = PPDLoader.PPD2HBChart("res://Extreme.ppd")
	var file := File.new()
	print(file.open("user://songs/super_test_song/test.json", File.WRITE))
	file.store_string(JSON.print(chart.serialize(), "  "))
#	extract_pack("user://resource.pak")
func extract_pack(path: String):
	var pack := PPDPack.new(path)
	for file in pack.file_names:
		var f_path = "user://" + file.get_string_from_utf8()
		var dir = Directory.new()
		dir.make_dir_recursive(f_path.get_base_dir())
		var index = pack.get_file_index(file.get_string_from_utf8())
		pack.file.seek(pack.file_offsets[index])
		var buff = pack.file.get_buffer(pack.file_sizes[index])
		
		var f = File.new()
		f.open(f_path, File.WRITE)
		f.store_buffer(buff)
		f.close()
