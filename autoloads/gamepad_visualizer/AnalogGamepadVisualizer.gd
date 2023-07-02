extends Panel

@export var axis_x = 0
@export var axis_y = 0
@export var device = 0

var pos = Vector2.ZERO

func _input(event):
	if event is InputEventJoypadMotion:
		
		if event.device == device:
			if event.axis == axis_x:
				pos.x = Input.get_joy_axis(device, event.axis)
			if event.axis == axis_y:
				pos.y = Input.get_joy_axis(device, event.axis)
			queue_redraw()
func _draw():
	var col = Color.WHITE
	col.a = 0.5
	var deadzone = UserSettings.user_settings.analog_deadzone
	var starting_pos = (1.0 - deadzone) * size / 2.0
	
	if axis_x <= JOY_AXIS_RIGHT_Y and axis_y <= JOY_AXIS_RIGHT_Y and UserSettings.should_use_direct_joystick_access():
		draw_circle(size / 2.0, deadzone * size.x / 2.0, col)
		draw_circle((pos * size / 2) + size / 2, 2, Color.WHITE)
	else:
		var size = deadzone * size
		draw_rect(Rect2(starting_pos, size), col)

		draw_circle((pos * size / 2) + size / 2, 2, Color.WHITE)
