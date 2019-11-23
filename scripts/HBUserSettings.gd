extends HBSerializable

class_name HBUserSettings

var visualizer_enabled = false
var visualizer_resolution = 64
var lag_compensation = 0

func _init():
	serializable_fields += ["visualizer_enabled", "visualizer_resolution", "lag_compensation"]

func get_serialized_type():
	return "UserSettings"
