extends Control

onready var widget_area = get_node("WidgetArea")
onready var game = get_node("RythmGame")
const SAFE_AREA_FACTOR = 0.05
const SAFE_AREA_SIZE = Vector2(192, 108)

func _ready():
	game.size = rect_size
	game.editing = true
	game.hide_ui()
	connect("resized", self, "_on_resized")
	
func _on_resized():
	game.size = rect_size
	game._on_viewport_size_changed()
	update()
	
func _process(delta):
	$Label.text = HBUtils.format_time(game.time * 1000.0)
	$Label.text += "\n BPM: " + str(game.get_bpm_at_time(game.time*1000.0))
	

func _draw():
	var origin = game.remap_coords(Vector2())
	var size = game.playing_field_size
	_draw_game_area(origin, size)
	_draw_safe_area(origin, size)
func _draw_game_area(origin, size):
	draw_rect(Rect2(origin, size), Color(1.0, 1.0, 1.0), false, 1.0, true)

func _draw_safe_area(origin, size):
	var GAME_AREA_START = game.remap_coords(Vector2.ZERO)
	var safe_area_rect = Rect2(game.remap_coords(SAFE_AREA_SIZE), game.remap_coords(game.BASE_SIZE) + GAME_AREA_START - game.remap_coords(SAFE_AREA_SIZE) * 2)
	draw_rect(safe_area_rect, Color(1.0, 0.0, 0.0), false, 1.0, true)
