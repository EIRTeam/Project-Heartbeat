extends Sprite

const trail_length = 200
var note_data: HBNoteData

func _ready():
	texture = HBNoteData.get_note_graphics(note_data.note_type).note

func _physics_process(delta):
	$Node/Line2D.add_point(global_position)
	while $Node/Line2D.get_point_count() > trail_length:
		$Node/Line2D.remove_point(0)
	position.x += 50*delta
	position.y += 50*delta
