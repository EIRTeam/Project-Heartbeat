extends Tree

func _input(event):
	if event is InputEventMouseButton and not get_global_rect().has_point(get_global_mouse_position()):
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			release_focus()
