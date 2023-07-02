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
		has_audio_loudness = true
		audio_loudness = -13.0
		for diff in pv_data.charts:
			charts[diff] = pv_data.charts[diff]
		title = pv_data.title
		romanized_title = pv_data.title_en
		game_fs_access = _game_fs_access
		opcode_map = _opcode_map
		if pv_data.preview_start != 0.0:
			preview_start = pv_data.preview_start * 1000
			if pv_data.preview_duration != 0.0:
				preview_end = preview_start + pv_data.preview_duration * 1000
		if "music" in pv_data.metadata:
			artist = pv_data.metadata.music
		var j := 1
		for i in _pv_data.variants:
			var variant: Dictionary = _pv_data.variants[i]
			if "song_file_name" in variant:
				var vari := HBSongVariantData.new()
				var name: String = variant.get("name", "")
				vari.variant_name = name if name else "Variant %d" % j
				song_variants.push_back(vari)
			j += 1
	func get_song_audio_res_path():
		var p = game_fs_access.get_file_path(pv_data.song_file_name)
		return p
		
	func uses_dsc_style_channels() -> bool:
		return true
	func has_audio():
		return game_fs_access.get_file_path(pv_data.song_file_name) != ""
	func get_chart_for_difficulty(difficulty) -> HBChart:
		return DSCConverter.convert_dsc_to_chart(pv_data.charts[difficulty].dsc_path, opcode_map)
	func is_cached(variant := -1):
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

