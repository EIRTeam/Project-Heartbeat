extends HBSerializable

class_name HBPackItem

var title: String
var description: String
var item_directory: String
var ugc_metadata: Dictionary

func _init() -> void:
	serializable_fields += [
		"title",
		"description",
		"item_directory",
		"ugc_metadata"
	]

func get_serialized_type():
	return "HBPackItem"
