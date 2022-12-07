extends NoteGraphics

func set_note_type(type, multi = false, double = false):
	texture = HBNoteData.get_note_graphic(type, "sustain_note")
