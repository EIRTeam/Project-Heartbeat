extends StaticBody2D

var distance = 1400
var time_out = 1400

signal selected

var note_data: HBNoteData = HBNoteData.new()
var arm_position = 0 setget set_arm_position
var mouse_in = false

func set_arm_position(value):
	arm_position = value
	$TimingArm.rotation_degrees = clamp(360 * value, 0, 360)

func _draw():
	pass
#	draw_line(Vector2(0.0, 0.0), Vector2(400.0*distance/time_out, 0.0), Color("#FF0000"))

func _ready():
	note_data.connect("note_type_changed", self, "_on_note_type_changed")

func set_note_type(type, multi = false):
	if multi:
		$Sprite.texture = HBNoteData.get_note_graphics(type).multi_note_target
	else:
		$Sprite.texture = HBNoteData.get_note_graphics(type).target
			
	$TimingArm.rotation_degrees = arm_position * 360
func _unhandled_input(event):
	if event.is_action_pressed("editor_select") and input_pickable and mouse_in:
		emit_signal("selected")
		get_tree().set_input_as_handled()
func _on_NoteTarget_mouse_entered():
	mouse_in = true

func _on_NoteTarget_mouse_exited():
	mouse_in = false
