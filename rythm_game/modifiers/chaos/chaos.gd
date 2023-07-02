extends HBModifier

const RandomizerSettings = preload("res://rythm_game/modifiers/randomizer/randomizer_settings.gd")

func _init():
	pass

func _init_plugin():
	# Base init plugin must always be called after local init
	super._init_plugin()
func _preprocess_timing_points(points: Array) -> Array:
	randomize()
	var anime_seed = "Oshino shinobu is best waifu"
	var gen_seed = 0
	for i in anime_seed.to_ascii_buffer():
		gen_seed += i
	rand_from_seed(gen_seed)
	var notes = [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]
	notes.shuffle()
	var note_types_to_randomize = [
		HBBaseNote.NOTE_TYPE.UP,
		HBBaseNote.NOTE_TYPE.DOWN,
		HBBaseNote.NOTE_TYPE.LEFT,
		HBBaseNote.NOTE_TYPE.RIGHT,
	]
	var generator = RandomNumberGenerator.new()
	generator.seed = gen_seed
	var last_types = []
	var last_type_time = 0.0
	for point in points:
		if point is HBBaseNote and not point.is_slide_note():
			if point.note_type in note_types_to_randomize:
				note_types_to_randomize.shuffle()
				var new_type = note_types_to_randomize[0]
				if last_type_time == point.time:
					# to maintain multi notes
					if last_types.size() > 0:
						while new_type in last_types:
							note_types_to_randomize.shuffle()
							new_type = note_types_to_randomize[0]
				else:
					last_type_time = point.time
					last_types = []
				last_types.append(new_type)
				
				point.note_type = note_types_to_randomize[0]
				point.position = Vector2(generator.randi_range(192, 1780), generator.randi_range(162, 918))
				point.entry_angle = generator.randf_range(0, 360)
	return points
static func get_modifier_name():
	return "Chaos"

# Some modifiers might use a different name based on settings
func get_modifier_list_name():
	return "Chaos"

static func get_modifier_description():
	return "Good luck."
static func get_modifier_settings_class() -> Script:
	return RandomizerSettings
static func get_option_settings() -> Dictionary:
	return {}
