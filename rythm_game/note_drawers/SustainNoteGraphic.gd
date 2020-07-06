extends Sprite

var last_pos = Vector2()

func set_note_type(type, multi = false, double = false):
	texture = HBNoteData.get_note_graphic(type, "sustain_note")
