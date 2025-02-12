extends Node

class_name HBBackgroundMusicPlayer

signal stream_time_changed
signal song_started(song)

var song_idx = 0

class SongPlayer:
	extends Node
	
	const FADE_IN_VOLUME = -70
	
	var audio_playback: ShinobuSoundPlayer
	var voice_audio_playback: ShinobuSoundPlayer
	
	var song: HBSong
	
	signal song_assets_loaded(assets)
	signal song_ended()
	signal stream_time_changed(time)
	
	var target_volume := 0.0
	var volume_offset := 0.0
	
	var has_audio_normalization_data = false
	var song_idx = 0
	
	var voice_remap: ShinobuChannelRemapEffect
	var audio_remap: ShinobuChannelRemapEffect
	
	var has_assets := false
	
	func _get_song_user_volume(song: HBSong, variant := -1, loudness_offset := 0.0) -> float:
		var volume_offset := loudness_offset
		var base_volume := song.get_volume_db()
		var out_volume := 0.0
		if song.id in UserSettings.user_settings.per_song_settings:
			var user_song_settings = UserSettings.user_settings.per_song_settings[song.id] as HBPerSongSettings
			if variant != -1:
				volume_offset = song.get_variant_data(variant).get_volume()
			out_volume = db_to_linear(base_volume + volume_offset) * user_song_settings.volume
		else:
			out_volume = db_to_linear(base_volume + volume_offset)
		return out_volume
	
	func load_song_assets():
		if not song.has_audio() or not song.is_cached():
			return ERR_FILE_NOT_FOUND
		var assets_to_load: Array[SongAssetLoader.ASSET_TYPES] = [
			SongAssetLoader.ASSET_TYPES.AUDIO,
			SongAssetLoader.ASSET_TYPES.VOICE,
			SongAssetLoader.ASSET_TYPES.PREVIEW,
			SongAssetLoader.ASSET_TYPES.BACKGROUND
		]
		if not song.has_audio_loudness and not SongDataCache.is_song_audio_loudness_cached(song):
			assets_to_load.append(SongAssetLoader.ASSET_TYPES.AUDIO_LOUDNESS)
		var token := SongAssetLoader.request_asset_load(song, assets_to_load)
		token.assets_loaded.connect(_on_song_assets_loaded)
		
		emit_signal("stream_time_changed", song.preview_start / 1000.0)
		
		return OK
	
	func _init(_song: HBSong, _song_idx: int):
		song = _song
		song_idx = _song_idx

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
		
	func _on_song_assets_loaded(token: SongAssetLoader.AssetLoadToken):
		has_assets = true
		var audio: SongAssetLoader.SongAudioData = token.get_asset(SongAssetLoader.ASSET_TYPES.AUDIO)
		var voice: SongAssetLoader.SongAudioData = token.get_asset(SongAssetLoader.ASSET_TYPES.VOICE)
		var audio_loudness: SongAssetLoader.AudioNormalizationInfo = token.get_asset(SongAssetLoader.ASSET_TYPES.AUDIO_LOUDNESS)
		if audio and audio.shinobu:
			if song.has_audio_loudness or SongDataCache.is_song_audio_loudness_cached(song):
				var song_loudness = 0.0
				has_audio_normalization_data = true
				if SongDataCache.is_song_audio_loudness_cached(song):
					song_loudness = SongDataCache.audio_normalization_cache[song.id].loudness
				else:
					song_loudness = song.audio_loudness
				volume_offset = HBAudioNormalizer.get_offset_from_loudness(song_loudness)
			elif audio_loudness:
				volume_offset = HBAudioNormalizer.get_offset_from_loudness(audio_loudness.loudness)
			
			target_volume = _get_song_user_volume(song, -1, volume_offset)

			var song_audio_name = get_song_audio_name()
			var sound_source := audio.shinobu
			audio_playback = sound_source.instantiate(HBGame.menu_music_group, song.uses_dsc_style_channels())
			var use_source_channel_count := song.uses_dsc_style_channels() and audio_playback.get_channel_count() >= 4
			if song.uses_dsc_style_channels() and not use_source_channel_count:
				audio_playback.queue_free()
				audio_playback = sound_source.instantiate(HBGame.menu_music_group)
			add_child(audio_playback)
			audio_playback.seek(song.preview_start)
			# Scheduling starts prevents crackles
			audio_playback.schedule_start_time(Shinobu.get_dsp_time())
			
			#audio_playback.connect_sound_to_effect(HBGame.spectrum_analyzer)
			
			if voice and voice.shinobu:
				var song_voice_audio_name = get_song_voice_audio_name()
				var voice_source := voice.shinobu
				voice_audio_playback = voice_source.instantiate(HBGame.menu_music_group, use_source_channel_count)
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
				
		if audio_playback:
			# WARNING: DO NOT SET THE VOLUME FOR THE BACKGORUND MUSIC PLAYER's AUDIO PLAYBACK NODES
			# OR YOU WILL BE KILLED, AUDIO FADING IS INDEPENDENT FROM VOLUME SO IF YOU DO THAT IT WILL GET
			# EXPONENTIALLY BOOSTED, KEEP IT AT 1.0 PLEASE
			audio_playback.fade(500, 0.0, target_volume)
			audio_playback.start()
		if voice_audio_playback:
			voice_audio_playback.fade(500, 0.0, target_volume)
			voice_audio_playback.start()
		
		emit_signal("song_assets_loaded")
		
		set_process(true)

	func notify_song_volume_settings_changed():
		# We are fading out already, do nothing..
		if not is_processing():
			return
		target_volume = _get_song_user_volume(song, -1, volume_offset)
		if voice_audio_playback:
			voice_audio_playback.fade(200, -1.0, target_volume)
		if audio_playback:
			audio_playback.fade(200, -1.0, target_volume)

	func fade_out():
		set_process(false) # nothing else should fire while fading out...
		if audio_playback:
			audio_playback.fade(500, target_volume, 0.0)
			if voice_audio_playback:
				voice_audio_playback.fade(500, target_volume, 0.0)
		
		var timer := get_tree().create_timer(0.5, false)
		timer.timeout.connect(self.queue_free)

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
			current_song_player.disconnect("song_assets_loaded", Callable(self, "_on_song_assets_loaded"))
			current_song_player.disconnect("stream_time_changed", Callable(self, "_on_stream_time_changed"))
			if not current_song_player.has_assets:
				current_song_player.queue_free()
			else:
				current_song_player.fade_out()
		current_song_player = song_player
	else:
		song_player.queue_free()
	
	
