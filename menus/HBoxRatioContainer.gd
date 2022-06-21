tool
extends HBoxContainer

class_name HBoxRatioContainer

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		# Must re-sort the children
		var max_width = 0
		
		for c in get_children():
			var c_min_width = c.rect_min_size.x
			max_width = max(max_width, c_min_width)
		
		var width = max_width * get_child_count()
		var separation_width = get_constant("separation") * (get_child_count() - 1)
		rect_min_size = Vector2(width + separation_width, rect_min_size.y)
