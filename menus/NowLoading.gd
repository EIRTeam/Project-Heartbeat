extends Control

const LOADING_TEXT = "LOADINGU..."

const LOADINGU_SPEED = 6.5 # Characters per second...

var loading_pos = 0

func _process(delta):
	
	loading_pos = fmod((loading_pos + LOADINGU_SPEED * delta), LOADING_TEXT.length()+1)
		
	$LoadingLabel.text = LOADING_TEXT.substr(0, loading_pos)
	
