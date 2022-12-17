# This takes care of all things related to playing back in the editor.
extends Node

class_name EditorPlayback

var game: HBRhythmGame
var time_begin
var time_delay
var _audio_play_offset
var playback_speed := 1.0
var chart: HBChart setget set_chart
var current_song: HBSong
var selected_variant := -1

var metronome_enabled := false
var metronome_offset := 0
var metronome_separation := 0.0
var metronome_timer := 0.0
var first_after_seek := false

signal time_changed
signal playback_speed_changed(speed)

var pitch_shift_effect: ShinobuPitchShiftEffect = Shinobu.instantiate_pitch_shift()

var godot_audio_stream: AudioStream

var audio_source: ShinobuSoundSource
var voice_source: ShinobuSoundSource

func set_chart(val):
	chart = val
	game.set_chart(chart)
	game._process(0)
func _init(_game: HBRhythmGame):
	self.game = _game

func _process(delta):
	var time = 0.0
	if is_playing() and false:
		time = (OS.get_ticks_usec() - time_begin) / 1000000.0
		time *= playback_speed
		# Compensate for latency.
		time -= time_delay
		time -= UserSettings.user_settings.lag_compensation / 1000.0
		# May be below 0 (did not being yet).
		time = max(0, time)
		
		time = time + _audio_play_offset
		
		var variant_offset = 0
		if current_song:
			variant_offset = current_song.get_variant_offset(selected_variant) / 1000.0
		time += variant_offset
		game.time = time
	if is_playing() and game.audio_playback.is_playing():
		emit_signal("time_changed", game.time)
	
	if is_playing() and metronome_enabled:
		if time * 1000 >= metronome_offset:
			if first_after_seek:
				first_after_seek = false
			else:
				metronome_timer += delta * 1000
			
			if metronome_timer >= metronome_separation:
				game.play_note_sfx()
				metronome_timer -= metronome_separation

func toggle_metronome(offset: int, separation: float):
	metronome_enabled = not metronome_enabled
	metronome_offset = offset
	metronome_separation = separation
	
	if game.time * 1000.0 > metronome_offset:
		metronome_timer = fmod((game.time * 1000.0) - metronome_offset, metronome_separation)
	else:
		metronome_timer = metronome_separation

func get_song_volume():
	return SongDataCache.get_song_volume_offset(current_song) * current_song.volume

func set_song(song: HBSong, variant=-1):
	current_song = song
	selected_variant = variant
	game.audio_playback = null
	game.voice_audio_playback = null
	
	godot_audio_stream = song.get_audio_stream()
	
	if not SongDataCache.is_song_audio_loudness_cached(song):
		var norm = HBAudioNormalizer.new()
		norm.set_target_ogg(godot_audio_stream)
		print("Loudness cache not found, normalizing...")
		while not norm.work_on_normalization():
			pass
		var res = norm.get_normalization_result()
		SongDataCache.update_loudness_for_song(song, res)
	audio_source = Shinobu.register_sound_from_memory("song", godot_audio_stream.data)
	if game.audio_playback:
		game.audio_playback.queue_free()
	if game.voice_audio_playback:
		game.voice_audio_playback.queue_free()
	game.audio_playback = ShinobuGodotSoundPlaybackOffset.new(audio_source.instantiate(HBGame.music_group))
		
	add_child(game.audio_playback)
	game.audio_playback.offset = current_song.get_variant_data(variant).variant_offset
	
	var volume_db = get_song_volume()
	
	game.audio_playback.volume = db2linear(volume_db)
	voice_source = null
	if song.voice:
		var voice_audio_stream = song.get_voice_audio_stream()
		voice_source = Shinobu.register_sound_from_memory("voice", voice_audio_stream.data)
		game.voice_audio_playback = ShinobuGodotSoundPlaybackOffset.new(voice_source.instantiate(HBGame.music_group))
		add_child(game.voice_audio_playback)
		game.voice_audio_playback.offset = current_song.get_variant_data(variant).variant_offset
		game.voice_audio_playback.volume = db2linear(volume_db)

func pause():
	game.game_mode = HBRhythmGameBase.GAME_MODE.EDITOR_SEEK
	game.pause_game()
	game.seek_new(game.time * 1000.0, true)
	game._process(0)
#	_on_timing_points_changed()
	game.previewing = false
	game.sfx_pool.stop_all_sfx()
	game.set_process(false)

func is_playing():
	if not game.audio_playback:
		return false
	return game.audio_playback.is_playing()

func seek(value: int):
	#game.remove_all_notes_from_screen()
	game.seek_new(value, true)
	if not game.audio_playback.is_playing():
		pause()
	else:
		play_from_pos(value)
	game._process(0)
	emit_signal("time_changed", game.time)
	#_on_timing_points_changed()
	game.delete_rogue_notes(value / 1000.0)
		

func _on_timing_params_changed():
	game._on_viewport_size_changed()
#	game.remove_all_notes_from_screen()
#	game.reset_hit_notes()
#	game.base_bpm = current_song.bpm # We reset the BPM
#	game.set_chart(chart)
#	game.delete_rogue_notes(game.time)

func start():
	game.game_mode = HBRhythmGameBase.GAME_MODE.AUTOPLAY
	game.start()
	game.set_process(true)
	game.previewing = true

func play_from_pos(position: float):
	if current_song:
		game.previewing = true
		game.seek_new(position)
		game.start()
		
		var song_volume = get_song_volume()
		
		time_begin = OS.get_ticks_usec()
		time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
		_audio_play_offset = position / 1000.0
		game.seek(position)
		game.start()
		game.delete_rogue_notes(position / 1000.0)
		game.hold_release()
		emit_signal("time_changed", position / 1000.0)
		game.set_process(true)
		
		if position > metronome_offset:
			metronome_timer = fmod(position - metronome_offset, metronome_separation)
			first_after_seek = true
		else:
			metronome_timer = metronome_separation

func set_lyrics(phrases: Array):
	var lyrics_view = game.game_ui.get_lyrics_view()
	lyrics_view.set_phrases(phrases)


func set_speed(value: float, correction: bool):
	playback_speed = value
	
	game.audio_playback.set_pitch_scale(playback_speed)
	if game.voice_audio_playback:
		game.voice_audio_playback.set_pitch_scale(playback_speed)
	
	if correction:
		pitch_shift_effect.pitch_scale = 1.0 / playback_speed
	else:
		pitch_shift_effect.pitch_scale = 1.0
	
	if not is_equal_approx(pitch_shift_effect.pitch_scale, 1.0):
		add_pitch_effect()
	else:
		remove_pitch_effect()
	
	emit_signal("playback_speed_changed", value)

func add_pitch_effect():
	HBGame.spectrum_analyzer.connect_to_effect(pitch_shift_effect)
	pitch_shift_effect.connect_to_endpoint()
func remove_pitch_effect():
	HBGame.spectrum_analyzer.connect_to_endpoint()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		remove_pitch_effect()
