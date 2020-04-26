extends HBSerializable

var speed = 100

func _init():
	serializable_fields += ["speed"]

func get_serialized_type():
	return "GameInfo"
