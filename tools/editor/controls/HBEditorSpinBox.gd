extends SpinBox

class_name HBEditorSpinBox

signal input_accepted
signal input_rejected

func _input(event):
	if event.is_action_pressed("gui_accept") or event.is_action_pressed("gui_cancel"):
		if get_viewport().gui_get_focus_owner() == get_line_edit():
			apply()
			get_line_edit().release_focus()
			get_viewport().set_input_as_handled()
			
			if event.is_action_pressed("gui_accept"):
				emit_signal("input_accepted")
			else:
				emit_signal("input_rejected")
	
	if event is InputEventMouseButton and not get_global_rect().has_point(get_global_mouse_position()):
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			apply()
			get_line_edit().release_focus()
