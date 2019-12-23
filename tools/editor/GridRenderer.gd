extends Control

var horizontal := 5 setget set_horizontal
var vertical := 7 setget set_vertical

onready var game = get_node("../RythmGame")

func _draw():
	var origin = game.remap_coords(Vector2())
	var size = game.get_playing_field_size()
	for i in range(horizontal):
		var first_point = Vector2(origin.x, size.y * (i/float(horizontal)))
		var second_point = first_point + Vector2(size.x, 0)
		draw_line(first_point, second_point, Color(0.5, 0.5, 0.5))
		
	for i in range(vertical):
		var first_point = Vector2(origin.x + size.x * i/float(vertical), 0)
		var second_point = first_point + Vector2(0, size.y)
		draw_line(first_point, second_point, Color(0.5, 0.5, 0.5))

func set_horizontal(value):
	horizontal = value
	update()
func set_vertical(value):
	vertical = value
	update()
