extends Control

func _ready():
	set_game_size()
	connect("resized", $RhythmGame, "set_size", [rect_size])
	var chart_path = SongLoader.songs["the_top"].get_chart_path("easy")
	var file = File.new()
	file.open(chart_path, File.READ)
	var result = JSON.parse(file.get_as_text()).result
	
	var chart = HBChart.new()
	chart.deserialize(result)
	$RhythmGame.timing_points = chart.get_timing_points()
	$RhythmGame.play_song()
	
func set_song(song: HBSong):
	$RhythmGame.set_song(song)
	
func set_game_size():
	$RhythmGame.size = rect_size
	
