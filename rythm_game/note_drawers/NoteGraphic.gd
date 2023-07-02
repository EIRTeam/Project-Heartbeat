extends Sprite2D

class_name NoteGraphics

var last_pos = Vector2()

func set_note_type(type, multi = false, double = false):
	if double == true:
		texture = HBNoteData.get_note_graphic(type, "double_note")
	else:
		if multi:
			texture = HBNoteData.get_note_graphic(type, "multi_note")
		else:
			texture = HBNoteData.get_note_graphic(type, "note")
