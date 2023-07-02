extends Control

const TRAVEL_UP_TIME = 0.75 # seconds
const FADE_OUT_TIME = 0.15
const TRAVEL_UP_HEIGHT = 75.0
const OFFSET = Vector2(0, -25.0)
var fade_out_t = FADE_OUT_TIME
var travel_up_t = TRAVEL_UP_TIME
var target_opacity = 0.0
var starting_point = Vector2.ZERO
var _game: HBRhythmGame: set = set_game

func set_game(val):
	_game = val
	set_process(true)

func _ready():
	hide()
	set_process(false)

func show_at_point(point: Vector2, score: float, show_max: bool):
	show()
	modulate.a = 0.0
	$VBoxContainer/ScoreLabel.text = "+" + str(score)
	$VBoxContainer/MaxScoreLabel.visible = show_max
	starting_point = point
	fade_out_t = 0.0
	travel_up_t = 0.0
	
func _process(delta: float):
	if travel_up_t >= TRAVEL_UP_TIME - FADE_OUT_TIME:
		fade_out_t = clamp(fade_out_t+delta, 0, FADE_OUT_TIME)
	travel_up_t = clamp(travel_up_t+delta, 0, TRAVEL_UP_TIME)
	modulate.a = 1.0 - (fade_out_t / FADE_OUT_TIME)
	var remapped_starting_point = _game.remap_coords(starting_point) - size / 2
	remapped_starting_point.y += _game.remap_coords(OFFSET).y
	var target_point = remapped_starting_point
	target_point.y -= _game.remap_coords(Vector2(0, TRAVEL_UP_HEIGHT)).y
	position = remapped_starting_point.lerp(target_point, travel_up_t / TRAVEL_UP_TIME)
	
