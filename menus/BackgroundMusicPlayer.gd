extends Node

class_name HBBackgroundMusicPlayer

signal stream_time_changed
signal song_started(song, assets)

var song_idx = 0

class SongPlayer:
	extends Node
	
	const FADE_IN_VOLUME = -70
	
	var audio_playback: ShinobuSoundPlayer
	var voice_audio_playback: ShinobuSoundPlayer
	
	var current_load_task: SongAssetLoadAsyncTask
	var song: HBSong
	
	signal song_assets_loaded(assets)
	signal song_ended()
	signal stream_time_changed(time)
	
	var target_volume := 0.0
	var has_audio_normalization_data = false
	var song_idx = 0
	
	var voice_remap: ShinobuChannelRemapEffect
	var audio_remap: ShinobuChannelRemapEffect
	
	func load_song_assets():
		if not song.has_audio() or not song.is_cached():
			return ERR_FILE_NOT_FOUND
		if current_load_task:
			AsyncTaskQueue.abort_task(current_load_task)
		var assets_to_load = ["audio", "voice", "preview", "background"]
		if not song.has_audio_loudness and not SongDataCache.is_song_audio_loudness_cached(song):
			assets_to_load.append("audio_loudness")
		current_load_task = SongAssetLoadAsyncTask.new(assets_to_load, song)
		current_load_task.connect("assets_loaded", Callable(self, "_on_song_assets_loaded"))
		AsyncTaskQueue.queue_task(current_load_task)
		
		emit_signal("stream_time_changed", song.preview_start / 1000.0)
		
		return OK
	
	func _init(_song: HBSong, _song_idx: int):
		song = _song
		song_idx = _song_idx
		
		if song.has_audio_loudness or SongDataCache.is_song_audio_loudness_cached(song):
			var song_loudness = 0.0
			has_audio_normalization_data = true
			if SongDataCache.is_song_audio_loudness_cached(song):
				song_loudness = SongDataCache.audio_normalization_cache[song.id].loudness
			else:
				song_loudness = song.audio_loudness
			target_volume = HBAudioNormalizer.get_offset_from_loudness(song_loudness)
	func _ready():
		set_process(false)
		
	func pause():
		audio_playback.stop()
		if voice_audio_playback:
			voice_audio_playback.stop()
			
	func resume():
		audio_playback.start()
		if voice_audio_playback:
			voice_audio_playback.start()
		
	func _process(_delta):
		if audio_playback:
			emit_signal("stream_time_changed", audio_playback.get_playback_position_msec() / 1000.0)
			var end_time = audio_playback.get_length_msec()
			if song.preview_end != -1:
				end_time = song.preview_end
			if audio_playback.get_playback_position_msec() >= end_time or audio_playback.is_at_stream_end():
				fade_out()
				emit_signal("song_ended")
		
	func get_song_audio_name():
		return "%s_%d" % [str(song.id), song_idx]
	func get_song_voice_audio_name():
		return "voice_%s_%d" % [str(song.id), song_idx]
		
	func _on_song_assets_loaded(assets):
		if "audio" in assets:
			if "audio_loudness" in assets:
				target_volume = HBAudioNormalizer.get_offset_from_loudness(assets.audio_loudness)
			var song_audio_name = get_song_audio_name()
			var sound_source := Shinobu.register_sound_from_memory(song_audio_name, assets.audio_shinobu)
			audio_playback = sound_source.instantiate(HBGame.menu_music_group, song.uses_dsc_style_channels())
			var use_source_channel_count := song.uses_dsc_style_channels() and audio_playback.get_channel_count() >= 4
			if song.uses_dsc_style_channels() and not use_source_channel_count:
				audio_playback.queue_free()
				audio_playback = sound_source.instantiate(HBGame.menu_music_group)
			add_child(audio_playback)
			audio_playback.volume = 0.0
			audio_playback.seek(song.preview_start)
			# Scheduling starts prevents crackles
			audio_playback.schedule_start_time(Shinobu.get_dsp_time())
			audio_playback.start()
			
			#audio_playback.connect_sound_to_effect(HBGame.spectrum_analyzer)
			
			if "voice" in assets and assets.voice:
				var song_voice_audio_name = get_song_voice_audio_name()
				var voice_source := Shinobu.register_sound_from_memory(song_voice_audio_name, assets.voice_shinobu)
				voice_audio_playback = voice_source.instantiate(HBGame.menu_music_group, use_source_channel_count)
				voice_audio_playback.volume = 0.0
				voice_audio_playback.seek(song.preview_start)
				voice_audio_playback.schedule_start_time(Shinobu.get_dsp_time())
				voice_audio_playback.start()
				add_child(voice_audio_playback)
			if song.uses_dsc_style_channels() and audio_playback.get_channel_count() >= 4:
				if voice_audio_playback:
					voice_remap = Shinobu.instantiate_channel_remap(voice_audio_playback.get_channel_count(), 2)
					voice_remap.set_weight(2, 0, 1.0)
					voice_remap.set_weight(3, 1, 1.0)
					voice_remap.connect_to_group(HBGame.menu_music_group)
					voice_audio_playback.connect_sound_to_effect(voice_remap)
				
				
				audio_remap = Shinobu.instantiate_channel_remap(audio_playback.get_channel_count(), 2)
				audio_remap.set_weight(0, 0, 1.0)
				audio_remap.set_weight(1, 1, 1.0)
				audio_remap.connect_to_group(HBGame.menu_music_group)
				audio_playback.connect_sound_to_effect(audio_remap)
				
		var tween := Threen.new()
		
		add_child(tween)
		if audio_playback:
			tween.interpolate_property(audio_playback, "volume", 0.0, db_to_linear(target_volume), 0.5)
		if voice_audio_playback:
			tween.interpolate_property(voice_audio_playback, "volume", 0.0, db_to_linear(target_volume), 0.5)
		
		tween.connect("tween_all_completed", Callable(tween, "queue_free"))
		
		tween.start()
		
		emit_signal("song_assets_loaded", assets)
		
		set_process(true)
		
		

	var calls := 0
		
	func fade_out():
		set_process(false) # nothing else should fire while fading out...
		var tween := Threen.new()
		
		add_child(tween)
		if audio_playback:
			tween.interpolate_property(audio_playback, "volume", db_to_linear(target_volume), 0.0, 0.5)
			if voice_audio_playback:
				tween.interpolate_property(voice_audio_playback, "volume", db_to_linear(target_volume), 0.0, 0.5)
		
		tween.connect("tween_all_completed", Callable(self, "queue_free"))
		
		tween.start()

