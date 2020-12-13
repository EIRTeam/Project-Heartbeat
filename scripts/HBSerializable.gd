# Base for any serializable object
class_name HBSerializable

var merge_dict_fields := []

var serializable_fields := []
func serialize(serialize_defaults = false):
	if get_serialized_type():
		var defaults = get_serializable_types()[get_serialized_type()].new()
		var serialized_data = {}
		for field in serializable_fields:
			var _field = get(field)
			# Ensures that we don't write defaults to disk, in case we change them
			if not serialize_defaults and _field == defaults.get(field):
				continue
			if _field is Object and _field.has_method("serialize"):
				serialized_data[field] = _field.serialize(serialize_defaults)
			elif _field is Array:
				var r = []
				for item in _field:
					if item is Object and item.has_method("serialize"):
						r.append(item.serialize(serialize_defaults))
					else:
						r.append(item)
				serialized_data[field] = r
			elif _field is int or _field is float or _field is String or _field is Dictionary or _field is bool:
				serialized_data[field] = get(field)
			else:
				serialized_data[field] = var2str(get(field))
		return HBUtils.merge_dict(serialized_data, {
			"type": get_serialized_type()
		})
	
static func deserialize(data: Dictionary):
	
	if "type" in data:
		if not data.type in get_serializable_types():
			print("Error deserializing unknown type " + data.type)
			return null
		var object = get_serializable_types()[data.type].new()
		for field in object.serializable_fields:
			var _field = object.get(field)
			if data.has(field):
				if _field is Object and _field.has_method("serialize"):
					if data[field].has("type"):
						# Fixes cloning...
						object.set(field, deserialize(data[field]))
				elif _field is Dictionary:
					if _field.size() > 0:
						# Support for enums
						var dict := data[field] as Dictionary
						if _field.keys()[0] is int:
							# we found an enum
							var result_field = {}
							for key in dict:
								result_field[int(key)] = dict[key]
							object.set(field, result_field)
							continue
					if field in object.merge_dict_fields:
						data[field] = HBUtils.merge_dict(_field, data[field])
					object.set(field, data[field])
				elif _field is Array:
					var r = []
					for item in data[field]:
						if item is Dictionary and item.has("type"):
							r.append(deserialize(item))
						else:
							r.append(item)
					object.set(field, r)
				elif _field is float or _field is String or _field is bool:
					var r = data[field]
					if object.get(field + "__possibilities") is Array:
						var possibilities = object.get(field + "__possibilities")
						if not data[field] in possibilities:
							r = possibilities[0]
					object.set(field, r)
				elif _field is int:
					object.set(field, int(data[field]))
				else:
					object.set(field, str2var(data[field]))
		return object
	
static func get_serializable_types():
	HBGame.serializable_mutex.lock()
	var types = {
		"Note": load("res://scripts/timing_points/HBNoteData.gd"),
		"TimingPoint": load("res://scripts/timing_points/HBTimingPoint.gd"),
		"DoubleNote": load("res://scripts/timing_points/HBDoubleNote.gd"),
		"SustainNote": load("res://scripts/timing_points/HBSustainNote.gd"),
		"BpmChange": load("res://scripts/timing_points/HBBPMChange.gd"),
		"Song": load("res://scripts/HBSong.gd"),
		"Result": load("res://scripts/HBResult.gd"),
		"UserSettings": load("res://scripts/HBUserSettings.gd"),
		"PerSongEditorSettings": load("res://scripts/HBPerSongEditorSettings.gd"),
		"GameInfo": load("res://scripts/HBGameInfo.gd"),
		"NightcoreSettings": load("res://rythm_game/modifiers/nightcore/nightcore_settings.gd"),
		"RandomizerSettings": load("res://rythm_game/modifiers/randomizer/randomizer_settings.gd"),
		"PerSongSettings": load("res://scripts/HBPerSongSettings.gd"),
		"SongStats": load("res://scripts/HBSongStats.gd"),
		"Folder": load("res://scripts/HBFolder.gd"),
		"MetaCacheEntry": load("res://autoloads/HBSongMetaCacheEntry.gd"),
		"AudioLoudnessCacheEntry": load("res://autoloads/HBAudioLoudnessCacheEntry.gd"),
		"PPDSong": load("res://scripts/HBPPDSong.gd"),
		"WebUserInfo": load("res://scripts/HBWebUserInfo.gd"),
		"Phrase": load("res://rythm_game/lyrics/HBLyricsPhrase.gd"),
		"PhraseStart": load("res://rythm_game/lyrics/HBLyricsPhraseStart.gd"),
		"PhraseEnd": load("res://rythm_game/lyrics/HBLyricsPhraseEnd.gd"),
		"Lyric": load("res://rythm_game/lyrics/HBLyricsLyric.gd"),
		"TimingModifierSettings": load("res://rythm_game/modifiers/timing/timing_settings.gd")
	}
	HBGame.serializable_mutex.unlock()
	return types
func get_serialized_type():
	pass

static func from_file(path: String):
	var file = File.new()
	if file.open(path, File.READ) == OK:
		var data = file.get_as_text()
		var json_result := JSON.parse(data)
		if json_result.error == OK:
			return deserialize(json_result.result)
		else:
			print("Error parsing JSON file %s on line %d %s" % [path, json_result.error_line, json_result.error_string], Log.LogLevel.ERROR)
			
	else:
		print("Error opening JSON file %s" % [path], Log.LogLevel.ERROR)

func save_to_file(path: String):
	var file := File.new()
	var data = serialize()
	var err = file.open(path, File.WRITE) == OK
	if err:
		file.store_string(JSON.print(data, "  "))
	else:
		Log.log(self, "Error when saving serialized object %s, error: %d" % [get_serialized_type(), err], Log.LogLevel.ERROR)
	return err
static func can_show_in_editor():
	return false

func convert_to_type(target_type: String) -> HBSerializable:
	var new_data_ser = serialize()
	new_data_ser["type"] = target_type
	var new_note = deserialize(new_data_ser)
	return new_note

# Returns a clone of itself
func clone() -> HBSerializable:
	return deserialize(serialize())
