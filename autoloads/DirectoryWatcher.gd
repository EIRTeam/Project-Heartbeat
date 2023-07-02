extends Node
class_name DirectoryWatcher

var _directory_list: Dictionary
var _to_delete: Array

var _current_directory: int
var _current_directory_name: String
var _remaining_steps: int
var _current_delay: float

var scan_delay: float = 1
var scan_step := 50

signal files_created(files)
signal files_modified(files)
signal files_deleted(files)

func _ready() -> void:
	_current_delay = scan_delay
	_remaining_steps = scan_step

func add_scan_directory(directory: String):
	if directory.begins_with("res://") or directory.begins_with("user://"):
		directory = ProjectSettings.globalize_path(directory)
	_directory_list[directory] = {first_scan = true, new = [], modified = [], current = {}, previous = {}}

func remove_scan_directory(directory: String):
	if directory.begins_with("res://") or directory.begins_with("user://"):
		directory = ProjectSettings.globalize_path(directory)
	_to_delete.append(directory)

func _process(delta: float) -> void:
	if _directory_list.is_empty():
		push_error("No directory to watch. Please kill me ;_;")
		return
	
	if _current_delay > 0:
		_current_delay -= delta
		return
	var _directory: DirAccess
	while _remaining_steps > 0:
		if _current_directory_name.is_empty():
			_current_directory_name = _directory_list.keys()[_current_directory]
			_directory = DirAccess.open(_current_directory_name)
			_directory.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		
		var directory: Dictionary = _directory_list[_current_directory_name]
		
		var file := _directory.get_next()
		if file.is_empty():
			_current_directory += 1
			_current_directory_name = ""
			
			if "first_scan" in directory:
				directory.erase("first_scan")
				directory.new.clear()
				directory.modified.clear()
			else:
				if not directory.new.is_empty():
					emit_signal("files_created", directory.new)
					directory.new.clear()
				
				if not directory.modified.is_empty():
					emit_signal("files_modified", directory.modified)
					directory.modified.clear()
				
				var deleted := []
				for path in directory.previous:
					if not path in directory.current:
						deleted.append(_directory.get_current_dir().path_join(path))
				
				if not deleted.is_empty():
					emit_signal("files_deleted", deleted)
			
			directory.previous = directory.current
			directory.current = {}
			
			if _current_directory == _directory_list.size():
				if not _to_delete.is_empty():
					for dir in _to_delete:
						_directory_list.erase(dir)
				
				_current_directory = 0
				_remaining_steps = scan_step
				_current_delay = scan_delay
				break
		else:
			if _directory.current_is_dir():
				continue
			var full_file := _directory.get_current_dir().path_join(file)
			
			directory.current[file] = FileAccess.get_modified_time(full_file)
			if directory.previous.get(file, -1) == -1:
				directory.new.append(full_file)
			elif directory.current[file] > directory.previous[file]:
				directory.modified.append(full_file)
