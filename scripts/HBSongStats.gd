extends HBSerializable

class_name HBSongStats

var times_played = 0
var selected_variant := -1

func _init():
	serializable_fields = ["times_played", "selected_variant"]

func get_serialized_type():
	return "SongStats"
