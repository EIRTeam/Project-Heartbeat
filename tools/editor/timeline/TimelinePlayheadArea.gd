extends Panel

signal mouse_x_input(value)
signal double_click()

var double_click_timer := Timer.new()

func _ready():
	add_child(double_click_timer)
	double_click_timer.one_shot = true

func _gui_input(event):
	if Input.is_action_pressed("editor_select", true):
		if get_local_mouse_position().y > 0 and get_local_mouse_position().y < rect_size.y / 2 and \
			Input.is_action_just_pressed("editor_select", true):
			if double_click_timer.is_stopped():
				double_click_timer.start(0.25)
			else:
				emit_signal("double_click")
				double_click_timer.stop()
				get_tree().set_input_as_handled()
		else:
			emit_signal("mouse_x_input", (get_viewport().get_mouse_position() - rect_global_position).x)
			get_tree().set_input_as_handled()
