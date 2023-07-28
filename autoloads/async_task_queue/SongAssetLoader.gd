extends Node

enum ASSET_TYPES {
	PREVIEW,
	BACKGROUND,
	NOTE_USAGE,
	AUDIO,
	VOICE,
	CIRCLE_IMAGE,
	CIRCLE_LOGO,
	AUDIO_LOUDNESS,
	ASSET_TYPE_MAX
}

var mutex := Mutex.new()

class AudioNormalizationInfo:
	var loudness := 0.0

class SongAudioData:
	var shinobu: ShinobuSoundSource
	var godot_stream: AudioStream

class RefDict:
	extends RefCounted
	var dict: Dictionary
	func _init(_dict: Dictionary):
		dict = _dict
		dict.make_read_only()

class SongAssetCache:
	var song: HBSong
	var assets: Array[WeakRef]
	var variant := -1
	func _init(_song: HBSong, _variant := -1):
		variant = _variant
		song = _song
		assets.resize(ASSET_TYPES.ASSET_TYPE_MAX)

var assets_cache := {}

class AssetLoadToken:
	signal assets_loaded(assets: AssetLoadToken)
	var song: HBSong
	var assets_to_load: Array[ASSET_TYPES]
	# Each key contains semaphores that should be posted when the asset is done loading
	var asset_semaphores := {}
	var mutex := Mutex.new()
	var loaded_asset_count := 0
	var loaded_assets := {}
	var task_id: int
	var variant := -1
	var sprite_set: DIVASpriteSet
	func get_asset(asset: ASSET_TYPES) -> RefCounted:
		return loaded_assets.get(asset, null)

func get_asset_type_dependencies(type: ASSET_TYPES) -> Array[ASSET_TYPES]:
	var deps : Array[ASSET_TYPES] = []
	match type:
		ASSET_TYPES.AUDIO_LOUDNESS:
			deps.push_back(ASSET_TYPES.AUDIO)
	return deps

func _finish_task(token: AssetLoadToken):
	var variant_id := get_variant_id(token.song, token.variant)
	mutex.lock()
	if not variant_id in assets_cache:
		assets_cache[variant_id] = SongAssetCache.new(token.song, token.variant)
	var cache := assets_cache[variant_id] as SongAssetCache
	for asset in token.loaded_assets:
		cache.assets[asset] = weakref(token.loaded_assets[asset])
	mutex.unlock()
	WorkerThreadPool.wait_for_group_task_completion(token.task_id)
	token.assets_loaded.emit(token)

# HACK to allow case insensitive naming of files, fairly expensive so use sparingly
func _case_sensitivity_hack(path: String):
	if path.begins_with("res://"):
		return path
	if OS.get_name() == "linuxbsd":
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

func _image_from_fs(path: String) -> Texture2D:
	if path.begins_with("res://"):
		return load(path)
	var img: Image = Image.load_from_file(path)
	var tex := ImageTexture.create_from_image(img)
	return tex

func _process_audio_loudness(token: AssetLoadToken, audio: ShinobuSoundSource):
	token.mutex.lock()
	var normalization_info := AudioNormalizationInfo.new()
	token.loaded_assets[ASSET_TYPES.AUDIO_LOUDNESS] = normalization_info
	normalization_info.loudness = audio.ebur128_get_loudness()
	token.mutex.unlock()

func _wait_for_asset_dep(token: AssetLoadToken, asset: ASSET_TYPES) -> Variant:
	var out: Variant
	token.mutex.lock()
	out = token.get_asset(asset)
	var semaphore := Semaphore.new()
	if not asset in token.asset_semaphores:
		token.asset_semaphores[asset] = []
	token.asset_semaphores[asset].push_back(semaphore)
	token.mutex.unlock()
	if not out:
		semaphore.wait()
		out = token.get_asset(asset)
	return out
