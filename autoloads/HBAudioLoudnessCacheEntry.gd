extends HBSerializable

class_name HBAudioLoudnessCacheEntry

var modified: int
var loudness: float

func _init():
	serializable_fields += ["modified", "loudness"]

func get_serialized_type():
	return "AudioLoudnessCacheEntry"
