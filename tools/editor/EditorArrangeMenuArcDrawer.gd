extends Control

var mouse_distance: int
var rotation: float

func _draw():
	if mouse_distance > 70:
		_draw_arc(61, 69, 0, rotation, Color(255, 0, 0, 0.7).lightened(0.6), Color.red)
	elif mouse_distance > 44:
		_draw_arc(44, 61, 0, rotation, Color(255, 0, 0, 0.7).lightened(0.5), Color.red)
	else:
		_draw_arc(29, 37, 0, rotation, Color(255, 0, 0, 0.7).lightened(0.5), Color.red)

func _draw_arc(radius_from, radius_to, angle_from, angle_to, color: Color, line_color: Color):
	var n_points = 32
	var points_arc = PoolVector2Array()
	var colors = PoolColorArray([color])
	
	var angle_diff = angle_to - angle_from
	for i in range(n_points + 1):
		var point = angle_from + i * angle_diff / n_points
		points_arc.push_back(Vector2(cos(point), sin(point)) * radius_from)
	
	for i in range(n_points, -1, -1):
		var point = angle_from + i * angle_diff / n_points
		points_arc.push_back(Vector2(cos(point), sin(point)) * radius_to)
	
	draw_line(Vector2.ZERO, Vector2(cos(angle_to), sin(angle_to)) * radius_to, line_color, 2)
	
	draw_polygon(points_arc, colors)