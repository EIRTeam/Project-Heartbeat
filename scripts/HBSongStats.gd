extends HBSerializable

class_name HBSongStats

var times_played = 0

func _init():
    serializable_fields = ["times_played"]

func get_serialized_type():
    return "SongStats"