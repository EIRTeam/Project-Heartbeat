@tool
extends Control

@export var start_angle: float = 0.0: set = set_start_angle
@export var end_angle: float = 0.0: set = set_end_angle

signal angle_changed(value)
signal angle_finished_changing

func set_start_angle(value):
	start_angle = value
	queue_redraw()

func set_end_angle(value):
	end_angle = value
	queue_redraw()

func _init():
	start_angle = 0

func _gui_input(event):
	if not Engine.is_editor_hint():
		if Input.is_action_pressed("editor_select"):
			get_viewport().set_input_as_handled()
			
			var center = size / 2
			var angle_to_center = round(rad_to_deg(center.angle_to_point(get_local_mouse_position())) - 180)
			
			set_start_angle(angle_to_center)
			set_end_angle(angle_to_center)
			
			emit_signal("angle_changed", angle_to_center)
		if Input.is_action_just_released("editor_select"):
			emit_signal("angle_finished_changing")

func _draw():
	var center = size / 2
	var radius = min(size.y, size.x) / 2
	
	draw_circle(center, radius, Color.BLACK)
	
	draw_line(center, center + Vector2.RIGHT.rotated(deg_to_rad(start_angle)) * radius, Color.WHITE)
	draw_line(center, center + Vector2.RIGHT.rotated(deg_to_rad(end_angle)) * radius, Color.WHITE)
	var color = Color.GRAY
	color.a = 0.7
	_draw_arc(0, radius, deg_to_rad(start_angle), deg_to_rad(end_angle), color, Color.WHITE)

func _draw_arc(radius_from, radius_to, angle_from, angle_to, color: Color, line_color: Color):
	var n_points = 32.0
	var points_arc = PackedVector2Array()
	var colors = PackedColorArray([color])
	
	for i in range(n_points + 1):
		var point = lerp_angle(angle_from, angle_to, i * 1 / n_points)
		points_arc.push_back(size / 2 + Vector2(cos(point), sin(point)) * radius_from)
	
	for i in range(n_points, -1, -1):
		var point = lerp_angle(angle_from, angle_to, i * 1 / n_points)
		points_arc.push_back(size / 2 + Vector2(cos(point), sin(point)) * radius_to)
	
	draw_polygon(points_arc, colors)
