extends Control

func _ready():
	$RythmGame.size = rect_size
	$RythmGame.editing = true
	
func _process(delta):
	$Label.text = HBUtils.format_time($RythmGame.time * 1000.0)
