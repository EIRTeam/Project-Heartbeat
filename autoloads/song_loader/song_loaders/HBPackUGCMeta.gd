extends HBSerializable

class_name HBPackUGCMeta

enum ItemType {
	SONG,
	RESOURCE_PACK
}

var title: String
var description: String
var ugc_provider: String
var ugc_id: int
var extra_metadata: Dictionary

func _init() -> void:
	serializable_fields += [
		"title",
		"description",
		"ugc_provider",
		"ugc_id",
		"extra_metadata"
	]

func get_serialized_type():
	return "HBPackUGCMeta"
