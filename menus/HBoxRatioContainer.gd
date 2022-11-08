tool
extends HBoxContainer

class_name HBoxRatioContainer

func _ready():
	for c in get_children():
		if c is HBEditorButton:
			c.connect("min_x_size_changed", self, "update_min_size")
	
	update_min_size()

func update_min_size():
	var max_width = 0
		
	for c in get_children():
		var c_min_width = c.rect_min_size.x
		max_width = max(max_width, c_min_width)
	
	for c in get_children():
		c.rect_min_size.x = max_width
