extends Control

var length: float
var color: Color
var enabled := false

func set_enable_hack(_enabled: bool):
	enabled = _enabled
	queue_redraw()

func run_uwu_hack(_length: float, _color: Color):
	length = _length
	color = _color
	queue_redraw()

func _draw():
	if enabled:
		var width = 5
		
		var y = (size.y - width)/2
		var start = Vector2(size.x/2.0, y)
		var size = Vector2(-length, width)
		
		draw_rect(Rect2(start, size), color)
