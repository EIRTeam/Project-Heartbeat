extends LineEdit

signal accepted()
signal rejected()

func _gui_input(event):
	if event.is_action_pressed("gui_accept"):
		emit_signal("accepted")
	
	if event.is_action_pressed("gui_cancel"):
		emit_signal("rejected")
