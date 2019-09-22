extends Control

const SCALE = 30.0 # Seconds per 500 pixels

func _ready():
	update()
	
func _draw():
	_draw_playhead()
	
func _draw_playhead():
	var playhead_position = 20 # seconds
	var playhead_pos = Vector2(10.0, 0.0)
	draw_line(playhead_pos, playhead_pos+Vector2(0.0, rect_size.y), Color(1.0, 0.0, 0.0), 1.0)
