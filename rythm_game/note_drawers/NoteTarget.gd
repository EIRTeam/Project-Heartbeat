extends Node2D

class_name NoteTarget

var arm_position = 0: set = set_arm_position
var arm2_position = 0: set = set_arm2_position

@onready var progress_circle_rect = get_node("Node2D/TextureRect")

func set_arm_position(value):
	arm_position = value
	if UserSettings.user_settings.use_timing_arm:
		pass
		$TimingArm.rotation_degrees = 360 * value
	else:
		if arm2_position == 0.0:
			progress_circle_rect.value = arm_position
			progress_circle_rect.self_modulate.a = arm_position
func set_arm2_position(value):
	arm2_position = value
	if UserSettings.user_settings.use_timing_arm:
		$TimingArm2.rotation_degrees = 360 * value
	else:
		if arm2_position != 0.0:
			progress_circle_rect.value = arm2_position
			progress_circle_rect.self_modulate.a = arm2_position

func _ready():
	$TimingArm.texture = ResourcePackLoader.get_graphic("timing_arm.png")
	$TimingArm2.texture = ResourcePackLoader.get_graphic("timing_arm.png")

func set_note_type(note_data: HBBaseNote, multi = false, blue=false):
	# set the texture to the correct one
	if note_data.get_serialized_type() == "SustainNote":
		$Sprite2D.texture = HBNoteData.get_note_graphic(note_data.note_type ,"sustain_note_target")
	elif note_data.get_serialized_type() == "DoubleNote":
		$Sprite2D.texture = HBNoteData.get_note_graphic(note_data.note_type, "double_note_target")
	else:
		if blue:
			$Sprite2D.texture = HBNoteData.get_note_graphic(note_data.note_type, "target_blue")
		elif multi:
			$Sprite2D.texture = HBNoteData.get_note_graphic(note_data.note_type, "multi_note_target")
			$Sprite2D/HoldTextSprite.texture = ResourcePackLoader.get_graphic("hold_text_multi.png")
			$Sprite2D/HoldTextSprite.visible = note_data.hold
		else:
			$Sprite2D/HoldTextSprite.visible = note_data.hold
			$Sprite2D/HoldTextSprite.texture = ResourcePackLoader.get_graphic("hold_text.png")
			$Sprite2D.texture = HBNoteData.get_note_graphic(note_data.note_type, "target")
			
	var arm_disabled_types = [
		HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT,
		HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT
	]
	if note_data.note_type in arm_disabled_types:
		$TimingArm.hide()
		$TimingArm2.hide()
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
			progress_circle_rect.tint_progress = ResourcePackLoader.get_note_trail_color(note_data.note_type)
	
