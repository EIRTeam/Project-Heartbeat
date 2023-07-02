extends "res://addons/gut/test.gd"

class TestSerialization:
	extends "res://addons/gut/test.gd"
		
	func _type_test(cl: GDScript, property_name: String, expected_type: int, test_value):
		var test_class = cl.new()
		test_class.set(property_name, test_value)
		var result = test_class.serialize()
		assert_typeof(result.get(property_name), expected_type)
		assert_eq(result.get(property_name), test_value)
		
	func test_serialize_int():
		_type_test(HBNoteData, "time_out", TYPE_INT, 12)

	func test_serialize_float():
		_type_test(HBNoteData, "entry_angle", TYPE_FLOAT, 12.5)

	func test_serialize_string():
		_type_test(HBSong, "title", TYPE_STRING, "Hello, I am a test title!")

	func test_serialize_array():
		_type_test(HBPerSongEditorSettings, "hidden_layers", TYPE_ARRAY, ["UwU"])

	func test_recursive_serialize():
		var test = HBGameInfo.new()
		test.result.score = 123
		var result = test.serialize()
		assert_eq(result.result.type, "Result")
		assert_eq(result.result.score, 123)
		assert_typeof(result.result.score, TYPE_INT)
		
class TestDeserialization:
	extends "res://addons/gut/test.gd"
	func _type_test(cl: GDScript, property_name: String, expected_type: int, test_value):
		var inst = cl.new() as HBSerializable
		var type = inst.get_serialized_type()
		var result = {
			"type": type,
			property_name: test_value
		}
		var r = HBSerializable.deserialize(result)
		assert_true(r is cl)
	func test_deserialize_int():
		_type_test(HBNoteData, "time_out", TYPE_INT, 12)

	func test_deserialize_float():
		_type_test(HBNoteData, "entry_angle", TYPE_FLOAT, 12.5)

	func test_deserialize_string():
		_type_test(HBSong, "title", TYPE_STRING, "Hello, I am a test title!")

	func test_deserialize_array():
		_type_test(HBPerSongEditorSettings, "hidden_layers", TYPE_ARRAY, ["UwU"])

	func test_recursive_deserialize():
		var test = {
			"type": "GameInfo",
			"result": {
				"score": 123,
				"type": "Result"
			}
		}
		var result = HBSerializable.deserialize(test)
		assert_eq(result.result.score, 123)
