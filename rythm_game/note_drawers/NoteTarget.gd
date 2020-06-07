extends StaticBody2D

var arm_position = 0 setget set_arm_position
var arm2_position = 0 setget set_arm2_position

onready var progress_circle_rect = get_node("Node2D/TextureRect")

func set_arm_position(value):
	arm_position = value
	if UserSettings.user_settings.use_timing_arm:
		$TimingArm.rotation_degrees = 360 * value
	else:
		progress_circle_rect.value = arm_position
		progress_circle_rect.self_modulate.a = arm_position
			
func set_arm2_position(value):
	arm_position = value
	if UserSettings.user_settings.use_timing_arm:
		$TimingArm2.rotation_degrees = 360 * value
	else:
		progress_circle_rect.value = arm_position
		progress_circle_rect.self_modulate.a = arm_position



func set_note_type(note_data: HBBaseNote, multi = false):
	# set the texture to the correct one
	if note_data.get_serialized_type() == "SustainNote":
		$Sprite.texture = HBNoteData.get_note_graphics(note_data.note_type).sustain_target
	elif note_data.get_serialized_type() == "DoubleNote":
		$Sprite.texture = HBNoteData.get_note_graphics(note_data.note_type).double_target
	else:
		if multi:
			$Sprite.texture = HBNoteData.get_note_graphics(note_data.note_type).multi_note_target
			$Sprite/HoldTextSpriteMulti.visible = note_data.hold
		else:
			$Sprite/HoldTextSprite.visible = note_data.hold
			$Sprite.texture = HBNoteData.get_note_graphics(note_data.note_type).target
			
	var arm_disabled_types = [
		HBNoteData.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE,
		HBNoteData.NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE
	]
	if note_data.note_type in arm_disabled_types:
		$TimingArm.hide()
		progress_circle_rect.hide()
	else:
		if UserSettings.user_settings.use_timing_arm:
			$TimingArm.show()
			progress_circle_rect.hide()
			$TimingArm.rotation_degrees = arm_position * 360
			if note_data.get_serialized_type() == "SustainNote":
				$TimingArm2.show()
			else:
				$TimingArm2.hide()
		else:
			$TimingArm.hide()
			$TimingArm2.hide()
			progress_circle_rect.show()
			progress_circle_rect.tint_progress = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
	
