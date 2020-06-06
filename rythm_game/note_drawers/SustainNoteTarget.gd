extends "NoteTarget.gd"

func set_note_type(type, multi = false, hold = true, double = false):
	.set_note_type(type, multi, hold, double)
	$Sprite.texture = HBNoteData.get_note_graphics(type).sustain_target
 
