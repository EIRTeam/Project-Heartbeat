class_name HBSerializable

var serializable_fields := []
func serialize():
	var serialized_data = {}
	for field in serializable_fields:
		serialized_data[field] = var2str(get(field))
	return HBUtils.merge_dict(serialized_data, {
		"type": get_serialized_type()
	})
	
static func deserialize(data: Dictionary):
	var object = get_serializable_types()[data.type].new()
	for field in object.serializable_fields:
		if data.has(field):
			print("DATA HAS", data[field])
			object.set(field, str2var(data[field]))
	return object
	
static func get_serializable_types():
	return {
		"Note": load("res://scripts/HBNote.gd"),
		"TimingPoint": load("res://scripts/HBTimingPoint.gd")
	}
func get_serialized_type():
	pass
