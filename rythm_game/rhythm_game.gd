extends Control

func _ready():
	set_game_size()
	connect("resized", $RhythmGame, "set_size", [rect_size])

	
func set_song(song: HBSong):
	$RhythmGame.set_song(song)

func set_game_size():
	$RhythmGame.size = rect_size
	
func _on_resumed():
	$RhythmGame.resume()
	$PauseMenu.hide()
	
func _unhandled_input(event):
	if event.is_action_pressed("pause") and not event.is_echo():
		if not get_tree().paused:
			$RhythmGame.pause_game()
			$PauseMenu.show_pause()
		else:
			_on_resumed()
			$PauseMenu._on_resumed()
		get_tree().set_input_as_handled()
