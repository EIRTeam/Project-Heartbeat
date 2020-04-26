class_name HBModifier

# Uses same format as OptionsMenu
var options = {}
var modifier_settings_class: Script
var modifier_settings: HBSerializable

func _pre_game(song: HBSong, game: HBRhythmGame):
	pass

func _post_game(song: HBSong, game: HBRhythmGame):
	pass

func _chart_preprocess(chart: HBChart) -> HBChart:
	return chart

func _init_plugin():
	reset_defaults()
	
# Returns the option values to default 
func reset_defaults():
	# Dicts are passed by reference so we gotta clone them
	modifier_settings = modifier_settings_class.new()

static func get_modifier_name():
	return "Modifier"

static func get_modifier_description():
	return "Default modifier description, please replace me by overriding static get_modifier_description"
