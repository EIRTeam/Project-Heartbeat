class_name HBSerializable

var serializable_fields := []
func serialize():
	var defaults = get_serializable_types()[get_serialized_type()].new()
	var serialized_data = {}
	for field in serializable_fields:
		var _field = get(field)
		# Ensures that we don't write defaults to disk, in case we change them
		if _field == defaults.get(field):
			continue
		if _field is Object and field.has_method("serialize"):
			serialized_data[field] = _field.serialize()
		if _field is Array or _field is int or _field is float or _field is String or _field is Dictionary or _field is bool:
			serialized_data[field] = get(field)
		else:
			serialized_data[field] = var2str(get(field))
	return HBUtils.merge_dict(serialized_data, {
		"type": get_serialized_type()
	})
	
static func deserialize(data: Dictionary):
	var object = get_serializable_types()[data.type].new()
	for field in object.serializable_fields:
		var _field = object.get(field)
		if data.has(field):
			if _field is Dictionary:
				if data[field].has("type"):
					# Recursive serialized objects
					object.set(field, deserialize(data[field]))
				elif _field.size() > 0:
					# Support for enums
					var dict := data[field] as Dictionary
					if _field.keys()[0] is int:
						# we found an enum
						var result_field = {}
						for key in dict:
							result_field[int(key)] = dict[key]
						object.set(field, result_field)
				else:
					object.set(field, data[field])
			elif _field is Array or _field is float or _field is String or _field is bool:
				object.set(field, data[field])
			elif _field is int:
				object.set(field, int(data[field]))
			else:
				object.set(field, str2var(data[field]))
	return object
	
static func get_serializable_types():
	return {
		"Note": load("res://scripts/HBNoteData.gd"),
		"TimingPoint": load("res://scripts/HBTimingPoint.gd"),
		"HoldNote": load("res://scripts/HBHoldNoteData.gd"),
		"SlideNote": load("res://scripts/HBTimingPoint.gd"),
		"Song": load("res://scripts/HBSong.gd"),
		"Result": load("res://scripts/HBResult.gd"),
		"UserSettings": load("res://scripts/HBUserSettings.gd"),
		"BpmChange": load("res://scripts/HBBPMChange.gd"),
		"PerSongEditorSettings": load("res://scripts/HBPerSongEditorSettings.gd")
	}
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

# Returns a clone of itself
func clone() -> HBSerializable:
	return deserialize(serialize())
