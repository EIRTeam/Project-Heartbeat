extends ColorPickerButton

class_name HBEditorColorPickerButton

signal input_accepted
signal input_rejected

func _input(event):
	if get_popup().visible:
		if event.is_action_pressed("gui_accept"):
			get_popup().visible = false
			emit_signal("input_accepted")
		
		if event.is_action_pressed("gui_cancel"):
			get_popup().visible = false
			emit_signal("input_rejected")
		
		if event is InputEventMouseButton and not get_popup().get_global_rect().has_point(get_global_mouse_position()):
			if event.button_index == BUTTON_LEFT and event.pressed:
				get_popup().visible = false
				emit_signal("input_rejected")
