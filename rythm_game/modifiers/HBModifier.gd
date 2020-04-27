class_name HBModifier

# Uses same format as OptionsMenu
var options = {}
var modifier_settings: HBSerializable

func _pre_game(song: HBSong, game: HBRhythmGame):
	pass

func _post_game(song: HBSong, game: HBRhythmGame):
	pass

func _preprocess_timing_points(points: Array) -> Array:
	return points

func _init_plugin():
	pass
	
# Returns the option values to default 
func reset_defaults():
	# Dicts are passed by reference so we gotta clone them
	modifier_settings = get_modifier_settings_class().new()

static func get_modifier_name():
	return "Modifier"

static func get_modifier_description():
	return "Default modifier description, please replace me by overriding static get_modifier_description"

static func get_modifier_settings_class() -> Script:
	return HBSerializable
static func get_option_settings() -> Dictionary:
	return {}
