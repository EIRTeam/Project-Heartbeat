extends Panel

@export var axis = 0
@export var device = 0

var value = 0.0

func _input(event):
	if event is InputEventJoypadMotion:
		if event.device == device:
			if event.axis == axis:
				value = Input.get_joy_axis(device, event.axis)
			queue_redraw()

func _draw():
	var s = size
	s.x *= value
	var rect = Rect2(Vector2.ZERO, s)
	draw_rect(rect, Color.WHITE)
