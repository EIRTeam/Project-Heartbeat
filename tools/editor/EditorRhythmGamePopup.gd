extends Control

onready var rhythm_game = HBRhythmGame.new()
onready var quit_button = get_node("HBoxContainer/QuitButton")
onready var restart_button = get_node("HBoxContainer/RestartButton")
onready var rhythm_game_ui = get_node("RhythmGame")
onready var stats_label = get_node("ExtraUI/HBoxContainer/StatsLabel")
signal quit

var _last_time = 0.0

var stats_latency_sum = 0
var stats_passed_notes = 0
var stats_total_notes = 0
var stats_diffs = []
var last_notes = []

func _init():
	name = "EditorRhythmGamePopup"
	
func play_song_from_position(song: HBSong, chart: HBChart, time: float):
#	rhythm_game.set_song(song, )
	rhythm_game.remove_all_notes_from_screen()
	rhythm_game.reset_hit_notes()
	var volume = db2linear(SongDataCache.get_song_volume_offset(song) * song.volume)
	rhythm_game.audio_playback.volume = volume
	if rhythm_game.voice_audio_playback:
		rhythm_game.voice_audio_playback.volume = volume
	rhythm_game.seek(time * 1000.0)
	rhythm_game.start()
	rhythm_game.base_bpm = song.bpm
	rhythm_game.set_chart(chart)
	rhythm_game.set_process_input(true)
	rhythm_game.game_input_manager.set_process_input(true)
	reset_stats()
	_last_time = time
	show()
	set_game_size()
	set_process_unhandled_input(true)
func set_audio(song: HBSong, variant := -1):
	rhythm_game.audio_playback = ShinobuGodotSoundPlaybackOffset.new(ShinobuGodot.instantiate_sound("song", "music"))
	rhythm_game.audio_playback.offset = song.get_variant_data(variant).variant_offset
	if song.voice:
		rhythm_game.voice_audio_playback = ShinobuGodotSoundPlaybackOffset.new(ShinobuGodot.instantiate_sound("song_voice", "music"))
		rhythm_game.voice_audio_playback.offset = song.get_variant_data(variant).variant_offset
func _ready():
	quit_button.connect("pressed", self, "_on_quit_button_pressed")
	restart_button.connect("pressed", self, "_on_restart_button_pressed")
	rhythm_game.connect("note_judged", self, "_on_note_judged")
	connect("resized", self, "set_game_size")
	add_child(rhythm_game)
	rhythm_game.health_system_enabled = false
	rhythm_game_ui.hide_intro_skip()
	rhythm_game.set_game_ui(rhythm_game_ui)
	rhythm_game.set_game_input_manager(HeartbeatInputManager.new())
	rhythm_game.game_input_manager.set_process_input(false)
	rhythm_game.set_process_input(false)
	set_process_unhandled_input(false)
	
func _unhandled_input(event):
	if event.is_action_pressed("contextual_option"):
		_on_restart_button_pressed()
	
func _on_restart_button_pressed():
	rhythm_game.remove_all_notes_from_screen()
	rhythm_game.reset_hit_notes()
	reset_stats()
	rhythm_game.seek(_last_time * 1000.0)
	rhythm_game.start()

func _on_quit_button_pressed():
	rhythm_game.set_process_input(false)
	rhythm_game.game_input_manager.set_process_input(false)
	rhythm_game.pause_game()
	hide()
	set_process_unhandled_input(false)
	emit_signal("quit")

func set_game_size():
	rhythm_game.size = rect_size


func reset_stats():
	stats_latency_sum = 0
	stats_passed_notes = 0
	stats_total_notes = 0
	stats_diffs = []
	last_notes = []
	update_stats_label()


func update_stats_label():
	for i in range(last_notes.size()-1, -1, -1):
		var n_time = last_notes[i]
		if n_time < (rhythm_game.time * 1000.0) - 1000.0:
			last_notes.remove(i)
	var passed_percentage = 0.0
	var avg_latency = 0.0
	if stats_total_notes > 0 :
		passed_percentage = stats_passed_notes/float(stats_total_notes) * 100.0
	if stats_passed_notes > 0:
		avg_latency = stats_latency_sum / float(stats_passed_notes)
	stats_label.text = "%d/%d (%.2f %%)\n" % [stats_passed_notes, stats_total_notes, passed_percentage]
	stats_label.text += "NPS: %d\n" % last_notes.size()
	stats_label.text += "Avg. latency: %.0f ms" % [avg_latency]


func _on_note_judged(judgement_info):
	var judgement = judgement_info.judgement
	var target_time = judgement_info.target_time
	stats_total_notes += 1
	last_notes.append(target_time)
	if judgement >= HBJudge.JUDGE_RATINGS.FINE and not judgement_info.wrong:
		stats_passed_notes += 1
		stats_latency_sum += judgement_info.time-judgement_info.target_time
	update_stats_label()
