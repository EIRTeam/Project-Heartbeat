extends Window

func _ready():
	hide()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			self.hide()