var current_song_player: SongPlayer

func play_song(song: HBSong):
#	if not song.has_audio_loudness and not SongDataCache.is_song_audio_loudness_cached(song):
#		return
	if current_song_player:
		if song == current_song_player.song:
			return
	var song_player = SongPlayer.new(song, song_idx)
	song_idx += 1
	add_child(song_player)
	song_player.connect("song_assets_loaded", Callable(self, "_on_song_assets_loaded"))
	song_player.connect("stream_time_changed", Callable(self, "_on_stream_time_changed"))
	song_player.connect("song_ended", Callable(self, "_on_song_ended"))
	
	if song_player.load_song_assets() == OK:
		if current_song_player:
			current_song_player.fade_out()
			current_song_player.disconnect("song_assets_loaded", Callable(self, "_on_song_assets_loaded"))
			current_song_player.disconnect("stream_time_changed", Callable(self, "_on_stream_time_changed"))
		current_song_player = song_player
	else:
		song_player.queue_free()
	
	
func _on_stream_time_changed(time: float):
	emit_signal("stream_time_changed", time)
	
func _on_song_ended():
	play_random_song()
	
func _on_song_assets_loaded(assets):
	emit_signal("song_started", current_song_player.song, assets)

func play_random_song():
	randomize()
	var found_song: HBSong
	while not found_song:
		var song := SongLoader.songs.values()[randi() % SongLoader.songs.size()] as HBSong
		var is_current_song = false
		if current_song_player:
			is_current_song = current_song_player.song == song
		if song.has_audio() and song.is_cached() and \
				(song.has_audio_loudness or SongDataCache.is_song_audio_loudness_cached(song)) and \
				not is_current_song:
			found_song = song
	if found_song:
		play_song(found_song)

func pause():
	current_song_player.pause()
func resume():
	current_song_player.resume()