func _load_thread_func(element: int, token: AssetLoadToken):
	var asset: ASSET_TYPES = token.assets_to_load[element]
	
	if token.song is SongLoaderDSC.HBSongMMPLUS and not token.sprite_set:
		if asset in [ASSET_TYPES.PREVIEW, ASSET_TYPES.BACKGROUND, ASSET_TYPES.CIRCLE_IMAGE]:
			token.sprite_set = token.song.get_song_select_sprite_set()
	
	var loaded_asset: RefCounted
	
	match asset:
		ASSET_TYPES.PREVIEW:
			if token.song.preview_image:
				if token.sprite_set:
					for sprite in token.sprite_set.sprites:
						if "SONG_JK" in sprite.name:
							loaded_asset = sprite
				else:
					var asset_path = _case_sensitivity_hack(token.song.get_song_preview_res_path())
					if asset_path:
						loaded_asset = _image_from_fs(asset_path)
		ASSET_TYPES.BACKGROUND:
			if token.song.background_image:
				if token.sprite_set:
					for sprite in token.sprite_set.sprites:
						if "SONG_BG" in sprite.name:
							loaded_asset = sprite
				else:
					var asset_path = _case_sensitivity_hack(token.song.get_song_background_image_res_path())
					if asset_path:
						loaded_asset = _image_from_fs(asset_path)
		ASSET_TYPES.NOTE_USAGE:
			var dict := {}
			for difficulty in token.song.charts:
				dict[difficulty] = token.song.get_chart_note_usage(difficulty)
			loaded_asset = RefDict.new(dict)
		ASSET_TYPES.AUDIO:
			if token.song.has_audio():
				var audio_ogg := token.song.get_audio_stream(token.variant) as AudioStreamOggVorbis
				var song_audio_data := SongAudioData.new()
				song_audio_data.shinobu = Shinobu.register_sound_from_memory(get_variant_id(token.song, token.variant) + "_voice", audio_ogg.get_meta("raw_file_data"))
				song_audio_data.godot_stream = audio_ogg
				if not token.song.youtube_url and token.song.uses_dsc_style_channels() and ASSET_TYPES.VOICE in token.assets_to_load:
					var spb := StreamPeerBuffer.new()
					spb.data_array = audio_ogg.packet_sequence.packet_data
					if HBUtils.get_ogg_channel_count_buff(spb) >= 4:
						var voice_audio_data := song_audio_data
						token.mutex.lock()
						token.loaded_assets[ASSET_TYPES.VOICE] = voice_audio_data
						token.mutex.unlock()
				loaded_asset = song_audio_data
		ASSET_TYPES.AUDIO_LOUDNESS:
			var audio_data: SongAudioData = _wait_for_asset_dep(token, ASSET_TYPES.AUDIO)
			var normalization_info := AudioNormalizationInfo.new()
			normalization_info.loudness = audio_data.shinobu.ebur128_get_loudness()
			loaded_asset = normalization_info
		ASSET_TYPES.VOICE:
			if token.song.voice and not token.song.uses_dsc_style_channels():
				var voice_audio_data := SongAudioData.new()
				var audio_ogg = token.song.get_voice_stream()
				voice_audio_data.shinobu = Shinobu.register_sound_from_memory(get_variant_id(token.song, token.variant) + "_voice", audio_ogg.get_meta("raw_file_data"))
				voice_audio_data.godot_stream = audio_ogg
				loaded_asset = voice_audio_data
		ASSET_TYPES.CIRCLE_IMAGE:
			if token.sprite_set:
				for sprite in token.sprite_set.sprites:
					if "SONG_LOGO" in sprite.name:
						loaded_asset = sprite
			elif token.song.circle_image:
				var asset_path = _case_sensitivity_hack(token.song.get_song_circle_image_res_path())
				if asset_path:
					loaded_asset = _image_from_fs(asset_path)
		ASSET_TYPES.CIRCLE_LOGO:
			if token.song.circle_logo:
				var asset_path = _case_sensitivity_hack(token.song.get_song_circle_logo_image_res_path())
				if asset_path:
					loaded_asset = _image_from_fs(asset_path)
	if loaded_asset:
		token.mutex.lock()
		token.loaded_assets[asset] = loaded_asset
		token.mutex.unlock()
	
	token.mutex.lock()
	token.loaded_asset_count += 1
	for semaphore in token.asset_semaphores.get(asset, []):
		semaphore.post()
	if token.loaded_asset_count == token.assets_to_load.size():
		_finish_task.call_deferred(token)
	token.mutex.unlock()

func get_variant_id(song: HBSong, variant := -1) -> StringName:
	return StringName(song.id + str(variant))

func _has_asset(song: HBSong, asset: ASSET_TYPES, variant := -1) -> bool:
	var variant_id := get_variant_id(song, variant)
	if assets_cache.has(variant_id):
		var asset_cache: SongAssetCache = assets_cache[variant_id] 
		var asset_weak_ref := asset_cache.assets[asset]
		if asset_weak_ref:
			var asset_ref = asset_weak_ref.get_ref()
			if asset_ref and asset_ref.get_reference_count() > 0:
				return true
	return false

func request_asset_load(song: HBSong, assets: Array[ASSET_TYPES], variant := -1) -> AssetLoadToken:
	mutex.lock()
	var token := AssetLoadToken.new()
	token.song = song
	token.variant = variant
	var variant_id := get_variant_id(song, variant)
	# Make sure dependencies are possible
	for asset in assets:
		var deps := get_asset_type_dependencies(asset)
		for dep in deps:
			assert(dep in assets, "Asset type %s requires %s as a dependency" % [ASSET_TYPES.find_key(dep), ASSET_TYPES.find_key(asset)])
	for i in range(assets.size()-1, -1, -1):
		var asset := assets[i]
		var asset_name := ASSET_TYPES.find_key(asset)
		if _has_asset(song, asset):
			assets.remove_at(i)
			var asset_cache: SongAssetCache = assets_cache[variant_id]
			token.loaded_assets[asset] = asset_cache.assets[asset].get_ref()
	
	# If we have all the assets shoot them at the end of the frame
	token.assets_to_load = assets
	if assets.size() == 0 and token.loaded_assets.size() > 0:
		mutex.unlock()
		token.emit_signal.call_deferred(&"assets_loaded", token)
		return token
	var task_id := WorkerThreadPool.add_group_task(_load_thread_func.bind(token), assets.size())
	token.mutex.lock()
	token.task_id = task_id
	token.mutex.unlock()
	mutex.unlock()
	return token
