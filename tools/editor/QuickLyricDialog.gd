extends WindowDialog


func _unhandled_input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE and event.pressed:
			self.hide()
