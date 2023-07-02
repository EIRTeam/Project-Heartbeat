extends HBTask

class_name SongAssetLoadAsyncTask

signal assets_loaded(assets)

var requested_assets: Array
var requested_assets_queue: Array
var song: HBSong
var loaded_assets: Dictionary = {}

var loaded_assets_mutex := Mutex.new()

var safe_texture_loading = false

var variant := -1

func _init(_requested_assets: Array, _song: HBSong, _variant := -1):
	super()
	requested_assets = _requested_assets
	requested_assets_queue = _requested_assets.duplicate(true)
	song = _song
	variant = _variant

func _process_audio_loudness(audio_to_normalize: AudioStreamOggVorbis):
	var audio_normalizer = HBAudioNormalizer.new()
	loaded_assets["audio_loudness"] = 0.0
	audio_normalizer.set_target_ogg(audio_to_normalize)
	while not audio_normalizer.work_on_normalization():
		if _aborted:
			return
	loaded_assets["audio_loudness"] = audio_normalizer.get_normalization_result()

func _image_from_fs(path):
	return HBUtils.image_from_fs(path)

# HACK to allow case insensitive naming of files, fairly expensive so use sparingly
func _case_sensitivity_hack(path: String):
	if path.begins_with("res://"):
		return path
	if OS.get_name() == "X11":
		var file_name = path.get_file().to_lower()
		var out_path = null
		if FileAccess.file_exists(path):
			out_path = path
		else:
			var dir := DirAccess.open(path.get_base_dir())
			if DirAccess.get_open_error() == OK:
				dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
				var dir_name = dir.get_next()
				while dir_name != "":
					if not dir.current_is_dir():
						if dir_name.to_lower() == file_name.to_lower():
							out_path = HBUtils.join_path(path.get_base_dir(), dir_name)
							break
					dir_name = dir.get_next()
		return out_path
	else:
		return path

var sprite_set: DIVASpriteSet


func _task_process() -> bool:
	var asset = requested_assets_queue[0]
	var loaded_asset
	if song is SongLoaderDSC.HBSongMMPLUS and not sprite_set:
		if asset in ["preview", "background", "circle_image"]:
			sprite_set = song.get_song_select_sprite_set()
	
	match asset:
		"preview":
			if song.preview_image:
				if sprite_set:
					for sprite in sprite_set.sprites:
						if "SONG_JK" in sprite.name:
							loaded_asset = sprite
				else:
					var asset_path = _case_sensitivity_hack(song.get_song_preview_res_path())
					if asset_path:
						loaded_asset = _image_from_fs(asset_path)
		"background":
			if song.background_image:
				if sprite_set:
					for sprite in sprite_set.sprites:
						if "SONG_BG" in sprite.name:
							loaded_asset = sprite
				else:
					var asset_path = _case_sensitivity_hack(song.get_song_background_image_res_path())
					if asset_path:
						loaded_asset = _image_from_fs(asset_path)
		"note_usage":
			loaded_asset = {}
			for difficulty in song.charts:
				loaded_asset[difficulty] = song.get_chart_note_usage(difficulty)
		"audio":
			if song.has_audio():
				loaded_asset = song.get_audio_stream(variant)
				var audio_ogg := loaded_asset as AudioStreamOggVorbis
				if not song.youtube_url and song.uses_dsc_style_channels() and "voice" in requested_assets_queue:
					var spb := StreamPeerBuffer.new()
					spb.data_array = audio_ogg.packet_sequence.packet_data
					if HBUtils.get_ogg_channel_count_buff(spb) >= 4:
						loaded_assets["voice"] = audio_ogg
						loaded_assets["voice_shinobu"] = audio_ogg.get_meta("raw_file_data")
					requested_assets_queue.erase("voice")
				if "audio_loudness" in requested_assets_queue:
					_process_audio_loudness(audio_ogg)
					requested_assets_queue.erase("audio_loudness")
				loaded_assets["audio_shinobu"] = audio_ogg.get_meta("raw_file_data")
		"voice":
			if song.voice:
				loaded_asset = song.get_voice_stream()
				loaded_assets["voice_shinobu"] = loaded_asset.get_meta("raw_file_data")
		"circle_image":
			if sprite_set:
				for sprite in sprite_set.sprites:
					if "SONG_LOGO" in sprite.name:
						loaded_asset = sprite
			elif song.circle_image:
				var asset_path = _case_sensitivity_hack(song.get_song_circle_image_res_path())
				if asset_path:
					loaded_asset = _image_from_fs(asset_path)
		"circle_logo":
			if song.circle_logo:
				var asset_path = _case_sensitivity_hack(song.get_song_circle_logo_image_res_path())
				if asset_path:
					loaded_asset = _image_from_fs(asset_path)
	if loaded_asset:
		loaded_assets_mutex.lock()
		loaded_assets[asset] = loaded_asset
		loaded_assets_mutex.unlock()
	
	requested_assets_queue.pop_front()
	return requested_assets_queue.size() == 0

func _on_task_finished_processing(data):
	print("FINISHED PROCESSING")
	for asset_name in data:
		if data[asset_name] is Image:
			var texture = ImageTexture.create_from_image(data[asset_name]) #,HBGame.platform_settings.texture_mode
			data[asset_name] = texture
		elif data[asset_name] is DIVASpriteSet.DIVASprite:
			data[asset_name].allocate()
	data["song"] = song
	emit_signal("assets_loaded", data)
	if "audio_loudness" in data:
		SongDataCache.update_loudness_for_song(song, data.audio_loudness)

func get_task_output_data():
	return loaded_assets
