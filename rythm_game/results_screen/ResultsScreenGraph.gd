extends Control

var value_max = 100.0
var value_min = 0.0

var value_max_y = 100.0

var _draw_points_internal = PackedVector2Array()

const X_MARGIN = 0

const fnt = preload("res://fonts/new_fonts/roboto_black_35.tres")

@onready var point_nodes_node = get_node("PointNodes")

var points = [
	Vector2(0, 10),
	Vector2(10, 20),
	Vector2(20, 30),
	Vector2(30, 30),
	Vector2(50, 50),
	Vector2(60, 80),
	Vector2(100, 90),
] : set = set_points

var dots = [
] : set = set_dots

const DOT_TEXTURE = preload("res://graphics/graph_dot.png")

func set_dots(val):
	dots = val
	queue_redraw()

func set_points(val):
	points = val
	queue_redraw()

func _ready():
	pass
	
	
func val_to_rect_pos(val: Vector2):
	val.x /= value_max
	val.y /= value_max_y
	val *=  size - Vector2(X_MARGIN, 0)
	val.x += X_MARGIN
	val.y = size.y - val.y
	return val
	
func draw_rating_rects():
	var pass_line_color = Color.WHITE
	var pass_line_rect_color = Color.WHITE
	pass_line_rect_color.a = 0.2
	
	var great_line_color = Color.LAWN_GREEN
	var great_line_rect_color = Color.LAWN_GREEN
	great_line_rect_color.a = 0.2
	
	var excellent_line_color = Color.GOLD
	var excellent_line_rect_color = Color.GOLD
	excellent_line_rect_color.a = 0.2
	
	var excellent_y = size.y - ((HBGame.EXCELLENT_THRESHOLD * 100.0 / value_max_y) * size.y)
	var great_y = size.y - ((HBGame.GREAT_THRESHOLD * 100.0 / value_max_y) * size.y)
	var pass_y = size.y - ((HBGame.PASS_THRESHOLD * 100.0 / value_max_y) * size.y)
	
	# pass rect
	draw_rect(Rect2(Vector2(X_MARGIN, great_y), Vector2(size.x - X_MARGIN, pass_y - great_y)), pass_line_rect_color)
	draw_rect(Rect2(Vector2(X_MARGIN, excellent_y), Vector2(size.x - X_MARGIN, great_y - excellent_y)), great_line_rect_color)
	draw_rect(Rect2(Vector2(X_MARGIN, 0), Vector2(size.x - X_MARGIN, excellent_y)), excellent_line_rect_color)
	draw_line(Vector2(0, great_y), Vector2(size.x, great_y), great_line_color, 5.0)
	
	draw_line(Vector2(0, excellent_y), Vector2(size.x, excellent_y), excellent_line_color, 5.0)
	
	draw_line(Vector2(0, pass_y), Vector2(size.x, pass_y), pass_line_color, 5.0)
	
	draw_string(fnt, Vector2(30, great_y), "GREAT", great_line_color)
	draw_string(fnt, Vector2(30, excellent_y), "EXCELLENT", excellent_line_color)
	draw_string(fnt, Vector2(30, pass_y), "PASS", pass_line_color)
	
func _draw():
	
	var colors = []
	_draw_points_internal = PackedVector2Array(points)
	var col = Color.ROYAL_BLUE
	col.a = 0.25
	var max_x = 0
	for i in range(_draw_points_internal.size()):
		colors.append(col)
		_draw_points_internal[i] = val_to_rect_pos(_draw_points_internal[i])
		max_x = max(max_x, _draw_points_internal[i].x)
	_draw_points_internal.append(Vector2(max_x, size.y))
	_draw_points_internal.append(Vector2(0, size.y))
	var col_w = Color.POWDER_BLUE
	col_w.a = 0.0
	colors.append(col_w)
	colors.append(col_w)

	var line_c = Color.WHITE
	line_c.a = 0.1

	for i in range(10):
		var y = ((((i + 1) / 10.0) * 100.0) / value_max_y) * size.y
		draw_line(Vector2(X_MARGIN, y), Vector2(size.x, y), line_c, 3.0)


	draw_polygon(_draw_points_internal, colors)

	_draw_points_internal.remove(_draw_points_internal.size()-1)
	_draw_points_internal.remove(_draw_points_internal.size()-1)
	
	draw_polyline(_draw_points_internal, Color.ROYAL_BLUE, 4.0, true)
	draw_rating_rects()
	for i in range(dots.size()):
		var dot := dots[i] as Vector2
		var pos = val_to_rect_pos(dot) - DOT_TEXTURE.get_size() / 2.0
		draw_texture(DOT_TEXTURE, pos, Color.CRIMSON)
