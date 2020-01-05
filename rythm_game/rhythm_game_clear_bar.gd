extends Panel
var value = 0.0 setget set_value
var max_value = 100.0 setget set_max_value
func set_value(val):
	value = val
	update()
	$Label.text = str((value / max_value) * 100.0)
func set_max_value(val):
	max_value = val
	update()
	
func _draw():
	var origin = Vector2(0,0)
	var size = rect_size
	size.x = size.x * (value / max_value)
	var rect = Rect2(origin, size)
	draw_rect(rect, Color.red)
	draw_rating_line(0.97)
	draw_rating_line(0.94)
	draw_rating_line(0.85)
	draw_line(origin+Vector2(rect_size.x * 0.85, 0), origin+Vector2(rect_size.x * 0.85, rect_size.y), Color.blue)
func draw_rating_line(val):
	var origin = Vector2(0, 0)
	var size = rect_size
	size.x = size.x * ((value * val) / max_value)
	draw_line(origin+Vector2(size.x, 0), origin+size, Color.green)	
