extends HBSerializable

class_name HBAtlasEntry

var region: Rect2
var margin: Rect2

func _init():
	serializable_fields += ["region", "margin"]

func get_serialized_type():
	return "HBAtlasEntry"
