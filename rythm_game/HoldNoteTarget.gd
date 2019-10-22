extends "res://rythm_game/NoteTarget.gd"
var arm_position_2 = 0.0 setget set_arm_position_2

func set_arm_position_2(value):
	arm_position_2 = value
	$TimingArm2.rotation_degrees = clamp(360 * value, 0, 360)

func set_note_type(type):
	$Sprite.texture = HBNoteData.get_note_graphics(type).hold_target