func _on_stream_time_changed(time: float):
	emit_signal("stream_time_changed", time)
	
func _on_song_ended():
	play_random_song()
	
func _on_song_assets_loaded():
	emit_signal("song_started")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F9:
			play_random_song()

func play_random_song():
	if SongLoader.songs.size() == 0:
		return
	randomize()
	var found_song: HBSong
	var attempts := 0
	const MAX_ATTEMPTS := 40
	while not found_song and attempts < MAX_ATTEMPTS:
		var song := SongLoader.songs.values()[randi() % SongLoader.songs.size()] as HBSong
		var is_current_song = false
		if current_song_player:
			is_current_song = current_song_player.song == song
		if song.has_audio() and song.is_cached() and \
				(song.has_audio_loudness or SongDataCache.is_song_audio_loudness_cached(song)) and \
				not is_current_song:
			found_song = song
		attempts += 1
	if found_song:
		play_song(found_song)

func pause():
	current_song_player.pause()
func resume():
	current_song_player.resume()

func notify_song_volume_settings_changed(song: HBSong):
	if current_song_player.song == song:
		current_song_player.notify_song_volume_settings_changed()

func get_current_song_length() -> float:
	if current_song_player.audio_playback:
		return current_song_player.audio_playback.get_length_msec() * 0.001
	return -1.0
