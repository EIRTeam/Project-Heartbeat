extends HBSerializable

class_name HBFolder

var songs = []
var subfolders = []
var sort_mode = "title"
var folder_name = ""

func _init():
	serializable_fields += [
		"songs", "subfolders", "sort_mode", "folder_name"
	]

func get_serialized_type():
	return "Folder"
