extends HBSerializable

class_name HBUserSettings

var visualizer_enabled = true
var visualizer_resolution = 32
var lag_compensation = 0
var icon_pack = "xbox"

func _init():
	serializable_fields += ["visualizer_enabled", "visualizer_resolution", "lag_compensation", "icon_pack"]

func get_serialized_type():
	return "UserSettings"
