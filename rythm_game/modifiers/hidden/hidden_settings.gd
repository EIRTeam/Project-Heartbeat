extends HBSerializable

func _init():
	serializable_fields += []

func get_serialized_type():
	return "HiddenSettings"
