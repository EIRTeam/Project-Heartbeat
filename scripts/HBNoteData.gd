extends HBTimingPoint

class_name HBNoteData

enum NOTE_TYPE {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

export (NOTE_TYPE) var note_type = NOTE_TYPE.RIGHT

var position: Vector2 = Vector2(0.5, 0.5)
var time_out: int = 1500 # time where the note target starts being visible
func _init():
	serializable_fields += ["position", "time_out", "note_type"]

func get_serialized_type():
	return "Note"
