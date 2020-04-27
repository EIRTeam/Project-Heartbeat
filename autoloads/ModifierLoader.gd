extends Node

const LOG_NAME = "ModifierLoader"

const MODIFIER_MOUNT_DIRS = ["res://rhythm_game/modifiers"]

var modifiers = {}

func _ready():
	load_modifiers_from_path("res://rythm_game/modifiers")

func load_all_modifiers():
	pass

func load_modifiers_from_path(path: String):
	var dir := Directory.new()
	var value = {}
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var dir_name = dir.get_next()
		while dir_name != "":
			if dir.current_is_dir() and not dir_name.begins_with("."):
				var modifier_script_path = path + "/%s/%s.gd" % [dir_name, dir_name]
				var file = File.new()
				if file.file_exists(modifier_script_path):
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

func get_modifier_by_id(name) -> HBModifier:
	return modifiers[name]
