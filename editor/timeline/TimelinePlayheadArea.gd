extends Panel
signal mouse_x_input(value)
	
func _gui_input(event):
	if Input.is_action_pressed("editor_select"):
		emit_signal("mouse_x_input", (get_viewport().get_mouse_position() - rect_global_position).x)
