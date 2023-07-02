extends Node

const LOG_NAME = "ModifierLoader"

const MODIFIER_MOUNT_DIRS = ["res://rhythm_game/modifiers"]

var modifiers = {}

func _ready():
	load_modifiers_from_path("res://rythm_game/modifiers")

func load_all_modifiers():
	pass

func load_modifiers_from_path(path: String):
	var dir := DirAccess.open(path)
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var dir_name = dir.get_next()
		while dir_name != "":
			if dir.current_is_dir() and not dir_name.begins_with("."):
				var modifier_script_path = path + "/%s/%s.gd" % [dir_name, dir_name]
				var modifier_script_path_compiled = path + "/%s/%s.gdc" % [dir_name, dir_name]
				if FileAccess.file_exists(modifier_script_path_compiled):
					modifier_script_path = modifier_script_path_compiled
				if FileAccess.file_exists(modifier_script_path):
					var modifier = load(modifier_script_path)
					if modifier.new() is HBModifier:
						modifiers[dir_name] = modifier
					else:
						var message = "Attempted to load modifier that doesn't inherit HBModifier at path %s" % [modifier_script_path]
						Log.log(self, message, Log.LogLevel.ERROR)
			dir_name = dir.get_next()
		Log.log(self, "Loaded %d modifiers" % [modifiers.size()])
	else:
		Log.log(self, "An error occurred when trying to load songs from %s" % [path], Log.LogLevel.ERROR)

func get_modifier_by_id(name) -> GDScript:
	return modifiers[name]
