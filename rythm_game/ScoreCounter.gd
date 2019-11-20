extends Label

var score = 0

var _display_score = 0

const INCREASE_SPEED = 2000 # points per second

func _process(delta):
	if _display_score < score:
		_display_score += clamp(int(delta * INCREASE_SPEED), 0, score)
		text = "%0*d" % [7, _display_score]
	else:
		text = "%0*d" % [7, score]
