extends SubViewport

var base_size: Vector2

func _on_window_size_changed():
	var window_size := get_window().size
	var new_size_y := (window_size.y / 1080.0) * base_size.y
	var new_size_x := new_size_y * (base_size.x / base_size.y)
	size = Vector2(new_size_x, new_size_y)
	var scale_factor = new_size_x / base_size.x
	get_child(0).scale = Vector2(scale_factor, scale_factor)
func _ready():
	base_size = size
	get_window().size_changed.connect(self._on_window_size_changed)