class HBSongMMPLUS:
	extends HBSongDSC
	
	# If true, this song was modified by a mod
	var is_mod_song := false
	# If true, this song is part of the original game
	var is_built_in := true
	# array of dicts
	var mod_infos := []
	
	func _init(_pv_data: DSCPVData, _game_fs_access: DSCGameFSAccess, _opcode_map: DSCOpcodeMap):
		super._init(_pv_data, _game_fs_access, _opcode_map)
		preview_image = "PLACEHOLDER"
		background_image = "PLACEHOLDER"
		circle_image = "PLACEHOLDER"
		is_mod_song = pv_data.is_mod_song
		mod_infos = pv_data.mod_infos
		is_built_in = pv_data.is_built_in
	
	func get_song_audio_res_path():
		return pv_data.song_file_name
	
	func get_audio_stream(variant := -1):
		var audio_path = get_song_audio_res_path()
		if variant != -1:
			audio_path = pv_data.variants.values()[variant].get("song_file_name", audio_path)
		var audio_data := game_fs_access.load_file_as_buffer(audio_path)
		var audio_stream := PHNative.load_ogg_from_buffer(audio_data.data_array)
		return audio_stream
	
	func get_song_select_sprite_set():
		var farc_archive := FARCArchive.new()
		
		var farc_path := "rom/2d/spr_sel_pv%s.farc" % [pv_data.pv_id_str]
		var file_path := game_fs_access.get_file_path(farc_path) as String
		if file_path:
			var buff := game_fs_access.load_file_as_buffer(file_path)
			farc_archive.open(buff)
			var sprite_set_path := "spr_sel_pv%s.bin" % [pv_data.pv_id_str]
			var sprite_set_buffer := farc_archive.get_file_buffer(sprite_set_path)
			var sprite_set := DIVASpriteSet.new()
			sprite_set.read(sprite_set_buffer)
			return sprite_set
	
	func get_chart_for_difficulty(difficulty) -> HBChart:
		var chart_path := pv_data.charts[difficulty].dsc_path as String
		var buff := game_fs_access.load_file_as_buffer(chart_path)
		return DSCConverter.convert_dsc_buffer_to_chart(buff, opcode_map)
		
	func get_meta_string():
		var meta := []
		if is_mod_song:
			for mod_info in mod_infos:
				var mod_name = mod_info.get("default", {}).get("name")
				if not mod_name:
					mod_name = "UNK"
				if mod_name:
					meta.append("Mod: %s" % [mod_name])
		meta.append_array(super.get_meta_string())
		return meta

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
	var pv_id_str: String
	var metadata = {}
	var tutorial = false
	var bpm: int
	var preview_start := 0.0
	var preview_duration := 0.0
	var has_ex_stage := false
	# if true, this song was modified by a mod
	var is_mod_song := false
	# if true, this song is a part of the original game
	var is_built_in := true
	var mod_infos := []
	var variants := {}
	
	func _init(_pv_id: int):
		self.pv_id = _pv_id

	func _ensure_diff_exists(diff: String):
		if not diff in charts:
			charts[diff] = {"stars": 0.0}

	func set_dsc_path(diff: String, scr_path: String):
		_ensure_diff_exists(diff)
		charts[diff]["dsc_path"] = scr_path

	func set_diff_length(diff: String, length: int):
		_ensure_diff_exists(diff)
		charts[diff]["length"] = length

	func set_star_count_from_str(diff: String, star_c_str: String):
		_ensure_diff_exists(diff)
		var spl = star_c_str.split("_")
		if spl.size() > 1:
			charts[diff].stars = float(spl[-2])
			charts[diff].stars += float(spl[-1]) / 10.0
	func merge(other: DSCPVData):
		for chart in other.charts:
			if chart in charts:
				charts[chart].merge(other.charts[chart], true)
			else:
				charts[chart] = other.charts[chart]
		song_file_name = other.song_file_name
		title = other.title_en
		metadata.merge(other.metadata, true)
		mod_infos.append_array(other.mod_infos)
		tutorial = other.tutorial
		bpm = other.bpm
		preview_start = other.preview_start
		preview_duration = other.preview_duration
		has_ex_stage = other.has_ex_stage
		is_mod_song = other.is_mod_song
		is_built_in = other.is_built_in
		variants.merge(other.variants, true)

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
		
		if not DirAccess.dir_exists_absolute(_game_location):
			is_valid = false
		for mdata_name in mdata_loader.mdatas:
			var mdata_rom_dir = mdata_loader.mdatas[mdata_name]
			if DirAccess.dir_exists_absolute(mdata_rom_dir):
				subroms.append(mdata_name)
				search_paths.append(mdata_rom_dir)
		search_paths.append(game_location)
		var dir := DirAccess.open(game_location)
		if DirAccess.get_open_error() == OK:
			dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
			var dir_name = dir.get_next()
			while dir_name != "":
				if dir.current_is_dir():
					if dir_name.begins_with("rom_"):
						subroms.append(dir_name)
						search_paths.append(HBUtils.join_path(game_location, dir_name))
				dir_name = dir.get_next()
				
	func get_file_path(path: String):
		for s_path in search_paths:
			var file_path = HBUtils.join_path(s_path, path)
			if FileAccess.file_exists(file_path):
				return file_path
		return ""
		
	func load_file_as_buffer(path: String) -> StreamPeerBuffer:
		var spb := StreamPeerBuffer.new()
		var file_path := get_file_path(path) as String
		if not file_path:
			return spb
		else:
			var f := FileAccess.open(file_path, FileAccess.READ)
			spb.data_array = f.get_buffer(f.get_length())
		return spb
		
class MMPLUSModFSAccess:
	extends DSCGameFSAccess
	var mod_name: String
	var mod_location: String
	var base_game_fs_access: MMPLUSFSAccess
	func _init(_game_location: String, _mod_name: String, _base_game_fs_access: MMPLUSFSAccess, \
			mdata_loader: MDATALoader):
		super._init(_game_location, mdata_loader)
		mod_name = _mod_name
		mod_location = _game_location.path_join("mods").path_join(_mod_name)
		base_game_fs_access = _base_game_fs_access
		if DirAccess.dir_exists_absolute(mod_location):
			is_valid = true
	func get_file_path(path: String):
		if FileAccess.file_exists(path):
			return path
		var full_file_path := mod_location.path_join(path)
		return full_file_path if FileAccess.file_exists(full_file_path) else ""
		
	func load_file_as_buffer(path: String) -> StreamPeerBuffer:
		var full_file_path = get_file_path(path)
		if full_file_path:
			var f := FileAccess.open(full_file_path, FileAccess.READ)
			if FileAccess.get_open_error() == OK:
				var spb := StreamPeerBuffer.new()
				spb.data_array = f.get_buffer(f.get_length())
				return spb
		return StreamPeerBuffer.new()
