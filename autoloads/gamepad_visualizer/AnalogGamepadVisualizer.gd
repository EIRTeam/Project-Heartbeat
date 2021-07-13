extends Panel

export var axis_x = 0
export var axis_y = 0
export var device = 0

var pos = Vector2.ZERO

func _input(event):
	if event is InputEventJoypadMotion:
		
		if event.device == device:
			if event.axis == axis_x:
				pos.x = Input.get_joy_axis(device, event.axis)
			if event.axis == axis_y:
				pos.y = Input.get_joy_axis(device, event.axis)
			update()
func _draw():
	var col = Color.white
	col.a = 0.5
	var deadzone = UserSettings.user_settings.analog_deadzone
	var starting_pos = (1.0 - deadzone) * rect_size / 2.0
	
	if axis_x <= JOY_AXIS_3 and axis_y <= JOY_AXIS_3 and UserSettings.should_use_direct_joystick_access():
		draw_circle(rect_size / 2.0, deadzone * rect_size.x / 2.0, col)
		draw_circle((pos * rect_size / 2) + rect_size / 2, 2, Color.white)
	else:
		var size = deadzone * rect_size
		draw_rect(Rect2(starting_pos, size), col)

		draw_circle((pos * rect_size / 2) + rect_size / 2, 2, Color.white)
