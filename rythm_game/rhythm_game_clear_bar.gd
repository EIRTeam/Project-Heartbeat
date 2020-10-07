extends Panel
var value = 90.0 setget set_value
var max_value = 100.0 setget set_max_value
var potential_score = 0.0
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
	if max_value > 0:
		$PercentageLabel.text = "%.2f " % ((value / max_value) * 100.0)
		$PercentageLabel.text += "%"
func set_max_value(val):
	max_value = val
	update()
	
const CLEAR_POINT = 0.75
	
func apply_margin(rect: Rect2) -> Rect2:
	rect.position.y += 2
	rect.size.y -= 4
	return rect
	
func _draw():
	var origin = Vector2(0,0)
	var size = rect_size
	size.x = size.x * (value / max_value)
	var rect_clear = Rect2(Vector2(rect_size.x * CLEAR_POINT, 0), Vector2(rect_size.x * (1 - CLEAR_POINT), rect_size.y))
	
	rect_clear = apply_margin(rect_clear)
	draw_rect(rect_clear, CLEAR_COLOR)
	var progress_rect = Rect2(origin, size)
	#draw_rect(progress_rect, PROGRESS_COLOR)
	progress_rect = apply_margin(progress_rect)
	draw_style_box(preload("res://rythm_game/game_modes/heartbeat/ClearBar.tres"), progress_rect)
	
	var past_completion_size = rect_size
	past_completion_size.x = past_completion_size.x * ((value-(max_value*CLEAR_POINT)) / max_value)
	if past_completion_size.x > 0:
		var past_completion_progress_rect = Rect2(Vector2(rect_size.x * CLEAR_POINT, 0), past_completion_size)
		past_completion_progress_rect = apply_margin(past_completion_progress_rect)
		
		draw_style_box(preload("res://rythm_game/game_modes/heartbeat/ClearBarPost.tres"), past_completion_progress_rect)
	draw_rating_line(0.95)
	draw_rating_line(0.90)
	draw_rating_line(0.75)
	draw_line(origin+Vector2(rect_size.x * CLEAR_POINT, -12), origin+Vector2(rect_size.x * CLEAR_POINT, rect_size.y), Color.red, 3)
	$PercentageLabel.rect_position = Vector2(rect_size.x * CLEAR_POINT, 0)
	$PercentageLabel.rect_size = Vector2(rect_size.x * (1.0-CLEAR_POINT), rect_size.y)
func draw_rating_line(val, color=Color.white, height=10):
	var val_r = round(potential_score) / max_value
	var origin = Vector2(rect_size.x * (val_r * val), -height)
	var end = Vector2(origin.x, rect_size.y)
	draw_line(origin, end, color, 3)