class MMPLUSFSAccess:
	extends DSCGameFSAccess
	
	const REGION_CPK_NAME := "diva_main_region.cpk"
	const REGION_ROM_NAME := "rom_steam_region"
	const MAIN_CPK_NAME := "diva_main.cpk"
	const MAIN_ROM_NAME := "rom_steam"
	const REGION_DLC_CPK_NAME := "diva_dlc00_region.cpk"
	const REGION_DLC_ROM_NAME := "rom_steam_region_dlc"
	const DLC_CPK_NAME := "diva_dlc00.cpk"
	const DLC_ROM_NAME := "rom_steam_dlc"

	var has_dlc := true
	
	var cpk_archives := {
		REGION_CPK_NAME: CPKArchive.new(),
		MAIN_CPK_NAME: CPKArchive.new(),
		REGION_DLC_CPK_NAME: CPKArchive.new(),
		DLC_CPK_NAME: CPKArchive.new()
	}
	
	class FileCacheEntry:
		var pack: CPKArchive
		var mod: MMPLUSModFSAccess
		var is_mod := false
		var internal_path: String
	
	var file_path_cache := {}
	
	# mod filesystems, ordered by priority
	var mod_fs := []
	
	func _init(_game_location: String, mdata_loader: MDATALoader):
		super(_game_location, mdata_loader)
		cpk_archives[REGION_CPK_NAME].set_meta("rom", REGION_ROM_NAME)
		cpk_archives[MAIN_CPK_NAME].set_meta("rom", MAIN_ROM_NAME)
		cpk_archives[REGION_DLC_CPK_NAME].set_meta("rom", REGION_DLC_ROM_NAME)
		cpk_archives[DLC_CPK_NAME].set_meta("rom", DLC_ROM_NAME)
		
		for file in [REGION_CPK_NAME, MAIN_CPK_NAME, REGION_DLC_CPK_NAME, DLC_CPK_NAME]:
			var cpk_path := _game_location.path_join(file)
			if not FileAccess.file_exists(cpk_path):
				if file == DLC_CPK_NAME or file == REGION_DLC_CPK_NAME:
					has_dlc = false
				if file == MAIN_CPK_NAME:
					return
			else:
				var farchive := FileAccess.open(cpk_path, FileAccess.READ)
				cpk_archives[file].open(farchive)
		if not has_dlc:
			cpk_archives.erase(REGION_DLC_CPK_NAME)
			cpk_archives.erase(DLC_CPK_NAME)
		is_valid = true
		
	func get_file_path(path: String):
		var cache_entry := file_path_cache.get(path) as FileCacheEntry
		if cache_entry:
			return cache_entry.internal_path
		else:
			for m in mod_fs:
				var mod := m as MMPLUSModFSAccess
				var p: String = mod.get_file_path(path)
				if p:
					var cache := FileCacheEntry.new()
					cache.mod = mod
					cache.is_mod = true
					cache.internal_path = p
					file_path_cache[path] = cache
					file_path_cache[p] = cache
					return cache.internal_path
			for pack in cpk_archives.values():
				var paths = pack.get_file_rom_paths(path)
				var found_path := ""
				if paths.size() > 0:
					found_path = paths[0]
				elif pack.has_file(path):
					found_path = path
				if found_path:
					var cache := FileCacheEntry.new()
					cache.pack = pack
					cache.internal_path = found_path
					file_path_cache[path] = cache
					file_path_cache[found_path] = cache
					return found_path
		return ""
	func load_file_as_buffer(path: String) -> StreamPeerBuffer:
		var cache_entry := file_path_cache.get(path) as FileCacheEntry
		if cache_entry:
			if cache_entry.is_mod:
				return cache_entry.mod.load_file_as_buffer(cache_entry.internal_path)
			return cache_entry.pack.load_file(cache_entry.internal_path)
		else:
			var file_p: String = get_file_path(path)
			if file_p:
				return load_file_as_buffer(path)
				
		return StreamPeerBuffer.new()
		
