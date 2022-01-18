extends TextEdit

class_name HBEditorTextEdit

func _input(event):
	if event.is_action_pressed("gui_accept") or event.is_action_pressed("gui_cancel"):
		release_focus()
	
	if event is InputEventMouseButton and not get_global_rect().has_point(get_global_mouse_position()):
		if event.button_index == BUTTON_LEFT and event.pressed:
			release_focus()
