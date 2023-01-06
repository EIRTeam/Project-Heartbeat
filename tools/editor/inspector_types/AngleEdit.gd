tool
extends Control

export(float) var start_angle = 0.0 setget set_start_angle
export(float) var end_angle = null setget set_end_angle

signal angle_changed(value)
signal angle_finished_changing

func set_start_angle(value):
	start_angle = value
	update()

func set_end_angle(value):
	end_angle = value
	update()

func _init():
	start_angle = 0
	end_angle = null

func _gui_input(event):
	if not Engine.editor_hint:
		if Input.is_action_pressed("editor_select"):
			get_tree().set_input_as_handled()
			
			var center = rect_size / 2
			var angle_to_center = round(rad2deg(center.angle_to_point(get_local_mouse_position())) - 180)
			
			set_start_angle(angle_to_center)
			if end_angle != null:
				set_end_angle(angle_to_center)
			
			emit_signal("angle_changed", angle_to_center)
		if Input.is_action_just_released("editor_select"):
			emit_signal("angle_finished_changing")

func _draw():
	var center = rect_size / 2
	var radius = min(rect_size.y, rect_size.x) / 2
	
	draw_circle(center, radius, Color.black)
	
	draw_line(center, center + Vector2.RIGHT.rotated(deg2rad(start_angle)) * radius, Color.white)
	if end_angle != null:
		draw_line(center, center + Vector2.RIGHT.rotated(deg2rad(end_angle)) * radius, Color.white)
		var color = Color.gray
		color.a = 0.7
		_draw_arc(0, radius, deg2rad(start_angle), deg2rad(end_angle), color, Color.white)

func _draw_arc(radius_from, radius_to, angle_from, angle_to, color: Color, line_color: Color):
	var n_points = 32.0
	var points_arc = PoolVector2Array()
	var colors = PoolColorArray([color])
	
	for i in range(n_points + 1):
		var point = lerp_angle(angle_from, angle_to, i * 1 / n_points)
		points_arc.push_back(rect_size / 2 + Vector2(cos(point), sin(point)) * radius_from)
	
	for i in range(n_points, -1, -1):
		var point = lerp_angle(angle_from, angle_to, i * 1 / n_points)
		points_arc.push_back(rect_size / 2 + Vector2(cos(point), sin(point)) * radius_to)
	
	draw_polygon(points_arc, colors)
