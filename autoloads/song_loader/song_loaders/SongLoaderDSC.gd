# Project DIVA-style song song loading code
extends SongLoaderImpl

class_name SongLoaderDSC

const LOG_NAME = "SongLoaderDSC"

var GAME_LOCATION = ""

const DSCConverter = preload("DSCConverter.gd")

var fs_access: DSCGameFSAccess

var opcode_map: DSCOpcodeMap

var game_type = "FT"

class HBSongDSC:
	extends HBSong
	var pv_data: DSCPVData
	var game_fs_access: DSCGameFSAccess
	var _audio_cache: WeakRef
	var opcode_map: DSCOpcodeMap
	func _init(_pv_data: DSCPVData, _game_fs_access: DSCGameFSAccess, _opcode_map: DSCOpcodeMap):
		self.pv_data = _pv_data
		for diff in pv_data.charts:
			charts[diff] = pv_data.charts[diff]
		title = pv_data.title
		romanized_title = pv_data.title_en
		game_fs_access = _game_fs_access
		opcode_map = _opcode_map
		if "music" in pv_data.metadata:
			artist = pv_data.metadata.music
	func get_song_audio_res_path():
		var p = game_fs_access.get_file_path(pv_data.song_file_name)
		return p
		
	func uses_dsc_style_channels() -> bool:
		return true
	func has_audio():
		return pv_data.song_file_name != ""
	func get_chart_for_difficulty(difficulty) -> HBChart:
		var p = game_fs_access.get_file_path(pv_data.charts[difficulty].dsc_path)
		return DSCConverter.convert_dsc_to_chart(p, opcode_map)
	func is_cached(variant := ""):
		return true
	func get_meta_string():
		var meta = []
		for key in pv_data.metadata:
			var line = "%s: %s" % [key.capitalize(), pv_data.metadata[key]]
			meta.append(line)
		return meta


	func is_chart_note_usage_known(difficulty: String):
		return true

	func is_chart_note_usage_known_all():
		return true
		
	func get_chart_note_usage(difficulty: String):
		return []
	func is_visible_in_editor():
		return false
		
func _init_loader() -> int:
	opcode_map = DSCOpcodeMap.new("res://autoloads/song_loader/song_loaders/dsc_opcode_db.json", game_type)
	return OK
# If true this loader manages discovery by itself
func uses_custom_load_paths():
	return true
	
class DSCPVData:
	var charts := {}
	var song_file_name := ""
	var title := ""
	var title_en := ""
	var pv_id: int
	var metadata = {}
	var tutorial = false
	var bpm: int
	func _init(_pv_id: int):
		self.pv_id = _pv_id

	func _ensure_diff_exists(diff: String):
		if not diff in charts:
			charts[diff] = {"stars": 0.0, "dsc_path": ""}

	func set_dsc_path(diff: String, scr_path: String):
		_ensure_diff_exists(diff)
		charts[diff].dsc_path = scr_path

	func set_star_count_from_str(diff: String, star_c_str: String):
		_ensure_diff_exists(diff)
		var spl = star_c_str.split("_")
		if spl.size() > 1:
			charts[diff].stars = float(spl[-2])
			charts[diff].stars += float(spl[-1]) / 10.0
func dsc_diff_to_hb_diff(diff: String):
	var result = diff
	match diff:
		"easy0":
			result = "EASY"
		"normal0":
			result = "NORMAL"
		"hard0":
			result = "HARD"
		"extreme0":
			result = "EXTREME"
		"extreme1":
			result = "EXTRA EXTREME"
		"easyscript_file_name":
			result = "EASY"
		"normalscript_file_name":
			result = "NORMAL"
		"hardscript_file_name":
			result = "HARD"
		"extremescript_file_name":
			result = "EXTREME"
		"dt1_easyscript_file_name":
			result = "EASY (DSC1)"
		"dt1_normalscript_file_name":
			result = "NORMAL (DSC1)"
		"dt1_hardscript_file_name":
			result = "HARD (DSC1)"
	return result

class DSCGameFSAccess:
	var subroms = []
	
	var search_paths = []
	
	var game_location
	var is_valid = true
	var pack = false
	func _init(_game_location: String, mdata_loader: MDATALoader):
		game_location = _game_location
		
		var dir = Directory.new()
		if not dir.dir_exists(_game_location):
			is_valid = false
		for mdata_name in mdata_loader.mdatas:
			var mdata_rom_dir = mdata_loader.mdatas[mdata_name]
			if dir.dir_exists(mdata_rom_dir):
				subroms.append(mdata_name)
				search_paths.append(mdata_rom_dir)
		search_paths.append(game_location)
		if dir.open(game_location) == OK:
			dir.list_dir_begin()
			var dir_name = dir.get_next()
			while dir_name != "":
				if dir.current_is_dir():
					if dir_name.begins_with("rom_"):
						subroms.append(dir_name)
						search_paths.append(HBUtils.join_path(game_location, dir_name))
				dir_name = dir.get_next()
				
	func get_file_path(path: String):
		var file := File.new()
		for s_path in search_paths:
			var file_path = HBUtils.join_path(s_path, path)
			if file.file_exists(file_path):
				return file_path
		return null
