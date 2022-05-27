extends Control

onready var button_container: Control = get_node("AspectRatioContainer/TextureRect2")

onready var face_down_button: Control = get_node("AspectRatioContainer/TextureRect2/FaceDown")
onready var face_up_button: Control = get_node("AspectRatioContainer/TextureRect2/FaceUp")
onready var face_left_button: Control = get_node("AspectRatioContainer/TextureRect2/FaceLeft")
onready var face_right_button: Control = get_node("AspectRatioContainer/TextureRect2/FaceRight")

onready var pad_down_button: Control = get_node("AspectRatioContainer/TextureRect2/PadDown")
onready var pad_up_button: Control = get_node("AspectRatioContainer/TextureRect2/PadUp")
onready var pad_left_button: Control = get_node("AspectRatioContainer/TextureRect2/PadLeft")
onready var pad_right_button: Control = get_node("AspectRatioContainer/TextureRect2/PadRight")

onready var joystick_left_button: Control = get_node("AspectRatioContainer/TextureRect2/JoystickLeft")
onready var joystick_right_button: Control = get_node("AspectRatioContainer/TextureRect2/JoystickRight")

var are_buttons_hidden := false

func _ready():
	add_to_group("event_guide")
	hide_buttons()
func hide_buttons():
	if are_buttons_hidden == false:
		for button in button_container.get_children():
			button.hide()
		are_buttons_hidden = true
func show_notes(notes: Array):
	for button in button_container.get_children():
		button.hide()
	are_buttons_hidden = true
	if notes.size() > 0:
		are_buttons_hidden = false
		
	for i in range(notes.size()):
		var note := notes[i] as HBBaseNote
		match note.note_type:
			HBBaseNote.NOTE_TYPE.DOWN:
				face_down_button.show()
			HBBaseNote.NOTE_TYPE.UP:
				face_up_button.show()
			HBBaseNote.NOTE_TYPE.LEFT:
				face_left_button.show()
			HBBaseNote.NOTE_TYPE.RIGHT:
				face_right_button.show()
			HBBaseNote.NOTE_TYPE.HEART:
				joystick_left_button.show()
			HBBaseNote.NOTE_TYPE.SLIDE_LEFT, HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
				if joystick_left_button.visible:
					joystick_right_button.show()
				else:
					joystick_left_button.show()
		if note is HBDoubleNote:
			match note.note_type:
				HBBaseNote.NOTE_TYPE.DOWN:
					pad_down_button.show()
				HBBaseNote.NOTE_TYPE.UP:
					pad_up_button.show()
				HBBaseNote.NOTE_TYPE.LEFT:
					pad_left_button.show()
				HBBaseNote.NOTE_TYPE.RIGHT:
					pad_right_button.show()
				HBBaseNote.NOTE_TYPE.HEART:
					joystick_right_button.show()
			
