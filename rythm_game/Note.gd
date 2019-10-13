extends Sprite

var last_pos = Vector2()

func set_note_type(type):
	texture = HBNoteData.get_note_graphics(type).note
