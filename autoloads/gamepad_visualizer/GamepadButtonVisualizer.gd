extends Panel

export var button = 0
export var device = 0

var prev_status = false

func _process(delta):
	var pressed = Input.is_joy_button_pressed(device, button)
	if pressed != prev_status:
		update()
		prev_status = pressed
				
func _draw():
	if Input.is_joy_button_pressed(device, button):
		draw_rect(Rect2(Vector2.ZERO, rect_size), Color.white)
	rect_min_size.x = rect_size.y
