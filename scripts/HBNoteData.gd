extends HBTimingPoint

class_name HBNoteData

enum NOTE_TYPE {
	UP,
	DOWN,
	LEFT,
	RIGHT
}
export (NOTE_TYPE) var note_type := NOTE_TYPE.RIGHT setget set_note_type

signal note_type_changed

func set_note_type(value):
	note_type = value
	emit_signal("note_type_changed")

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


var position: Vector2 = Vector2(0.5, 0.5) # Position goes from 0 to 1, in a 16:9 play area
var time_out: int = 1400 # time where the note target starts being visible
func _init():
	serializable_fields += ["position", "time_out", "note_type"]

func get_serialized_type():
	return "Note"


static func get_note_graphics(note_type):
	return NOTE_GRAPHICS[note_type]
