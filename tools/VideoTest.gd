extends Control

func _ready():
	var stream = VideoStreamGDNative.new()
	var file = load("res://out2.webm").get_file()
	print(file)
	stream.set_file(file)
	var vp = $VideoStreamPlayer
	vp.stream = stream

	var sp = vp.stream_position
	# hack: to get the stream length, set the position to a negative number
	# the plugin will set the position to the end of the stream instead.
	vp.stream_position = -1
	vp.stream_position = 0
	vp.play()
#	yield(get_tree(), "idle_frame") #This idle frame	
#	$VideoPlayer.stream_position = 5

func _input(event):
	if event.is_action_pressed("show_hidden"):
		$VideoStreamPlayer.stream_position = 5


func _on_VideoPlayer_finished():
	print("ENDED")
	$VideoStreamPlayer.stream_position = 5
