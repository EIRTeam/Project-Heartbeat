class_name HBReplayPackage

var replay_info: HBReplayInformation

var replay_reader: HBReplayReader
var replay_data_writer: HBReplayWriter

func from_file(file_path: String) -> int:
	var reader := ZIPReader.new()
	var err := reader.open(file_path)
	if err != OK:
		return err
	
	var info := reader.read_file("replay.json").get_string_from_utf8()
	var json := JSON.new()
	err = json.parse(info)
	if err != OK:
		return err
	replay_info = HBReplayInformation.deserialize(json.data)
	
	if not replay_info:
		return ERR_PARSE_ERROR
	
	replay_reader = HBReplayReader.from_buffer(reader.read_file("replay.phr"))
	
	return err

func to_file(file_path: String) -> int:
	var writer := ZIPPacker.new()
	var err := writer.open(file_path)
	if err != OK:
		return err
	
	var dict := replay_info.serialize() as Dictionary
	
	writer.start_file("replay.json")
	writer.write_file(JSON.stringify(dict, " ").to_utf8_buffer())
	writer.close_file()
	
	writer.start_file("replay.phr")
	writer.write_file(replay_data_writer.write_to_buffer())
	writer.close_file()
	
	writer.close()
	
	return OK
