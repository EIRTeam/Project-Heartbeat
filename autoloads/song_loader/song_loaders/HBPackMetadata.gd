extends HBSerializable

class_name HBPackMetadata

enum ItemType {
	SONG,
	RESOURCE_PACK
}

var title: String
var description: String
var items: Array[HBPackItem]

func _init() -> void:
	serializable_fields += [
		"title",
		"description",
		"items"
	]

func get_serialized_type():
	return "HBPackMetadata"