class MDATALoader:
	var path: String
	var mdatas: Dictionary = {}
	func _init(_path: String):
		path = _path
		
		if not DirAccess.dir_exists_absolute(_path):
			return
		var dir = DirAccess.open(_path)
		if DirAccess.get_open_error() == OK:
			dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
			var dir_name = dir.get_next()
			var mdata_names = []
			while dir_name != "":
				if dir.current_is_dir():
					if dir_name.begins_with("M"):
						if dir_name.length() == 4:
							var mdata_path = HBUtils.join_path(_path, dir_name)
							var info_path = HBUtils.join_path(mdata_path, "info.txt")
							if FileAccess.file_exists(info_path):
								mdata_names.append(dir_name)
				dir_name = dir.get_next()
				
			mdata_names.sort()
			mdata_names.reverse()
			for mdata_name in mdata_names:
				var mdata_path = HBUtils.join_path(_path, mdata_name)
				mdatas[mdata_name] = mdata_path
			for mdata_name in mdatas:
				var mdata_dir_path = mdatas[mdata_name]
				var info_path = HBUtils.join_path(mdata_dir_path, "info.txt")
				var file := FileAccess.open(info_path, FileAccess.READ)
				if FileAccess.get_open_error() == OK:
					while not file.eof_reached():
						var line = file.get_line()
						if line.begins_with("depend"):
							var spl_k = line.split(".")
							if spl_k.size() > 1:
								if spl_k[1].is_valid_int():
									var spl = line.split("=")
									if spl.size() > 1:
										var val = spl[1]
										if not val in mdatas:
											break
					
func parse_pvdb(pvdb: String) -> Dictionary:
	var pv_datas := {}
	for line in pvdb.split("\n"):
		if not line.strip_edges() or line.begins_with("#"):
			continue
		var spl = line.split("=")
		if spl.size() != 2:
			continue
		var key = spl[0]
		var value = spl[1]
		if line.begins_with("pv_"):
			var candidate := line.split(".")[0].split("_") as Array
			if candidate.size() <= 1:
				continue
			var pv_id_str := candidate[1] as String
			var pv_id = int(pv_id_str)
			if not pv_id in pv_datas.keys():
				pv_datas[pv_id] = DSCPVData.new(pv_id)
				pv_datas[pv_id].pv_id_str = pv_id_str
			var pv_data := pv_datas[pv_id] as DSCPVData
			if key.ends_with("ex_stage"):
				pv_data.has_ex_stage = true
				continue
			if key.ends_with("script_file_name"):
				var difficulty = key.split(".")[2] + key.split(".")[3]
				var get_f_path = fs_access.get_file_path(value)
				if get_f_path:
					pv_data.set_dsc_path(dsc_diff_to_hb_diff(difficulty), get_f_path)
			if "ex_song" in key:
				# Use an ex_ prefix, just in case a song has both another_song and ex_song
				var var_i := int(key.split(".")[2])
				var var_ex_str := "ex_" + str(var_i)
				if not var_ex_str in pv_data.variants:
					pv_data.variants[var_ex_str] = {}
				var variant_data: Dictionary = pv_data.variants[var_ex_str]
				if key.ends_with("file"):
					variant_data["song_file_name"] = value
				elif key.ends_with("chara") and not "name" in variant_data:
					variant_data["chara"] = true
					variant_data["name"] = value + " Ver."
				elif key.ends_with("name") and not "ex_auth" in key:
					if not "name" in variant_data or variant_data.get("chara", false):
						variant_data["name"] = value
						variant_data["chara"] = false
				elif key.ends_with("name_en"):
					variant_data["name"] = value
					variant_data["chara"] = false
			elif "another_song" in key:
				var var_i := int(key.split(".")[2])
				if var_i == 0:
					continue
				if not var_i in pv_data.variants:
					pv_data.variants[var_i] = {}
				if key.ends_with("song_file_name"):
					pv_data.variants[var_i]["song_file_name"] = value
				elif key.ends_with("name"):
					if not "name" in pv_data.variants[var_i]:
						pv_data.variants[var_i]["name"] = value
				elif key.ends_with("name_en"):
					pv_data.variants[var_i]["name"] = value
			elif key.ends_with("song_file_name"):
				pv_data.song_file_name = value
			if key.ends_with("song_name"):
				pv_data.title = value
			elif key.ends_with("song_name_en"):
				pv_data.title_en = value
			elif key.ends_with("level"):
				var difficulty = key.split(".")[2] + key.split(".")[3]
				pv_data.set_star_count_from_str(dsc_diff_to_hb_diff(difficulty), value)
			elif key.ends_with("bpm"):
				pv_data.bpm = int(value)
			elif key.ends_with("tutorial"):
				if value == "1":
					pv_data.tutorial = true
			elif key.ends_with("sabi.play_time"):
				pv_data.preview_duration = value.to_float()
			elif key.ends_with("sabi.start_time"):
				pv_data.preview_start = value.to_float()
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
func load_pv_datas_from_pvdb(pvdb_path: String) -> Dictionary:
	if not FileAccess.file_exists(pvdb_path):
		Log.log(self, "Error loading DSC songs from %s PVDB does not exist" % [pvdb_path], Log.LogLevel.ERROR)
		return {}
	var file = FileAccess.open(pvdb_path, FileAccess.READ)
	var pv_datas = parse_pvdb(file.get_as_text())
	return pv_datas
	
