extends MultiSpinBox

class_name HBEditorMultiSpinBox

func _ready():
	connect("error_changed", self, "_on_error")

func _input(event):
	if event is InputEventMouseButton and not get_global_rect().has_point(get_global_mouse_position()):
		if event.button_index == BUTTON_LEFT and event.pressed:
			if get_line_edit().has_focus():
				reset_expression()

func _on_error(error_text):
	hint_tooltip = error_text
