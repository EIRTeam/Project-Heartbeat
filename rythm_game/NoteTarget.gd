extends Sprite

var distance = 1400
var time_out = 1400
var type : int = 0
func _draw():
	draw_line(Vector2(0.0, 0.0), Vector2(400.0*distance/time_out, 0.0), Color("#FF0000"))

func _ready():
	texture = HBNoteData.get_note_graphics(type).target
