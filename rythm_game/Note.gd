extends Sprite

const trail_length = 200
var note_data: HBNoteData = HBNoteData.new()
var last_pos = Vector2()

func _ready():
	last_pos = position
	note_data.connect("note_type_changed", self, "_on_note_type_changed")
	_on_note_type_changed()
	
func _on_note_type_changed():
	texture = HBNoteData.get_note_graphics(note_data.note_type).note
func _physics_process(delta):
	
	for i in range($Line2D.get_point_count()):
		$Line2D.points[i] -= position - last_pos
	$Line2D.add_point(Vector2())
	while $Line2D.get_point_count() > trail_length:
		$Line2D.remove_point(0)

	last_pos = position


