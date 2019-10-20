
extends HBSerializable
var time: int

class_name HBTimingPoint

var LOG_NAME setget ,get_log_name

func get_log_name():
	return get_serialized_type()

func _init():
	serializable_fields += ["time"]
	
func get_serialized_type():
	return "TimingPoint"

func get_simplified():
	return self

func get_timeline_item():
	Log.log(self, "Unimplemented timeline item", Log.LogLevel.ERROR)
func get_duration():
	return 0