func load_songs_mmplus() -> Array:
	var mdata_path = HBUtils.join_path(GAME_LOCATION, "mdata")
	var mdata_loader = MDATALoader.new(mdata_path)
	var mmplus_file_access := MMPLUSFSAccess.new(GAME_LOCATION, mdata_loader)
	fs_access = mmplus_file_access
	
	var songs := {}
	
	if not mmplus_file_access.is_valid:
		propagate_error(tr("Couldn't load game data from %s") % [GAME_LOCATION], true)
		return songs.values()
	
	var region_cpk := mmplus_file_access.cpk_archives[MMPLUSFSAccess.REGION_CPK_NAME] as CPKArchive
	var main_pvdb := parse_pvdb(region_cpk.load_text_file("rom_steam_region/rom/pv_db.txt"))
	
	if fs_access.has_dlc:
		var region_dlc_cpk := mmplus_file_access.cpk_archives[MMPLUSFSAccess.REGION_DLC_CPK_NAME] as CPKArchive
		var dlc_pvdb := parse_pvdb(region_dlc_cpk.load_text_file("rom_steam_region_dlc/rom/mdata_pv_db.txt"))
		for pv_id in dlc_pvdb:
			if pv_id in main_pvdb:
				main_pvdb[pv_id].merge(dlc_pvdb[pv_id])
			else:
				main_pvdb[pv_id] = dlc_pvdb[pv_id]
	
	var pv_ids_to_ignore := [67, 68]
	var mods_config_path := GAME_LOCATION.path_join("config.toml") as String
	
	var mods_pv_db := {}
	var mod_filesystems := []
	
	# Load and merge mods DBs
	if DirAccess.dir_exists_absolute(mods_config_path):
		var mods_toml := TOMLParser.from_file(mods_config_path)
		
		var mods_path := GAME_LOCATION.path_join(mods_toml.default.get("mods", "mods")) as String
		var d := DirAccess.open(mods_path)
		if DirAccess.get_open_error() == OK:
			d.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
			
			var current_file := d.get_next()
			while current_file != "":
				if d.current_is_dir():
					var config_toml_path := mods_path.path_join(current_file).path_join("config.toml")
					if not d.file_exists(config_toml_path):
						current_file = d.get_next()
						continue
					
					var mod_toml := TOMLParser.from_file(config_toml_path)
					# Make sure the mod TOML has a name
					var mod_toml_default_section: Dictionary = mod_toml.get("default", {})
					mod_toml["default"] = mod_toml_default_section # In case the default section doesn't already exist
					mod_toml["default"]["name"] = current_file
					
					var mod_fs_access := MMPLUSModFSAccess.new(GAME_LOCATION, current_file, fs_access, mdata_loader)
					mod_filesystems.push_back(mod_fs_access)
					fs_access.mod_fs.push_back(mod_fs_access)
					var mod_dir := mods_path.path_join(current_file)
					for n in [mod_dir.path_join("rom/mod_pv_db.txt"), mod_dir.path_join("rom/eden39_pv_db.txt")]:
						if not FileAccess.file_exists(n):
							continue
						var f := FileAccess.open(n, FileAccess.READ)
						var err := FileAccess.get_open_error()
						if err != OK:
							propagate_error("Error %d loading pvdb from mod" % [err], true)
						var buffer := f.get_as_text()
						if not buffer.is_empty():
							var pvdb_text := buffer
							fs_access = mod_fs_access
							
							var mod_pvdb := parse_pvdb(pvdb_text)
							fs_access = mmplus_file_access
							
							for pv_id in mod_pvdb:
								var pv_data = mod_pvdb[pv_id] as DSCPVData
								pv_data.is_built_in = pv_id in main_pvdb
								pv_data.is_mod_song = true
								pv_data.mod_infos.push_back(mod_toml)
								if pv_id in mods_pv_db:
									mods_pv_db[pv_id].merge(pv_data)
								else:
									mods_pv_db[pv_id] = pv_data
							
				
				current_file = d.get_next()
	
	for pv_id in mods_pv_db:
		if pv_id in main_pvdb:
			main_pvdb[pv_id].merge(mods_pv_db[pv_id])
		else:
			main_pvdb[pv_id] = mods_pv_db[pv_id]
	
	for pv_id in main_pvdb:
		if pv_id in pv_ids_to_ignore:
			continue
		var pv_data := main_pvdb[pv_id] as DSCPVData
		if pv_data.charts.size() == 0 or \
			pv_data.tutorial:
			continue
		
		for i in range(pv_data.charts.size()-1, -1, -1):
			var chart_name = pv_data.charts.keys()[i]
			if not "dsc_path" in pv_data.charts[chart_name] and pv_data.charts[chart_name].get("length", 0) > 0:
				propagate_error(tr("Song ID %s's (%s) difficulty %s did not have a DSC script path") % [pv_data.pv_id_str, pv_data.title_en, chart_name])
				pv_data.charts.erase(chart_name)
		
		var song := HBSongMMPLUS.new(pv_data, fs_access, opcode_map)
		song.id = "pv_" + str(pv_id)
		
		var bpm_timing_change := HBTimingChange.new()
		bpm_timing_change.bpm = pv_data.bpm
		song.timing_changes = [bpm_timing_change]
		
		var ogg_path := mmplus_file_access.get_file_path(pv_data.song_file_name) as String
		if ogg_path:
			songs[song.id] = song
		else:
			if pv_data.has_ex_stage:
				continue
			propagate_error(tr("Couldn't find audio data for song ID %s (%s)") % [pv_data.pv_id_str, pv_data.title_en])
			continue
	
	return songs.values()
