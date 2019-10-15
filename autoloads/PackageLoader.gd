extends Node

var search_paths = ["user://packages"]
const LOG_NAME = "PackageLoader"
func _ready():
	SongLoader.songs = HBUtils.merge_dict(SongLoader.songs, SongLoader.load_songs_from_path("res://songs"))
	for path in search_paths:
		mount_packages_in_directory(path)

func mount_packages_in_directory(path: String):
	var dir := Directory.new()
	var value = {}
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if not dir.current_is_dir() and not file_name.begins_with(".") and file_name.ends_with("pck"):
				mount_package(path.plus_file(file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return value
	
func mount_package(pck_path: String):
	ProjectSettings.load_resource_pack(pck_path, true)
	var package = HBPackageMeta.new()
	package = HBPackageMeta.from_file("res://package.json")
	Log.log(self, "Successfully loaded package %s" % package.name)
	SongLoader.songs = HBUtils.merge_dict(SongLoader.songs, SongLoader.load_songs_from_path("res://songs"))
