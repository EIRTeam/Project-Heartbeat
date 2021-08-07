extends Control

onready var rhythm_game = HBRhythmGame.new()
onready var rhythm_game_ui = get_node("RhythmGame")
signal update_stats

var _last_time = 0.0

var stats_latency_sum = 0
var stats_passed_notes = 0
var stats_total_notes = 0
var stats_diffs = []
var last_notes = []

func _init():
	name = "EmbeddedRhythmGameHeartbeat"
	
func play_song(song: HBSong, chart: HBChart):
	rhythm_game.remove_all_notes_from_screen()
	rhythm_game.reset_hit_notes()
	rhythm_game.resume()
	rhythm_game.base_bpm = song.bpm
	rhythm_game.set_chart(chart)
	rhythm_game.set_process_input(true)
	rhythm_game.game_input_manager.set_process_input(true)
	rhythm_game.play_from_pos(0)
	reset_stats()
	
	if song is HBAutoSong:
		rhythm_game.audio_stream_player.volume_db = HBAudioNormalizer.get_offset_from_loudness(song.loudness)
		rhythm_game.audio_stream_player_voice.volume_db = -100
	else:
		var volume = SongDataCache.get_song_volume_offset(song) * song.volume
		rhythm_game.audio_stream_player.volume_db = volume
		if song.voice:
			rhythm_game.audio_stream_player_voice.volume_db = volume
		else:
			rhythm_game.audio_stream_player_voice.volume_db = -100
	
	_last_time = 0
	
	show()
	set_game_size()

func set_audio(audio, voice = null):
	rhythm_game.audio_stream_player.stream = audio
	rhythm_game.audio_stream_player_voice.stream = voice

func _ready():
	connect("resized", self, "set_game_size")
	
	add_child(rhythm_game)
	rhythm_game.connect("note_judged", self, "_on_note_judged")
	rhythm_game.set_game_ui(rhythm_game_ui)
	rhythm_game.set_game_input_manager(HeartbeatInputManager.new())
	rhythm_game.game_input_manager.set_process_input(false)
	rhythm_game.set_process_input(false)

func set_game_size():
	rhythm_game.size = rect_size


func restart():
	rhythm_game.remove_all_notes_from_screen()
	rhythm_game.reset_hit_notes()
	rhythm_game.play_from_pos(_last_time)
	reset_stats()

func reset_stats():
	stats_latency_sum = 0
	stats_passed_notes = 0
	stats_total_notes = 0
	stats_diffs = []
	last_notes = []
	emit_signal("update_stats")

func _on_note_judged(judgement_info):
	var judgement = judgement_info.judgement
	var target_time = judgement_info.target_time
	stats_total_notes += 1
	last_notes.append(target_time)
	if judgement >= HBJudge.JUDGE_RATINGS.FINE and not judgement_info.wrong:
		stats_passed_notes += 1
		stats_latency_sum += judgement_info.time-judgement_info.target_time
	emit_signal("update_stats")


func pause():
	get_tree().paused = true
func resume():
	get_tree().paused = false
