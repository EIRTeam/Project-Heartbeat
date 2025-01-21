extends Container

@export var target_size: Vector2

func _ready() -> void:
	sort_children.connect(self._on_sort_children)

func _on_sort_children():
	for child: Control in get_children():
		if not child:
			continue
		child.size = target_size
		child.position = Vector2.ZERO

		var target_ratio := target_size.aspect()
		var actual_ratio := size.aspect()
		
		var new_scale := 0.0
		
		if target_ratio > actual_ratio:
			# We must fit it with vertical offset
			new_scale = size.x / child.size.x
			var new_size := target_size * new_scale
			child.position.y = (size.y - new_size.y) * 0.5
		else:
			new_scale = size.y / child.size.y
			var new_size := target_size * new_scale
			child.position.x = (size.x - new_size.x) * 0.5
		
		child.scale = Vector2(new_scale, new_scale)