func load_songs() -> Array:
	if game_type == "MMPLUS":
		return load_songs_mmplus()
	
	var mdata_path = HBUtils.join_path(GAME_LOCATION, "mdata")
	var mdata_loader = MDATALoader.new(mdata_path)
	fs_access = DSCGameFSAccess.new(GAME_LOCATION, mdata_loader)
	
	if not fs_access.is_valid:
		propagate_error("Game directory does not exist (%s)" % [GAME_LOCATION], true)
		Log.log(self, "Error loading DSC songs from %s" % [GAME_LOCATION], Log.LogLevel.ERROR)
		return []
		
	var pv_datas = {}
	for pvdb_path in ["rom/pv_db.txt", "rom/mdata_pv_db.txt"]:
		var PVDB_LOCATION = fs_access.get_file_path(pvdb_path)
		if not PVDB_LOCATION:
			if pvdb_path == "rom/pv_db.txt":
				propagate_error(tr("PVDB does not exist (%s)") % ["rom/pv_db.txt"], true)
				return []
			
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
				propagate_error(tr("Song ID %s's (%s) difficulty %s did not have a DSC script path") % [pv_data.pv_id_str, chart_name, pv_data.title_en])
		
		var song := HBSongDSC.new(pv_data, fs_access, opcode_map)
		song.id = "pv_" + str(pv_id)
		
		if song.has_audio():
			propagate_error(tr("Song ID %s's audio path (%s) did not exist") % [pv_data.pv_id_str, pv_data.song_file_name])
			print(tr("Song ID %s's audio path (%s) did not exist") % [pv_data.pv_id_str, pv_data.song_file_name])
			songs.append(song)
		
		var bpm_timing_change := HBTimingChange.new()
		bpm_timing_change.bpm = pv_data.bpm
		song.timing_changes = [bpm_timing_change]
	
	return songs
