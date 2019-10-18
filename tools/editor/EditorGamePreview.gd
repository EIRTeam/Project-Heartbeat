extends Control

onready var widget_area = get_node("WidgetArea")

func _ready():
	$RythmGame.size = rect_size
	$RythmGame.editing = true
	$RythmGame.input_lag_compensation = 0.0
	connect("resized", self, "_on_resized")
	
func _on_resized():
	$RythmGame.size = rect_size
	update()
	
func _process(delta):
	$Label.text = HBUtils.format_time($RythmGame.time * 1000.0)

func _draw():
	var origin = $RythmGame.remap_coords(Vector2())
	var size = $RythmGame.get_playing_field_size()
	draw_rect(Rect2(origin, size), Color(1.0, 1.0, 1.0), false, 1.0, true)
