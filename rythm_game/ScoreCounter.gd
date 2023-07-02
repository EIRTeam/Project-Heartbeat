extends Label

var score = 0: set = set_score

var _display_score = 0.0

const SCORE_MAX_OUT_TIME = 0.5 # How much time it takes for the score to be applied

var increase_speed = 2000.0 # points per second

func set_score(val):
	score = val
	var diff = score - _display_score
	increase_speed = diff / SCORE_MAX_OUT_TIME

func _ready():
	text = "%0*d" % [7, 0]

func _process(delta):
	if _display_score < score:
		var speed = increase_speed + (increase_speed * _display_score / score)
		_display_score += delta * speed
		_display_score = clamp(_display_score, 0, score)
		text = "%0*d" % [7, int(_display_score)]
	else:
		text = "%0*d" % [7, score]
