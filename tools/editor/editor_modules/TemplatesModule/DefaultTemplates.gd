const DEFAULT_TEMPLATES = {
	###
	### Fast Quad
	###
	"Fast Quad": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(912, 480),
			"entry_angle": -135.0,
			"oscillation_frequency": 1.0,
			"oscillation_amplitude": 3000,
			"distance": 2000
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(1008, 480),
			"entry_angle": -45.0,
			"oscillation_frequency": -1.0,
			"oscillation_amplitude": 3000,
			"distance": 2000
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(912, 576),
			"entry_angle": -225.0,
			"oscillation_frequency": -1.0,
			"oscillation_amplitude": 3000,
			"distance": 2000
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1008, 576),
			"entry_angle": 45.0,
			"oscillation_frequency": 1.0,
			"oscillation_amplitude": 3000,
			"distance": 2000
		}
	},
	###
	### Ellongated sideways Quad
	###
	"Ellongated sideways Quad": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(960, 192),
			"entry_angle": -90.0,
			"oscillation_frequency": 0.0,
			"distance": 800
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(384, 528),
			"entry_angle": -180.0,
			"oscillation_frequency": 0.0,
			"distance": 800
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(960, 864),
			"entry_angle": 90.0,
			"oscillation_frequency": 0.0,
			"distance": 800
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1536, 528),
			"entry_angle": 0.0,
			"oscillation_frequency": 0.0,
			"distance": 800
		}
	},
	###
	### Clockwise rotating Quad part 1
	###
	"Clockwise rotating Quad part 1": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(960, 432),
			"entry_angle": 225.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(864, 528),
			"entry_angle": 135.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(960, 624),
			"entry_angle": 45.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1056, 528),
			"entry_angle": 315.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		}
	},
	###
	### Clockwise rotating Quad part 2
	###
	"Clockwise rotating Quad part 2": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(960, 336),
			"entry_angle": 180.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(768, 528),
			"entry_angle": 90.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(960, 720),
			"entry_angle": 0.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1152, 528),
			"entry_angle": 270.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		}
	},
	###
	### Clockwise rotating Quad part 3
	###
	"Clockwise rotating Quad part 3": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(960, 168),
			"entry_angle": 105.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 2080
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(600, 528),
			"entry_angle": 15.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 2080
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(960, 888),
			"entry_angle": 285.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 2080
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1320, 528),
			"entry_angle": 195.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 2080
		}
	},
	###
	### Counterclockwise rotating Quad part 1
	###
	"Counterclockwise rotating Quad part 1": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(960, 432),
			"entry_angle": -45.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(864, 528),
			"entry_angle": -135.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(960, 624),
			"entry_angle": -225.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1056, 528),
			"entry_angle": 45.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		}
	},
	###
	### Counterclockwise rotating Quad part 2
	###
	"Counterclockwise rotating Quad part 2": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(960, 336),
			"entry_angle": 0.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(768, 528),
			"entry_angle": -90.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(960, 720),
			"entry_angle": -180.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1152, 528),
			"entry_angle": 90.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		}
	},
	###
	### Counterclockwise rotating Quad part 3
	###
	"Counterclockwise rotating Quad part 3": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(960, 168),
			"entry_angle": 75.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 2080
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(600, 528),
			"entry_angle": -15.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 2080
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(960, 888),
			"entry_angle": -105.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 2080
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1320, 528),
			"entry_angle": -195,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 2080
		}
	},
	###
	### Clockwise oscillating Quad
	###
	"Clockwise oscillating Quad": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(960, 336),
			"entry_angle": 270.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(768, 528),
			"entry_angle": 180.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(960, 720),
			"entry_angle": 90.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1152, 528),
			"entry_angle": 0.0,
			"oscillation_frequency": -2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		}
	},
	###
	### Counterclockwise oscillating Quad
	###
	"Counterclockwise oscillating Quad": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(960, 336),
			"entry_angle": 270.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(768, 528),
			"entry_angle": 180.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(960, 720),
			"entry_angle": 90.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1152, 528),
			"entry_angle": 0.0,
			"oscillation_frequency": 2.0,
			"oscillation_amplitude": 1000,
			"distance": 1040
		}
	},
	###
	### Parallelogram
	###
	"Parallelogram": {
		HBNoteData.NOTE_TYPE.UP: {
			"position": Vector2(240, 240),
			"entry_angle": -180.0,
			"oscillation_frequency": 0.0,
			"distance": 880
		},
		HBNoteData.NOTE_TYPE.LEFT: {
			"position": Vector2(720, 768),
			"entry_angle": -180.0,
			"oscillation_frequency": 0.0,
			"distance": 880
		},
		HBNoteData.NOTE_TYPE.DOWN: {
			"position": Vector2(1200, 240),
			"entry_angle": -0.0,
			"oscillation_frequency": 0.0,
			"distance": 880
		},
		HBNoteData.NOTE_TYPE.RIGHT: {
			"position": Vector2(1680, 768),
			"entry_angle": -0.0,
			"oscillation_frequency": 0.0,
			"distance": 880
		}
	},
}

var default_templates := []
func _init():
	for name in DEFAULT_TEMPLATES.keys():
		var raw_template = DEFAULT_TEMPLATES[name]
		var template := HBEditorTemplate.new()
		
		template.name = name
		template.saved_properties = raw_template[0].keys()
		
		for note_type in raw_template:
			var note := HBNoteData.new()
			note.note_type = note_type
			
			for property in raw_template[note_type].keys():
				note[property] = raw_template[note_type][property]
			
			var note_ser = note.serialize()
			var note_copy = HBSerializable.deserialize(note_ser) as HBBaseNote
			
			template.set_type_template(note_copy)
		
		default_templates.append(template)
