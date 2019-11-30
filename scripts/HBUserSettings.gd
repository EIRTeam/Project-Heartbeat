extends HBSerializable

class_name HBUserSettings

var visualizer_enabled = false
var visualizer_resolution = 64
var lag_compensation = 0
var icon_pack = "playstation"

func _init():
	serializable_fields += ["visualizer_enabled", "visualizer_resolution", "lag_compensation", "icon_pack"]

func get_serialized_type():
	return "UserSettings"
