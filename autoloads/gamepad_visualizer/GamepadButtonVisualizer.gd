extends Panel

@export var button = 0
@export var device = 0

var prev_status = false

func _process(delta):
	var pressed = Input.is_joy_button_pressed(device, button)
	if pressed != prev_status:
		queue_redraw()
		prev_status = pressed
				
func _draw():
	if Input.is_joy_button_pressed(device, button):
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
	custom_minimum_size.x = size.y
