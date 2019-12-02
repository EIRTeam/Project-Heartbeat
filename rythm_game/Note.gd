extends Sprite

var last_pos = Vector2()

func set_note_type(type, multi = false):
	if multi:
		texture = HBNoteData.get_note_graphics(type).multi_note
	else:
		texture = HBNoteData.get_note_graphics(type).note
