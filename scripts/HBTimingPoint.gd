
extends HBSerializable
var time: int

class_name HBTimingPoint

func _init():
	serializable_fields += ["time"]
	
func get_serialized_type():
	return "TimingPoint"
