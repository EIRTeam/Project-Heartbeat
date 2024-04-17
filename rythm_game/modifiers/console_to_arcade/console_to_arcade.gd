extends HBModifier

const ConsoleToArcadeSettings = preload("res://rythm_game/modifiers/console_to_arcade/console_to_arcade_settings.gd")

func _init():
	modifier_settings = get_modifier_settings_class().new()

func _init_plugin():
	# Base init plugin must always be called after local init
	super._init_plugin()

static func get_modifier_name():
	return TranslationServer.tr("Console to arcade", &"Console to arcade modifier name")

func _preprocess_timing_points(points: Array) -> Array:
	var current_slide_dir := 1
	var slide_dirs := [
		HBBaseNote.NOTE_TYPE.SLIDE_LEFT,
		HBBaseNote.NOTE_TYPE.SLIDE_RIGHT,
	]
	for i in range(points.size()):
		var point := points[i] as HBTimingPoint
		if not modifier_settings.keep_hearts:
			if point.note_type == HBBaseNote.NOTE_TYPE.HEART:
				point.note_type = slide_dirs[current_slide_dir]
				current_slide_dir = (current_slide_dir + 1) % 2
		
		if point is HBDoubleNote:
			# Doubles to singles
			points[i] = point.convert_to_type("Note")
		elif point is HBSustainNote:
			# Sustains to two notes
			var pt := point.convert_to_type("Note") as HBNoteData
			points[i] = pt
			match modifier_settings.sustain_mode:
				HBConsoleToArcadeModifierSettings.SUSTAIN_MODE.TWO_NOTES:
					# Points are sorted by the game, so it's ok to not check i think
					var pt2 := pt.clone() as HBTimingPoint
					pt2.time = point.end_time
					points.push_back(pt2)
				HBConsoleToArcadeModifierSettings.SUSTAIN_MODE.HOLD:
					pt.hold = true
	return points

# Some modifiers might use a different name based on settings
func get_modifier_list_name():
	return TranslationServer.tr("Console to arcade (Keep hearts)", &"Console to arcade modifier name when keeping hearts") if modifier_settings.keep_hearts \
		else TranslationServer.tr("Console to arcade", &"Console to arcade modifier name")

static func get_modifier_description():
	return TranslationServer.tr("Converts console-style songs to be compatible with arcade controllers", &"Console to arcade modifier description")
static func get_modifier_settings_class() -> Script:
	return ConsoleToArcadeSettings

static func get_option_settings() -> Dictionary:
	return {
		"keep_hearts": {
			"name": TranslationServer.tr("Keep hearts", &"Console to arcade modifier keep_heartrs property"),
			"description": TranslationServer.tr("If enabled, will keep single hearts and convert double hearts to single hearts.", &"Console to arcade modifier keep_hearts property description"),
			"default_value": false
		},
		"sustain_mode": {
			"name": TranslationServer.tr("Sustain note conversion mode", &"Console to arcade modifier sustain_mode property"),
			"description": TranslationServer.tr("Changes how to convert sustain notes.", &"Console to arcade modifier sustain_mode description"),
			"default_value": HBConsoleToArcadeModifierSettings.SUSTAIN_MODE.TWO_NOTES,
			"options_pretty": [
				TranslationServer.tr("Replace with two notes", &"Console to arcade modifier sustain_mode two note option"),
				TranslationServer.tr("Replace with hold", &"Console to arcade modifier sustain_mode hold option"),
				TranslationServer.tr("Replace with one note", &"Console to arcade modifier sustain_mode single note option")
			],
			"options": [
				HBConsoleToArcadeModifierSettings.SUSTAIN_MODE.TWO_NOTES,
				HBConsoleToArcadeModifierSettings.SUSTAIN_MODE.HOLD,
				HBConsoleToArcadeModifierSettings.SUSTAIN_MODE.SINGLE_NOTE,
			],
			"type": "options"
		}
	}
