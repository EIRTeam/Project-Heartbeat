# Class used for individual song settings by the user.
extends HBSerializable

class_name HBPerSongSettings

var lag_compensation = 0
var volume = 1.0
func _init():
	serializable_fields += ["lag_compensation", "volume"]

func get_serialized_type():
	return "PerSongSettings"
