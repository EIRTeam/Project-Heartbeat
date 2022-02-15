extends TextureRect

export(HBBaseNote.NOTE_TYPE) var note_type := HBBaseNote.NOTE_TYPE.UP
export(String, "note", "double_note") var note_variant := "note"

func _ready():
	texture = HBBaseNote.get_note_graphic(note_type, note_variant) 