class MDATALoader:
	var path: String
	var mdatas: Dictionary = {}
	func _init(_path: String):
		path = _path
		var dir = Directory.new()
		
		if not dir.dir_exists(_path):
			return
		if dir.open(_path) == OK:
			var file = File.new()
			dir.list_dir_begin()
			var dir_name = dir.get_next()
			var mdata_names = []
			while dir_name != "":
				if dir.current_is_dir():
					if dir_name.begins_with("M"):
						if dir_name.length() == 4:
							var mdata_path = HBUtils.join_path(_path, dir_name)
							var info_path = HBUtils.join_path(mdata_path, "info.txt")
							if file.file_exists(info_path):
								mdata_names.append(dir_name)
				dir_name = dir.get_next()
				
			mdata_names.sort()
			mdata_names.invert()
			for mdata_name in mdata_names:
				var mdata_path = HBUtils.join_path(_path, mdata_name)
				mdatas[mdata_name] = mdata_path
			for mdata_name in mdatas:
				var mdata_dir_path = mdatas[mdata_name]
				var info_path = HBUtils.join_path(mdata_dir_path, "info.txt")
				if file.open(info_path, File.READ) == OK:
					while not file.eof_reached():
						var line = file.get_line()
						if line.begins_with("depend"):
							var spl_k = line.split(".")
							if spl_k.size() > 1:
								if spl_k[1].is_valid_integer():
									var spl = line.split("=")
									if spl.size() > 1:
										var val = spl[1]
										if not val in mdatas:
											break
					
func load_pv_datas_from_pvdb(pvdb_path: String) -> Dictionary:
	var file = File.new()
	if not file.file_exists(pvdb_path):
		Log.log(self, "Error loading DSC songs from %s PVDB does not exist" % [pvdb_path], Log.LogLevel.ERROR)
		return {}
	file.open(pvdb_path, File.READ)
	var pv_datas = {}
	while not file.eof_reached():
		var line = file.get_line()
		if not line.strip_edges() or line.begins_with("#"):
			continue
		var spl = line.split("=")
		if spl.size() != 2:
			continue
		var key = spl[0]
		var value = spl[1]
		if line.begins_with("pv_"):
			var pv_id = int(line.substr(3, 3))
			if not pv_id in pv_datas.keys():
				pv_datas[pv_id] = DSCPVData.new(pv_id)
			var pv_data := pv_datas[pv_id] as DSCPVData
			if key.ends_with("script_file_name"):
				var difficulty = key.split(".")[2] + key.split(".")[3]
				if fs_access.get_file_path(value):
					pv_data.set_dsc_path(dsc_diff_to_hb_diff(difficulty), value)
			if key.ends_with("song_file_name"):
				pv_data.song_file_name = value
			if key.ends_with("song_name"):
				pv_data.title = value
			elif key.ends_with("song_name_en"):
				pv_data.title_en = value
			if key.ends_with("level"):
				var difficulty = key.split(".")[2] + key.split(".")[3]
				pv_data.set_star_count_from_str(dsc_diff_to_hb_diff(difficulty), value)
			if key.ends_with("bpm"):
				pv_data.bpm = int(value)
			if key.ends_with("tutorial"):
				if value == "1":
					pv_data.tutorial = true
			var sp = key.split(".")
			if sp.size() > 2:
				if sp[1] == "songinfo":
					var meta_name = sp[2]
					if meta_name.ends_with("_en"):
						meta_name = meta_name.substr(0, meta_name.length()-3)
					if not meta_name in pv_data.metadata:
						pv_data.metadata[meta_name] = value
				if sp[1] == "songinfo_en":
					var meta_name = sp[2]
					if meta_name.ends_with("_en"):
						meta_name = meta_name.substr(0, meta_name.length()-3)
					pv_data.metadata[meta_name] = value
	return pv_datas
func load_songs() -> Array:
	var mdata_path = HBUtils.join_path(GAME_LOCATION, "mdata")
	var mdata_loader = MDATALoader.new(mdata_path)
	fs_access = DSCGameFSAccess.new(GAME_LOCATION, mdata_loader)
	
	if not fs_access.is_valid:
		Log.log(self, "Error loading DSC songs from %s" % [GAME_LOCATION], Log.LogLevel.ERROR)
		return []
	
	
	var pv_datas = {}
	for pvdb_path in ["rom/pv_db.txt", "rom/mdata_pv_db.txt"]:
		var PVDB_LOCATION = fs_access.get_file_path(pvdb_path)
		if not PVDB_LOCATION:
			Log.log(self, "Error loading DSC songs from %s PVDB does not exist (%s)" % [GAME_LOCATION, pvdb_path], Log.LogLevel.ERROR)
			continue
		var datas = load_pv_datas_from_pvdb(PVDB_LOCATION)
		pv_datas = HBUtils.merge_dict(pv_datas, datas)
	var songs = []
	for pv_id in pv_datas:
		var pv_data := pv_datas[pv_id] as DSCPVData
		# Not entirely sure why but pv_755 in m39s is broken?
		# we also ignore tutorial charts
		if pv_data.charts.size() == 0 or \
				pv_data.tutorial:
			continue
		for i in range(pv_data.charts.size()-1, -1, -1):
			var chart_name = pv_data.charts.keys()[i]
			if not pv_data.charts[chart_name].dsc_path:
				pv_data.charts.erase(chart_name)
		var song := HBSongDSC.new(pv_data, fs_access, opcode_map)
		song.id = "pv_" + str(pv_id)
		songs.append(song)
		
	return songs
