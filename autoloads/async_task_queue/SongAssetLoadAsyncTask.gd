extends HBTask

class_name SongAssetLoadAsyncTask

signal assets_loaded(assets)

var requested_assets: Array
var requested_assets_queue: Array
var song: HBSong
var loaded_assets: Dictionary = {}

var loaded_assets_mutex := Mutex.new()

var safe_texture_loading = false

func _init(_requested_assets: Array, _song: HBSong).():
	requested_assets = _requested_assets
	requested_assets_queue = _requested_assets.duplicate(true)
	song = _song
	safe_texture_loading = !UserSettings.get_async_texture_loading_enabled()

func _process_audio_loudness(audio_to_normalize: AudioStreamOGGVorbis):
	var audio_normalizer = HBAudioNormalizer.new()
	loaded_assets["audio_loudness"] = 0.0
	audio_normalizer.set_target_ogg(audio_to_normalize)
	var prev = OS.get_ticks_msec()
	while not audio_normalizer.work_on_normalization():
		if _aborted:
			return
	loaded_assets["audio_loudness"] = audio_normalizer.get_normalization_result()

func _image_from_fs(path):
	if not safe_texture_loading:
		return HBUtils.texture_from_fs_image(path)
	else:
		return HBUtils.image_from_fs(path)

func _task_process() -> bool:
	var audio_normalizer := HBAudioNormalizer.new()
	var original_audio = null
	
	var asset = requested_assets_queue[0]
	var loaded_asset
	match asset:
		"preview":
			if song.preview_image:
				loaded_asset = _image_from_fs(song.get_song_preview_res_path())
		"background":
			if song.background_image:
				loaded_asset = _image_from_fs(song.get_song_background_image_res_path())
		"audio":
			if song.has_audio():
				loaded_asset = song.get_audio_stream()
				var audio_ogg = loaded_asset
				if "do_dsc_audio_split" in requested_assets_queue and not song.youtube_url:
					if loaded_asset is AudioStreamOGGVorbis:
						var channel_count = HBUtils.get_ogg_channel_count(song.get_song_audio_res_path())
						if channel_count >= 4:
							var audio_utils = HBAudioUtils.new()
							audio_utils.split_audio(loaded_asset)
							loaded_asset = audio_utils.get_split_instrumental()
							loaded_assets_mutex.lock()
							loaded_assets["voice"] = audio_utils.get_split_voice()
							loaded_assets_mutex.unlock()
							requested_assets_queue.erase("voice")
					requested_assets_queue.erase("do_dsc_audio_split")
				if "audio_loudness" in requested_assets_queue:
					_process_audio_loudness(audio_ogg)
					requested_assets_queue.erase("audio_loudness")
		"voice":
			if song.voice:
				loaded_asset = song.get_voice_stream()
		"circle_image":
			if song.circle_image:
				loaded_asset = _image_from_fs(song.get_song_circle_image_res_path())
		"circle_logo":
			if song.circle_logo:
				loaded_asset = _image_from_fs(song.get_song_circle_logo_image_res_path())
	if loaded_asset:
		loaded_assets_mutex.lock()
		loaded_assets[asset] = loaded_asset
		loaded_assets_mutex.unlock()
	
	requested_assets_queue.pop_front()
	return requested_assets_queue.size() == 0

func _on_task_finished_processing(data):
	if not safe_texture_loading:
		VisualServer.force_sync()
	for asset_name in data:
		if data[asset_name] is Image:
			var texture = ImageTexture.new()
			texture.create_from_image(data[asset_name], Texture.FLAGS_DEFAULT & ~(Texture.FLAG_MIPMAPS))
			data[asset_name] = texture
	data["song"] = song
	emit_signal("assets_loaded", data)
	if "audio_loudness" in data:
		SongDataCache.update_loudness_for_song(song, data.audio_loudness)

func get_task_output_data():
	return loaded_assets
