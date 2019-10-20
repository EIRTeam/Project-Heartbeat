extends "res://rythm_game/NoteTarget.gd"

func set_note_type(type):
	$Sprite.texture = HBNoteData.get_note_graphics(type).hold_target
			
	$TimingArm.rotation_degrees = arm_position * 360
