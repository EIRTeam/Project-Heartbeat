extends Control

onready var rhythm_game = HBRhythmGame.new()
onready var quit_button = get_node("HBoxContainer/QuitButton")
onready var restart_button = get_node("HBoxContainer/RestartButton")
onready var rhythm_game_ui = get_node("RhythmGame")
signal quit

var _last_time = 0.0

func play_song_from_position(song: HBSong, chart: HBChart, time: float):
#	rhythm_game.set_song(song, )
	rhythm_game.remove_all_notes_from_screen()
	rhythm_game.reset_hit_notes()
	rhythm_game.resume()
	rhythm_game.base_bpm = song.bpm
	rhythm_game.set_chart(chart)
	rhythm_game.set_process_input(true)
	rhythm_game.game_input_manager.set_process_input(true)
	rhythm_game.play_from_pos(time)
	var volume = SongDataCache.get_song_volume_offset(song) * song.volume
	rhythm_game.audio_stream_player.volume_db = volume
	if song.voice:
		rhythm_game.audio_stream_player_voice.volume_db = volume
	else:
		rhythm_game.audio_stream_player_voice.volume_db = -100
	_last_time = time
	show()
	set_game_size()
func set_audio(audio, voice = null):
	rhythm_game.audio_stream_player.stream = audio
	rhythm_game.audio_stream_player_voice.stream = voice
func _ready():
	quit_button.connect("pressed", self, "_on_quit_button_pressed")
	restart_button.connect("pressed", self, "_on_restart_button_pressed")
	connect("resized", self, "set_game_size")
	add_child(rhythm_game)
	rhythm_game.set_game_ui(rhythm_game_ui)
	rhythm_game.set_game_input_manager(HeartbeatInputManager.new())
	rhythm_game.game_input_manager.set_process_input(false)
	rhythm_game.set_process_input(false)
	
func _unhandled_input(event):
	if event.is_action_pressed("contextual_option"):
		_on_restart_button_pressed()
	
func _on_restart_button_pressed():
	rhythm_game.remove_all_notes_from_screen()
	rhythm_game.reset_hit_notes()
	rhythm_game.play_from_pos(_last_time)
	
func _on_quit_button_pressed():
	rhythm_game.set_process_input(false)
	rhythm_game.game_input_manager.set_process_input(false)
	rhythm_game.resume()
	hide()
	emit_signal("quit")

func set_game_size():
	rhythm_game.size = rect_size
