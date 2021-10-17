# This takes care of all things related to playing back in the editor.
extends Node

class_name EditorPlayback

var audio_stream_player := AudioStreamPlayer.new()
var voice_audio_stream_player := AudioStreamPlayer.new()
var game: HBRhythmGame
var time_begin
var time_delay
var _audio_play_offset
var chart: HBChart setget set_chart
var current_song: HBSong
signal time_changed

func set_chart(val):
	chart = val
	game.set_chart(chart)
func _init(_game: HBRhythmGame):
	self.game = _game

func _ready():
	add_child(audio_stream_player)
	add_child(voice_audio_stream_player)
	audio_stream_player.bus = "Music"
	voice_audio_stream_player.bus = "Music"

func _process(delta):
	var time = 0.0
	if audio_stream_player.playing:
		time = (OS.get_ticks_usec() - time_begin) / 1000000.0
		# Compensate for latency.
		time -= time_delay
		time -= UserSettings.user_settings.lag_compensation / 1000.0
		# May be below 0 (did not being yet).
		time = max(0, time)
		
		time = time + _audio_play_offset
		game.time = time
	if audio_stream_player.playing and not audio_stream_player.stream_paused:
		emit_signal("time_changed", time)

func get_song_volume():
	return SongDataCache.get_song_volume_offset(current_song) * current_song.volume

func set_song(song: HBSong):
	current_song = song
	audio_stream_player.stream = song.get_audio_stream()
	
	if not SongDataCache.is_song_audio_loudness_cached(song):
		var norm = HBAudioNormalizer.new()
		norm.set_target_ogg(song.get_audio_stream())
		print("Loudness cache not found, normalizing...")
		while not norm.work_on_normalization():
			pass
		var res = norm.get_normalization_result()
		SongDataCache.update_loudness_for_song(song, res)
	
	var volume_db = get_song_volume()
	
	audio_stream_player.volume_db = volume_db
	if song.voice:
		voice_audio_stream_player.volume_db = volume_db
		voice_audio_stream_player.stream = song.get_voice_stream()
	else:
		voice_audio_stream_player.volume_db = -100

func pause():
	game.reset_hit_notes()
	audio_stream_player.stream_paused = true
	audio_stream_player.volume_db = -100
	audio_stream_player.stop()
	voice_audio_stream_player.stream_paused = true
	voice_audio_stream_player.volume_db = -100
	voice_audio_stream_player.stop()
#	_on_timing_points_changed()
	game.previewing = false
	game.sfx_pool.stop_all_sfx()

func is_playing():
	return audio_stream_player.playing

func seek(value: int):
	#game.remove_all_notes_from_screen()
	if not audio_stream_player.playing:
		pause()
	else:
		play_from_pos(value)
		
	game.time = value / 1000.0
	emit_signal("time_changed", game.time)
	game.reset_hit_notes()
	#_on_timing_points_changed()
	game.delete_rogue_notes(value / 1000.0)
		

func _on_timing_params_changed():
	game._on_viewport_size_changed()
#	game.remove_all_notes_from_screen()
#	game.reset_hit_notes()
#	game.base_bpm = current_song.bpm # We reset the BPM
#	game.set_chart(chart)
#	game.delete_rogue_notes(game.time)

func play_from_pos(position: float):
	if current_song:
		game.previewing = true
		audio_stream_player.stream_paused = false
		audio_stream_player.play()
		audio_stream_player.seek(position / 1000.0)
		voice_audio_stream_player.stream_paused = false
		
		var song_volume = get_song_volume()
		audio_stream_player.volume_db = song_volume
		if current_song.voice:
			voice_audio_stream_player.volume_db = song_volume
		
		voice_audio_stream_player.play()
		voice_audio_stream_player.seek(position / 1000.0)
		time_begin = OS.get_ticks_usec()
		time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
		_audio_play_offset = position / 1000.0
		game.play_from_pos(position / 1000.0)
		game.delete_rogue_notes(position / 1000.0)
		game.hold_release()
		emit_signal("time_changed", position / 1000.0)

func set_lyrics(phrases: Array):
	var lyrics_view = game.game_ui.get_lyrics_view()
	lyrics_view.set_phrases(phrases)
