extends LineEdit

class_name HBEditorLineEdit

signal text_accepted()

func _input(event):
	if event.is_action_pressed("gui_accept") or event.is_action_pressed("gui_cancel"):
		if get_focus_owner() == self:
			emit_signal("text_entered", text)
			emit_signal("text_accepted")
			release_focus()
	
	if event is InputEventMouseButton and not get_global_rect().has_point(get_global_mouse_position()):
		if get_focus_owner() == self:
			if event.button_index == BUTTON_LEFT and event.pressed:
				emit_signal("text_entered", text)
				release_focus()
