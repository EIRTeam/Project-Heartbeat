extends Control

onready var rhythm_game = get_node("RhythmGame")
onready var quit_button = get_node("QuitButton")
signal quit
func play_song_from_position(song: HBSong, chart: HBChart, time: float):
#	rhythm_game.set_song(song, )
	rhythm_game.resume()
	rhythm_game.base_bpm = song.bpm
	rhythm_game.set_chart(chart)
	rhythm_game.set_process_input(true)
	rhythm_game.play_from_pos(time)
	show()
	connect("resized", self, "set_game_size")
func set_audio(audio, voice = null):
	rhythm_game.audio_stream_player.stream = audio
	if voice:
		rhythm_game.audio_stream_player_voice.stream = voice
func _ready():
	quit_button.connect("pressed", self, "_on_quit_button_pressed")
	rhythm_game.set_process_input(false)
func _on_quit_button_pressed():
	rhythm_game.set_process_input(false)
	rhythm_game.resume()
	hide()
	emit_signal("quit")

func set_game_size():
	rhythm_game.size = rect_size
