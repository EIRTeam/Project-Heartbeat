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
			elif _field is Dictionary:
				var out_dict: Dictionary = {}
				for key in _field:
					var value = _field[key]
					if value is Object and value.has_method("serialize"):
						out_dict[key] = value.serialize()
					else:
						out_dict[key] = value
				serialized_data[field] = out_dict
			elif _field is int or _field is float or _field is String or _field is bool:
				serialized_data[field] = get(field)
			else:
				serialized_data[field] = var_to_str(get(field))
		return HBUtils.merge_dict(serialized_data, {
			"type": get_serialized_type()
		})

var deprecated_fields := []
static func deserialize(data: Dictionary):
	if "type" in data:
		if not data.type in get_serializable_types():
			print("Error deserializing unknown type " + data.type)
			return null
		var object = get_serializable_types()[data.type].new()
		
		var _deserializable_fields: Array = object.serializable_fields.duplicate()
		_deserializable_fields.append_array(object.deprecated_fields.duplicate())
		
		for field in _deserializable_fields:
			var _field = object.get(field)
			if data.has(field):
				if _field is Object and _field.has_method("serialize"):
					if data[field] is Dictionary and data[field].has("type"):
						# Fixes cloning...
						object.set(field, deserialize(data[field]))
					elif not data[field] is Dictionary:
						push_error("Error deserializing %s, field %s was expected to be a dictionary but it wasn't, it was instead a %d" % [data.type, field, typeof(data[field])])
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
						
					var out_dict = data[field]
					for key in out_dict:
						var value = out_dict[key]
						if value is Dictionary:
							if "type" in out_dict[key]:
								var o = deserialize(value)
								if o:
									out_dict[key] = o
					object.set(field, out_dict)
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
				elif data[field] is Dictionary and "type" in data[field]:
					# The black sheep of this deserialization code
					var deserialized = deserialize(data[field])
					
					object.set(field, deserialized)
				else:
					object.set(field , str_to_var(data[field]))
		return object
	
static func get_serializable_types():
	return HBGame.serializable_types
func get_serialized_type():
	pass

static func from_file(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		var data = file.get_as_text()
		var json_result := JSON.new()
		
		if json_result.parse(data) == OK:
			return deserialize(json_result.data)
		else:
			print("Error parsing JSON file %s on line %d %s" % [path, json_result.get_error_line(), json_result.get_error_message()], Log.LogLevel.ERROR)
			
	else:
		print("Error opening JSON file %s" % [path], Log.LogLevel.ERROR)

func save_to_file(path: String):
	var data = serialize()
	if not data:
		print("ERROR: Data was not serialized.")
		return
	
	var json = JSON.stringify(data, "  ")
	if not json:
		print("ERROR: Data could not be formatted as json.")
		return
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if FileAccess.get_open_error() == OK:
		file.store_string(json)
	else:
		print("Error when saving serialized object %s, error: %s" % [get_serialized_type(), FileAccess.get_open_error()])
	
	return FileAccess.get_open_error()

static func can_show_in_editor():
	return false

func convert_to_type(target_type: String) -> HBSerializable:
	var new_data_ser = serialize()
	new_data_ser["type"] = target_type
	var new_note = deserialize(new_data_ser)
	return new_note

func get_sanitized_field(field_name: String) -> String:
	assert(get(field_name) is String, "get_sanitized_field is only for String fields")
	return (get(field_name) as String).strip_edges()

# Returns a clone of itself
func clone() -> HBSerializable:
	var c = get_script().new()
	for property in serializable_fields:
		c.set(property, self.get(property))
	return c

func _to_string():
	return "HBSerializable (%s)" % [get_serialized_type()]
