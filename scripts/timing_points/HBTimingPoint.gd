# Base class for any game entity that has a "time"
extends HBSerializable
class_name HBTimingPoint

var time: int

var _class_name: String = "HBTimingPoint" # Workaround for godot#4708
var _inheritance: Array = [] # HACK: ClassDB.get_parent_class() is retarded

var LOG_NAME : get = get_log_name

func get_log_name():
	return get_serialized_type()

func _init():
	serializable_fields += ["time"]
	
func get_serialized_type():
	return "TimingPoint"

func get_timeline_item():
	Log.log(self, "Unimplemented timeline item", Log.LogLevel.ERROR)

func get_inspector_properties():
	return {
		"time": {
			"type": "int",
			"params": {
				"suffix": "ms",
			}
		}
	}

func get_duration():
	return 0
