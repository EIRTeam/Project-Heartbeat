extends Control

@onready var bar_visualizer := get_node("AspectRatioContainer/BarVisualizer")
@onready var logo_heart := get_node("Heart")
@onready var tween_appear := Threen.new()
@onready var tween_disappear := Threen.new()

func _ready():
	add_child(tween_appear)
	add_child(tween_disappear)
	tween_disappear.connect("tween_all_completed", Callable(self, "_disable"))
	connect("resized", Callable(self, "_on_resized"))
	logo_heart.connect("resized", Callable(self, "_on_heart_resized"))
	call_deferred("_on_resized")
	modulate.a = 0.0
#	logo_heart.rect_scale = Vector2(0.5, 0.5)
#	logo_heart.rect_pivot_offset = logo_heart.rect_size * 0.5
#	bar_visualizer.inside_percentage = 0.5
func _on_resized():
	bar_visualizer.pivot_offset = bar_visualizer.size * 0.5

func _on_heart_resized():
	logo_heart.pivot_offset = logo_heart.size * 0.5

func _process(delta):
	var avg := 0.0
	
	var A = ceil(0.078125 * HBGame.spectrum_snapshot.definition)
	for i in range(A):
		avg += HBGame.spectrum_snapshot.get_value_at_i(i)
	avg /= float(A)
	logo_heart.scale = logo_heart.scale.lerp(Vector2.ONE * 0.5 + Vector2.ONE * remap(avg, 0.0, 1.0, 0.0, 0.5), delta * 16)
func _draw():
	pass

func _disable():
	bar_visualizer.set_process(false)
	set_process(false)

func appear():
	bar_visualizer.set_process(true)
	set_process(true)
	tween_disappear.stop_all()
	tween_appear.remove_all()
	tween_appear.interpolate_property(self, "modulate:a", modulate.a, 1.0, 0.25)
	tween_appear.start()

func disappear():
	tween_appear.stop_all()
	tween_disappear.remove_all()
	tween_disappear.interpolate_property(self, "modulate:a", modulate.a, 0.0, 0.15)
	tween_disappear.start()
	
