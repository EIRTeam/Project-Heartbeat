extends Sprite

const trail_length = 200
var last_pos = Vector2()

func _ready():
	last_pos = position
	
func set_note_type(type):
	texture = HBNoteData.get_note_graphics(type).note
	
func _physics_process(delta):
	if position != last_pos:
		for i in range($Line2D.get_point_count()):
			$Line2D.points[i] -= position - last_pos
		$Line2D.add_point(Vector2())
		while $Line2D.get_point_count() > trail_length:
			$Line2D.remove_point(0)
		last_pos = position

