extends Control

class_name HBAnalogJoystickDebugDisplay

const DEADZONE_MAX := 1.0
const DEADZONE_INNER := 0.2
const DEADZONE_OUTER := 0.3
const ANGULAR_DEADZONE_SIDES := 90.0
const ANGULAR_DEADZONE_SIDES_INNER := 75.0

var last_inputs: Array[Vector2]

func _ready() -> void:
	last_inputs.resize(10)
	last_inputs.fill(Vector2.ZERO)

func _get_radius() -> float:
	return get_rect().size.x * 0.4

func _get_center() -> Vector2:
	return get_rect().size * 0.5
	
func display_input(vec: Vector2) -> void:
	last_inputs.push_back(vec)
	last_inputs.pop_front()
	queue_redraw()

func _draw_deadzone_circle(deadzone: float, color: Color):
	var radius := _get_radius()
	var center := _get_center()
	draw_arc(center, radius * deadzone, 0, TAU, 64, color, 3.0)

func _draw_point(point: Vector2, circle_radius: float, color: Color):
	var radius := _get_radius()
	var center := _get_center()
	draw_circle(point * radius + center, circle_radius, color)

func _draw_angular_deadzone(angle: float, color: Color):
	var right := Vector2(_get_radius(), 0.0)
	var center := _get_center()
	var p1 := center + right.rotated(angle*0.5)
	var p2 := center + right.rotated(angle*0.5 + PI)
	var p3 := center + right.rotated(angle*-0.5)
	var p4 := center + right.rotated(angle*-0.5 + PI)
	draw_line(p1, p2, color, 3.0, true)
	draw_line(p3, p4, color, 3.0, true)


func _draw() -> void:
	_draw_deadzone_circle(UserSettings.user_settings.direct_joystick_deadzone, Color.RED)
	_draw_deadzone_circle(UserSettings.user_settings.direct_joystick_deadzone - 0.1, Color.GREEN)
	_draw_deadzone_circle(DEADZONE_MAX, Color.BLACK)
	_draw_angular_deadzone(deg_to_rad(UserSettings.user_settings.direct_joystick_slider_angle_window), Color.BLUE_VIOLET)
	for input in last_inputs:
		_draw_point(input, 5.0, Color.BLUE)
