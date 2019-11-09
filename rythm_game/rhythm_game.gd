extends Control

func _ready():
	set_game_size()
	connect("resized", $RhythmGame, "set_size", [rect_size])

	
func set_song(song: HBSong):
	$RhythmGame.set_song(song)

func set_game_size():
	$RhythmGame.size = rect_size
	
