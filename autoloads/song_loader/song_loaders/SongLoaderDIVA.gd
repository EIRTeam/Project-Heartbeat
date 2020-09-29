# Project DIVA-style song song loading code
extends SongLoaderImpl

class_name SongLoaderDIVA

const LOG_NAME = "SongLoaderDIVA"

const DIVA_LOCATION = "/home/eirexe/Descargas/PDAFT/SBZV_7.01"

const DSCConverter = preload("DSCConverter.gd")

class HBSongDIVA:
	extends HBSong
	var pv_data: DIVAPVData
	
	func _init(_pv_data: DIVAPVData):
		self.pv_data = _pv_data
		for diff in pv_data.charts:
			charts[diff] = pv_data.charts[diff]
		title = pv_data.title
	func get_song_audio_res_path():
		return HBUtils.join_path(DIVA_LOCATION, pv_data.song_file_name)
	func has_audio():
		return pv_data.song_file_name != ""
	func get_chart_for_difficulty(difficulty) -> HBChart:
		return DSCConverter.convert_dsc_to_chart(HBUtils.join_path(DIVA_LOCATION, pv_data.charts[difficulty].dsc_path))
	func is_cached():
		return true
func _init_loader():
	pass

# If true this loader manages discovery by itself
func uses_custom_load_paths():
	return true
	
class DIVAPVData:
	var charts := {}
	var song_file_name := ""
	var title := ""
	var diva_location = ""
	var star_count: float = 0.0
	var pv_id: int
	func _init(_diva_location: String, _pv_id: int):
		self.diva_location = _diva_location
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
		print(star_count)
func load_songs() -> Array:
	var PVDB_LOCATION = HBUtils.join_path(DIVA_LOCATION, "rom/pv_db.txt")
	var file = File.new()
	if not file.file_exists(PVDB_LOCATION):
		Log.log(self, "Error loading DIVA songs from %s" % [PVDB_LOCATION], Log.LogLevel.ERROR)
		return []
	file.open(PVDB_LOCATION, File.READ)
	var pv_datas = {}
	var songs = []
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
				pv_datas[pv_id] = DIVAPVData.new(DIVA_LOCATION, pv_id)
			var pv_data := pv_datas[pv_id] as DIVAPVData
			if key.ends_with("script_file_name"):
				var difficulty = key.split(".")[2] + key.split(".")[3]
				pv_data.set_dsc_path(difficulty, value)
			if key.ends_with("song_file_name"):
				pv_data.song_file_name = value
			if key.ends_with("song_name"):
				pv_data.title = value
			if key.ends_with("level"):
				var difficulty = key.split(".")[2] + key.split(".")[3]
				pv_data.set_star_count_from_str(difficulty, value)
	var pvs_str = ""
	for pv_id in pv_datas:
		var pv_data := pv_datas[pv_id] as DIVAPVData
		
		var song := HBSongDIVA.new(pv_data)
		song.id = "pv_" + str(pv_id)
		songs.append(song)
		
	return songs
