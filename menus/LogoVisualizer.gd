extends Control

onready var bar_visualizer := get_node("AspectRatioContainer/BarVisualizer")
onready var logo_heart := get_node("Heart")
onready var heart_container := get_node("HBoxContainer/AspectRatioContainer2")

func _ready():
	connect("resized", self, "_on_resized")
	_on_resized()
	logo_heart.rect_scale = Vector2(0.5, 0.5)
	logo_heart.rect_pivot_offset = logo_heart.rect_size * 0.5
	bar_visualizer.inside_percentage = 0.4
func _on_resized():
	yield(get_tree(), "idle_frame")
	logo_heart.rect_pivot_offset = logo_heart.rect_size * 0.5
	bar_visualizer.rect_pivot_offset = bar_visualizer.rect_size * 0.5
	bar_visualizer.rect_scale = Vector2.ONE * 1.25

func _process(delta):
	var avg := 0.0
	
	var A = ceil(0.078125 * HBGame.spectrum_snapshot.definition)
	for i in range(A):
		avg += HBGame.spectrum_snapshot.get_value_at_i(i)
	avg /= float(A)
	logo_heart.rect_scale = logo_heart.rect_scale.linear_interpolate(Vector2.ONE * 0.5 + Vector2.ONE * range_lerp(avg, 0.0, 1.0, 0.0, 0.5), delta * 16)

func _draw():
	pass
