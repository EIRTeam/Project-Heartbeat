extends Node

class_name HBBackgroundMusicPlayer

signal stream_time_changed
signal song_started(song, assets)


class SongPlayer:
	extends Node
	
	const FADE_IN_VOLUME = -70
	
	onready var audio_stream_player := AudioStreamPlayer.new()
	onready var audio_stream_player_voice := AudioStreamPlayer.new()
	var current_load_task: SongAssetLoadAsyncTask
	var song: HBSong
	
	signal song_assets_loaded(assets)
	signal song_ended()
	signal stream_time_changed(time)
	
	var target_volume := 0.0
	var has_audio_normalization_data = false
	
	func load_song_assets():
		if not song.has_audio() or not song.is_cached():
			return ERR_FILE_NOT_FOUND
		if current_load_task:
			AsyncTaskQueue.abort_task(current_load_task)
		var assets_to_load = ["audio", "voice", "preview", "background", "circle_logo"]
		current_load_task = SongAssetLoadAsyncTask.new(assets_to_load, song)
		current_load_task.connect("assets_loaded", self, "_on_song_assets_loaded")
		AsyncTaskQueue.queue_task(current_load_task)
		
		emit_signal("stream_time_changed", song.preview_start / 1000.0)
		
		return OK
	
	func _init(_song: HBSong):
		song = _song
		
		if song.has_audio_loudness or SongDataCache.is_song_audio_loudness_cached(song):
			var song_loudness = 0.0
			has_audio_normalization_data = true
			if SongDataCache.is_song_audio_loudness_cached(song):
				song_loudness = SongDataCache.audio_normalization_cache[song.id].loudness
			else:
				song_loudness = song.audio_loudness
			target_volume = HBAudioNormalizer.get_offset_from_loudness(song_loudness)
	func _ready():
		add_child(audio_stream_player)
		add_child(audio_stream_player_voice)
		set_process(false)
		
		if has_audio_normalization_data:
			audio_stream_player.bus = "Music"
			audio_stream_player_voice.bus = "Music"
		else:
			audio_stream_player.bus = "MenuMusic"
			audio_stream_player_voice.bus = "MenuMusic"
		
	func pause():
		audio_stream_player.stream_paused = true 
		audio_stream_player_voice.stream_paused = true
	func resume():
		audio_stream_player.stream_paused = false 
		audio_stream_player_voice.stream_paused = false 
		
	func _process(_delta):
		emit_signal("stream_time_changed", audio_stream_player.get_playback_position())
		var end_time = audio_stream_player.stream.get_length()
		if song.end_time != -1:
			end_time = song.end_time / 1000.0
		if audio_stream_player.get_playback_position() >= end_time:
			fade_out()
			emit_signal("song_ended")
		
	func _on_song_assets_loaded(assets):
		audio_stream_player.volume_db = FADE_IN_VOLUME
		audio_stream_player_voice.volume_db = FADE_IN_VOLUME
		
		if "audio" in assets:
			audio_stream_player.stream = assets.audio
			audio_stream_player.play()
			audio_stream_player.seek(song.preview_start/1000.0)
			if "voice" in assets and assets.voice:
				audio_stream_player_voice.stream = assets.voice
				audio_stream_player_voice.play()
				audio_stream_player_voice.seek(song.preview_start/1000.0)
		
		var tween := Tween.new()
		
		add_child(tween)
		
		tween.interpolate_property(audio_stream_player, "volume_db", FADE_IN_VOLUME, target_volume, 0.5)
		tween.interpolate_property(audio_stream_player_voice, "volume_db", FADE_IN_VOLUME, target_volume, 0.5)
		tween.connect("tween_all_completed", tween, "queue_free")
		
		tween.start()
		
		emit_signal("song_assets_loaded", assets)
		
		set_process(true)
		
		

		
	func fade_out():
		set_process(false) # nothing else should fire while fading out...
		var tween := Tween.new()
		
		add_child(tween)
		
		tween.interpolate_property(audio_stream_player, "volume_db", target_volume, -70, 0.5)
		tween.interpolate_property(audio_stream_player_voice, "volume_db", target_volume, -70, 0.5)
		tween.connect("tween_all_completed", self, "queue_free")
		
		tween.start()

var current_song_player: SongPlayer

func play_song(song: HBSong):
	if current_song_player:
		if song == current_song_player.song:
			return
	var song_player = SongPlayer.new(song)
	add_child(song_player)
	song_player.connect("song_assets_loaded", self, "_on_song_assets_loaded")
	song_player.connect("stream_time_changed", self, "_on_stream_time_changed")
	song_player.connect("song_ended", self, "_on_song_ended")
	
	if song_player.load_song_assets() == OK:
		if current_song_player:
			current_song_player.fade_out()
			current_song_player.disconnect("song_assets_loaded", self, "_on_song_assets_loaded")
			current_song_player.disconnect("stream_time_changed", self, "_on_stream_time_changed")
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
		var song = SongLoader.songs.values()[randi() % SongLoader.songs.size()]
		if song.has_audio() and song.is_cached():
			found_song = song
	if found_song:
		play_song(found_song)

func pause():
	current_song_player.pause()
func resume():
	current_song_player.resume()
