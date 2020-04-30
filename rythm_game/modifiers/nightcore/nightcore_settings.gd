extends HBSerializable

var speed = 110

func _init():
	serializable_fields += ["speed"]

func get_serialized_type():
	return "NightcoreSettings"
