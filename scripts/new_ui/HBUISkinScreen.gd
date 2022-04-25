extends HBSerializable

class_name HBUISkinScreen

var layered_components := {}

func _init():
	serializable_fields += [
		"layered_components"
	]

func get_serialized_type():
	return "SkinScreen"
