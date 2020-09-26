extends HBSerializable

class_name HBSongMetaCacheEntry

var modified: int
var meta: HBSong = HBSong.new()
func _init():
	serializable_fields += ["modified", "meta"]

func get_serialized_type():
	return "MetaCacheEntry"
