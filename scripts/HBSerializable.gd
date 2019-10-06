class_name HBSerializable

var serializable_fields := []
func serialize():
	var serialized_data = {}
	for field in serializable_fields:
		var _field = get(field)
		if _field is Array or _field is int or _field is float or _field is String:
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
			if field is Dictionary:
				if data[field].has("type"):
					object.set(field, deserialize(data[field]))
			elif _field is Array or _field is float or _field is String or _field is Dictionary:
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
		"MultiNote": load("res://scripts/HBMultiNoteData.gd"),
		"Song": load("res://scripts/HBSong.gd")
	}
func get_serialized_type():
	pass

static func can_show_in_editor():
	return false
