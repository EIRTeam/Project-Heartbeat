extends Control

var horizontal := 20 setget set_horizontal
var vertical := 40 setget set_vertical
var settings: HBPerSongEditorSettings

onready var game = get_node("../../RhythmGame")

const MULTI_TARGETS = [Vector2(240, 528), Vector2(720, 528), Vector2(1200, 528), Vector2(1680, 528)]

func _draw():
	var origin = game.remap_coords(Vector2())
	var size = game.playing_field_size
	for i in range(horizontal):
		var first_point = Vector2(origin.x, size.y * (i/float(horizontal)))
		var second_point = first_point + Vector2(size.x, 0)
		draw_line(first_point, second_point, Color(0.5, 0.5, 0.5))
		
	for i in range(vertical):
		var first_point = Vector2(origin.x + size.x * i/float(vertical), 0)
		var second_point = first_point + Vector2(0, size.y)
		draw_line(first_point, second_point, Color(0.5, 0.5, 0.5))
	
	for note_coord in MULTI_TARGETS:
		draw_cross(game.remap_coords(note_coord))
func draw_cross(cross_center: Vector2):
	var height = (game.get_note_scale() * 100) / 2.0
	var cross_vertical_start = cross_center - Vector2(0, height)
	var cross_vertical_end = cross_center + Vector2(0, height)
	var cross_horizontal_start = cross_center - Vector2(height, 0)
	var cross_horizontal_end = cross_center + Vector2(height, 0)
	draw_line(cross_vertical_start, cross_vertical_end, Color.white, 1.0)
	draw_line(cross_horizontal_start, cross_horizontal_end, Color.white,1.0)
func set_horizontal(value):
	horizontal = value
	settings.grid_resolution.x = value
	update()
func set_vertical(value):
	vertical = value
	settings.grid_resolution.y = value
	update()
