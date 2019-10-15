extends HBSerializable

class_name HBPackageMeta

var name: String
var description: String
var authors = []
var version: String = "1.0.0"

const DEV_PACKAGE_DIR = "user://dev_packages"

func _init():
	serializable_fields = ["name", "description", "authors", "version"]
	
func get_serialized_type():
	return "Package"

static func get_dev_package_path(package_name: String):
	return DEV_PACKAGE_DIR + "/%s" % [package_name]

static func get_dev_package_meta_path(package_name: String):

	return get_dev_package_path(package_name).plus_file("package.json")
static func get_dev_package_song_path(package_name: String, song_name: String):
	return get_dev_package_path(package_name).plus_file("songs").plus_file(song_name)
static func get_dev_package_song_meta_path(package_name: String, song_name: String):
	print(get_dev_package_song_path(package_name, song_name).plus_file("song.json"))
	return get_dev_package_song_path(package_name, song_name).plus_file("song.json")
