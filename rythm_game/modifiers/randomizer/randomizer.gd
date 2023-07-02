extends HBModifier

const RandomizerSettings = preload("res://rythm_game/modifiers/randomizer/randomizer_settings.gd")

func _init():
	pass

func _init_plugin():
	# Base init plugin must always be called after local init
	super._init_plugin()
func _preprocess_timing_points(points: Array) -> Array:
	randomize()
	var notes = [HBNoteData.NOTE_TYPE.UP, HBNoteData.NOTE_TYPE.DOWN, HBNoteData.NOTE_TYPE.LEFT, HBNoteData.NOTE_TYPE.RIGHT]
	notes.shuffle()
	var note_remap_dict = {
		HBNoteData.NOTE_TYPE.UP: notes[0],
		HBNoteData.NOTE_TYPE.DOWN: notes[1],
		HBNoteData.NOTE_TYPE.LEFT: notes[2],
		HBNoteData.NOTE_TYPE.RIGHT: notes[3]
	}
	
	for point in points:
		if point is HBBaseNote:
			if point.note_type in note_remap_dict:
				point.note_type = note_remap_dict[point.note_type]
	return points
static func get_modifier_name():
	return "Randomizer"

# Some modifiers might use a different name based on settings
func get_modifier_list_name():
	return "Randomizer"

static func get_modifier_description():
	return "Randomizes the notes."
static func get_modifier_settings_class() -> Script:
	return RandomizerSettings
static func get_option_settings() -> Dictionary:
	return {}
