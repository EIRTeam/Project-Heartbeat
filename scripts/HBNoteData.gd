extends HBTimingPoint

class_name HBNoteData

enum NOTE_TYPE {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

const NOTE_GRAPHICS = {
	NOTE_TYPE.UP: {
		"note": preload("res://graphics/notes/xbox/Y.png"),
		"target": preload("res://graphics/notes/xbox/Y_target.png")
	},
	NOTE_TYPE.DOWN: {
		"note": preload("res://graphics/notes/xbox/A.png"),
		"target": preload("res://graphics/notes/xbox/A_target.png")
	},
	NOTE_TYPE.LEFT: {
		"note": preload("res://graphics/notes/xbox/X.png"),
		"target": preload("res://graphics/notes/xbox/X_target.png")
	},
	NOTE_TYPE.RIGHT: {
		"note": preload("res://graphics/notes/xbox/B.png"),
		"target": preload("res://graphics/notes/xbox/B_target.png")
	}
}

export (NOTE_TYPE) var note_type = NOTE_TYPE.RIGHT

var position: Vector2 = Vector2(0.5, 0.5)
var time_out: int = 1000 # time where the note target starts being visible
func _init():
	serializable_fields += ["position", "time_out", "note_type"]

func get_serialized_type():
	return "Note"


static func get_note_graphics(note_type):
	return NOTE_GRAPHICS[note_type]
