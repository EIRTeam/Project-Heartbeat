extends Control

var length: float
var color: Color
var enabled := false

func set_enable_hack(_enabled: bool):
	enabled = _enabled
	update()

func run_uwu_hack(_length: float, _color: Color):
	length = _length
	color = _color
	update()

func _draw():
	if enabled:
		var y = rect_size.y / 2.0
		var start = Vector2(rect_size.x/2.0, y)
		var end = Vector2(-length+rect_size.x/2.0, y)
		draw_line(start, end, color, 1.0)
