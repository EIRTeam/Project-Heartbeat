# Song asset loader with abort capabilities
extends Node

class_name HBBackgroundSongAssetsLoader

signal song_assets_loaded(song, assets)

var current_song: HBSong
var _current_song_mutex = Mutex.new()
var enable_abort = true # Aborts loading of one song when another request comes

# VisualServer requires references to images be kept alive, so we keep them alive.
var loaded_images = []

var load_mutex = Mutex.new()

const LOG_NAME = "BackgroundSongAssetsLoader.gd"

func _load_song_assets_thread(userdata):
	var song := SongLoader.songs[userdata.song_id] as HBSong
	var audio_normalizer := HBAudioNormalizer.new()
	var loaded_assets = {}
	var original_audio = null
	for asset in userdata.requested_assets:
		var loaded_asset
		if asset == "audio_loudness":
			continue
		match asset:
			"preview":
				if song.preview_image:
					loaded_asset = HBUtils.image_from_fs_async(song.get_song_preview_res_path())
			"background":
				if song.background_image:
					loaded_asset = HBUtils.image_from_fs_async(song.get_song_background_image_res_path())
			"audio":
				if song.has_audio():
					loaded_asset = song.get_audio_stream()
					original_audio = loaded_asset
					if "__game_request" in userdata.requested_assets and not userdata.song.youtube_url:
						if loaded_asset is AudioStreamOGGVorbis:
							var channel_count = HBUtils.get_ogg_channel_count(song.get_song_audio_res_path())
							if channel_count >= 4:
								var audio_utils = HBAudioUtils.new()
								audio_utils.split_audio(loaded_asset)
								loaded_asset = audio_utils.get_split_instrumental()
								loaded_assets["voice"] = audio_utils.get_split_voice()
			"voice":
				if song.voice:
					loaded_asset = song.get_voice_stream()
			"circle_image":
				if song.circle_image:
					loaded_asset = HBUtils.image_from_fs_async(song.get_song_circle_image_res_path())
			"circle_logo":
				if song.circle_logo:
					loaded_asset = HBUtils.image_from_fs_async(song.get_song_circle_logo_image_res_path())
		if loaded_asset:
			loaded_assets[asset] = loaded_asset
		if enable_abort:
			# Current song changed, abort
			_current_song_mutex.lock()
			if current_song.id != userdata.song_id:
				call_deferred("_song_asset_loading_aborted", userdata.thread)
				_current_song_mutex.unlock()
				return
			_current_song_mutex.unlock()
#	OS.delay_msec(int(1 * 1000.0)) # Delay simulation
	if "audio_loudness" in userdata.requested_assets:
		loaded_assets["audio_loudness"] = 0.0
		if "audio" in loaded_assets:
			if loaded_assets.audio:
				var audio_to_normalize = loaded_assets["audio"]
				if original_audio:
					audio_to_normalize = original_audio
					audio_normalizer.set_target_ogg(audio_to_normalize)
					var prev = OS.get_ticks_msec()
					while not audio_normalizer.work_on_normalization():
						if enable_abort:
							_current_song_mutex.lock()
							if current_song.id != userdata.song_id:
								call_deferred("_song_asset_loading_aborted", userdata.thread)
								_current_song_mutex.unlock()
								return
							_current_song_mutex.unlock()
					loaded_assets["audio_loudness"] = audio_normalizer.get_normalization_result()
	if enable_abort:
		# Current song changed, abort
		_current_song_mutex.lock()
		if current_song.id != userdata.song_id:
			call_deferred("_song_asset_loading_aborted", userdata.thread)
			_current_song_mutex.unlock()
			return
		_current_song_mutex.unlock()
	call_deferred("_song_assets_loaded", userdata.thread, song, loaded_assets)
	
func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		force_abort_current_loading()
	
func force_abort_current_loading():
	_current_song_mutex.lock()
	current_song = HBSong.new()
	_current_song_mutex.unlock()
	
func _song_asset_loading_aborted(thread: Thread):
	thread.wait_to_finish()
	
func _song_assets_loaded(thread: Thread, song: HBSong, assets: Dictionary):
	thread.wait_to_finish() # Windows breaks if you don't do this
	_current_song_mutex.lock()
	if current_song:
		if song.id != current_song.id:
			_current_song_mutex.unlock()
			return
	_current_song_mutex.unlock()
	var images = []
	for asset_name in assets:
		if assets[asset_name] is Image:
			var image = assets[asset_name] as Image
			var tex = ImageTexture.new()
			tex.create_from_image(image, HBGame.platform_settings.texture_mode)
				
			# Keep the bloody reference or else this breaks
			images.append(image)
			assets[asset_name] = tex
	
	loaded_images.append(images)
	
	if "audio_loudness" in assets:
		SongDataCache.update_loudness_for_song(song, assets.audio_loudness)
	
	emit_signal("song_assets_loaded", song, assets)
	
func load_song_assets(song, requested_assets=["preview", "background", "audio", "voice"]):
	var thread = Thread.new()
	_current_song_mutex.lock()
	current_song = song
	_current_song_mutex.unlock()
	var result = thread.start(self, "_load_song_assets_thread", {"song_id": song.id, "thread": thread, "requested_assets": requested_assets})
	if result != OK:
		Log.log(self, "Error starting thread for asset loader: " + str(result), Log.LogLevel.ERROR)
