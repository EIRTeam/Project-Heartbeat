class_name DSCOpcodeMap

var opcode_db: Dictionary
var _id_to_opcode_name_map: Dictionary = {}
# selected game for processing
var game: String
var _game_info_entry_n: String

var opcode_names_to_id = {}

func _init(map_path = "res://autoloads/song_loader/song_loaders/dsc_opcode_db.json", _game = "FT"):
	var file := FileAccess.open(map_path, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	opcode_db = test_json_conv.get_data()
	if _game == "MMPLUS":
		_game = "FT"
	game = _game
	_game_info_entry_n = "info_" + _game
	for opcode_name in opcode_db:
		if _game_info_entry_n in opcode_db[opcode_name]:
			var opcode_entry = opcode_db[opcode_name][_game_info_entry_n]
			_id_to_opcode_name_map[int(opcode_entry.id)] = opcode_name
			# slightly more memory but faster lookup, doesn't matter much
			opcode_names_to_id[opcode_name] = int(opcode_entry.id)

func get_opcode_parameter_count(opcode: int):
	var parameter_count = -1
	if opcode in _id_to_opcode_name_map:
		if _game_info_entry_n in opcode_db[_id_to_opcode_name_map[opcode]]:
			parameter_count = opcode_db[_id_to_opcode_name_map[opcode]][_game_info_entry_n].len
	return parameter_count
