extends Container

class_name HBRadialContainer

func _ready() -> void:
	sort_children.connect(_on_sort_children_requested)

func _on_sort_children_requested():
	var starting_angle := deg_to_rad(0.0)
	var rect := get_rect()
	var radius := rect.size[rect.size.min_axis_index()] * 0.5
	var center := rect.size * 0.5
	var angle_step := TAU / float(get_child_count())
	
	var radial_margin := get_theme_constant(&"radial_margin", &"HBRadialContainer")
	
	for child: Control in get_children():
		if not child:
			return
		child.size = child.get_combined_minimum_size()
		var child_size := child.size
		var child_radius := child.size[child.size.max_axis_index()] * 0.5
		var child_idx := child.get_index()
		var angle := child_idx * angle_step
		
		child.position = center + (Vector2.UP * (radius - child_radius - radial_margin)).rotated(angle_step * child_idx) - (child.size * 0.5)
		
func _draw() -> void:
	var rect := get_rect()
	var radius := rect.size[rect.size.min_axis_index()] * 0.5
	var center := rect.size * 0.5
	draw_circle(center, radius, Color.REBECCA_PURPLE)
