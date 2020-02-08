extends Panel
var value = 0.0 setget set_value
var max_value = 100.0 setget set_max_value

const PROGRESS_COLOR = Color("a877f0")
export(Color) var CLEAR_COLOR = Color("000")

func _ready():
	connect("resized", self, "_on_resized")
	_on_resized()
func _on_resized():
	update()

func set_value(val):
	value = val
	update()
	$PercentageLabel.text = "%.2f " % ((value / max_value) * 100.0)
	$PercentageLabel.text += "%"
func set_max_value(val):
	max_value = val
	update()
	
func _draw():
	var origin = Vector2(0,0)
	var size = rect_size
	size.x = size.x * (value / max_value)
	var rect = Rect2(origin, size)
	draw_rect(rect, PROGRESS_COLOR)
	draw_rating_line(0.97)
	draw_rating_line(0.94)
	draw_rating_line(0.85)
	var rect_clear = Rect2(Vector2(rect_size.x * 0.85, 0), Vector2(rect_size.x * (1 - 0.85), rect_size.y))
	draw_rect(rect_clear, CLEAR_COLOR)
	draw_line(origin+Vector2(rect_size.x * 0.85, -10), origin+Vector2(rect_size.x * 0.85, rect_size.y), PROGRESS_COLOR, 3)
	$PercentageLabel.rect_position = Vector2(rect_size.x * 0.85, 0)
	$PercentageLabel.rect_size = Vector2(rect_size.x * (1.0-0.85), rect_size.y)
func draw_rating_line(val):
	var val_r = round(value) / max_value
	var origin = Vector2(rect_size.x * (val_r * val), -10)
	var end = Vector2(origin.x, rect_size.y)
	draw_line(origin, end, Color.white, 3)
