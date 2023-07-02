extends Control

const INNER_RING_RADIUS = [29, 37]
const MIDDLE_RING_RADIUS = [44, 61]
const OUTER_RING_RADIUS = [61, 69]

var mouse_distance: int
var arc_rotation: float

func _draw():
	if mouse_distance > 70:
		_draw_arc(OUTER_RING_RADIUS[0], OUTER_RING_RADIUS[1], 0, arc_rotation, Color(255, 0, 0, 0.7).lightened(0.6), Color.RED)
	elif mouse_distance > 44:
		_draw_arc(MIDDLE_RING_RADIUS[0], MIDDLE_RING_RADIUS[1], 0, arc_rotation, Color(255, 0, 0, 0.7).lightened(0.5), Color.RED)
	else:
		_draw_arc(INNER_RING_RADIUS[0], INNER_RING_RADIUS[1], 0, arc_rotation, Color(255, 0, 0, 0.7).lightened(0.5), Color.RED)

func _draw_arc(radius_from, radius_to, angle_from, angle_to, color: Color, line_color: Color):
	var n_points = 32
	var points_arc = PackedVector2Array()
	var colors = PackedColorArray([color])
	
	var angle_diff = angle_to - angle_from
	for i in range(n_points + 1):
		var point = angle_from + i * angle_diff / n_points
		points_arc.push_back(Vector2(cos(point), sin(point)) * radius_from)
	
	for i in range(n_points, -1, -1):
		var point = angle_from + i * angle_diff / n_points
		points_arc.push_back(Vector2(cos(point), sin(point)) * radius_to)
	
	draw_line(Vector2.ZERO, Vector2(cos(angle_to), sin(angle_to)) * radius_to, line_color, 2)
	
	draw_polygon(points_arc, colors)
