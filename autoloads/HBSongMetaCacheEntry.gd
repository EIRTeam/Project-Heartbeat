extends HBSerializable

class_name HBSongMetaCacheEntry

var modified: int
var meta: HBSong = HBSong.new()
var optional_file_modified: Array = [] # Modified times for additional meta files

func _init():
	serializable_fields += ["modified", "meta", "optional_file_modified"]

func get_serialized_type():
	return "MetaCacheEntry"
