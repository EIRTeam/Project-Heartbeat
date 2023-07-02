extends Control

@onready var rhythm_game = HBRhythmGame.new()
@onready var rhythm_game_ui = get_node("RhythmGame")
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
	rhythm_game.resume()
	rhythm_game.set_chart(chart)
	rhythm_game.set_process_input(true)
	rhythm_game.game_input_manager.set_process_input(true)
	rhythm_game.play_from_pos(0)
	reset_stats()
	
	if song is HBAutoSong:
		rhythm_game.audio_playback.volume = db_to_linear(HBAudioNormalizer.get_offset_from_loudness(song.loudness))
		if rhythm_game.voice_audio_playback:
			rhythm_game.voice_audio_playback.volume = 0.0
	else:
		var volume = db_to_linear(SongDataCache.get_song_volume_offset(song) * song.volume)
		rhythm_game.audio_playback.volume = volume
		if rhythm_game.voice_audio_playback:
			rhythm_game.voice_audio_playback.volume = volume
		else:
			rhythm_game.voice_audio_playback.volume = 0.0
	
	_last_time = 0
	
	show()
	set_game_size()

func set_audio(audio, voice = null):
	rhythm_game.audio_playback = ShinobuGodotSoundPlaybackOffset.new(audio)
	if voice:
		rhythm_game.voice_audio_playback.stream = ShinobuGodotSoundPlaybackOffset.new(voice)

func _ready():
	connect("resized", Callable(self, "_on_resized"))
	rhythm_game_ui._set_ui_visible(false)
	
	add_child(rhythm_game)
	rhythm_game.connect("note_judged", Callable(self, "_on_note_judged"))
	rhythm_game.set_game_ui(rhythm_game_ui)
	rhythm_game.set_game_input_manager(HeartbeatInputManager.new())
	rhythm_game.game_input_manager.set_process_input(false)
	rhythm_game.set_process_input(false)

func _on_resized():
	set_game_size()
	rhythm_game._on_viewport_size_changed()

func set_game_size():
	rhythm_game.size = size

func restart():
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
