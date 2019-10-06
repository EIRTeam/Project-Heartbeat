extends StaticBody2D

var distance = 1400
var time_out = 1400

signal selected
signal moved
var grabbed_offset = Vector2()
var mouse_in = false
var is_grabbing = false
var pickable = true
var note_data: HBNoteData = HBNoteData.new()

func _draw():
	pass
#	draw_line(Vector2(0.0, 0.0), Vector2(400.0*distance/time_out, 0.0), Color("#FF0000"))

func _ready():
	note_data.connect("note_type_changed", self, "_on_note_type_changed")

func set_note_type(type):
	$Sprite.texture = HBNoteData.get_note_graphics(type).target

func _process(delta):
	if  Input.is_action_pressed("editor_select") and is_grabbing and pickable:
		global_position = get_global_mouse_position() + grabbed_offset
		emit_signal("moved")

func _unhandled_input(event):
	if event.is_action_pressed("editor_select") and pickable and mouse_in:
		emit_signal("selected")
		is_grabbing = true
		grabbed_offset = global_position - get_global_mouse_position()
		get_tree().set_input_as_handled()

func _input(event):
	if event.is_action_released("editor_select"):
		is_grabbing = false
func _on_NoteTarget_mouse_entered():
	mouse_in = true

func _on_NoteTarget_mouse_exited():
	mouse_in = false
