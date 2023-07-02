extends Node

const CACHE_PATH = "user://cache.json"
var timer = Timer.new()
const LOG_NAME = "SongDataCache"
func _ready():
	timer.wait_time = 0.5
	timer.connect("timeout", Callable(self, "_on_save_cache_timed_out"))
	timer.one_shot = true
	add_child(timer)

const CURRENT_CACHE_VERSION = 1

var song_cache_mutex = Mutex.new()
var song_meta_cache = {}
var audio_normalization_cache = {}
	
func _get_song_audio_path(song) -> String:
	if song.youtube_url:
		if song.use_youtube_for_audio:
			if YoutubeDL.get_cache_status(song.youtube_url, false, true) == YoutubeDL.CACHE_STATUS.OK:
				return YoutubeDL.get_audio_path(YoutubeDL.get_video_id(song.youtube_url))
	return song.get_song_audio_res_path()
	
func update_loudness_for_song(song, loudness: float):
	if FileAccess.file_exists(_get_song_audio_path(song)):
		var audio_cache = HBAudioLoudnessCacheEntry.new()
		audio_cache.modified = FileAccess.get_modified_time(_get_song_audio_path(song))
		audio_cache.loudness = loudness
		audio_normalization_cache[song.id] = audio_cache
		save_cache()
	
func load_cache():
	if FileAccess.file_exists(CACHE_PATH):
		var file = FileAccess.open(CACHE_PATH, FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			var text = file.get_as_text()
			var test_json_conv = JSON.new()
			var result_err := test_json_conv.parse(text)
			if result_err != OK:
				prints("Error loading cache", test_json_conv.get_error_line(), test_json_conv.get_error_message())
				return
			
			var has_version = "__version" in test_json_conv.data
			if not has_version or (has_version and test_json_conv.data.__version < CURRENT_CACHE_VERSION):
				Log.log(self, "Local cache is old, ignoring it...")
				return
			if "song_meta" in test_json_conv.data:
				var meta_caches = test_json_conv.data.song_meta
				if meta_caches is Dictionary:
					for song_id in meta_caches:
						var r = HBSerializable.deserialize(meta_caches[song_id])
						if r is HBSongCacheEntry:
							r.song_id = song_id
							song_meta_cache[song_id] = r
						else:
							Log.log(self, "Error deserializing cache for song %s", [song_id])
							break
			if "audio_normalization" in test_json_conv.data:
				var audio_normalization_caches = test_json_conv.data.audio_normalization
				for song_id in audio_normalization_caches:
					var r = HBSerializable.deserialize(audio_normalization_caches[song_id])
					if r is HBAudioLoudnessCacheEntry:
						audio_normalization_cache[song_id] = r
					else:
						Log.log(self, "Error deserializing audio normalization cache for song %s", [song_id])
						break
			Log.log(self, "Finished loading cache...")
			file.close()
	
func _on_save_cache_timed_out():
	var file = FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	var serialized_metas = {}
	for song_id in song_meta_cache:
		var meta_cache = song_meta_cache[song_id] as HBSongCacheEntry
		var serialized_meta = meta_cache.serialize()
		serialized_metas[song_id] = serialized_meta
	
	var serialized_audio_caches = {}
	for song_id in audio_normalization_cache:
		var meta_cache = audio_normalization_cache[song_id] as HBAudioLoudnessCacheEntry
		var serialized_meta = meta_cache.serialize()
		serialized_audio_caches[song_id] = serialized_meta
	
	var text = JSON.stringify({
		"__version": CURRENT_CACHE_VERSION,
		"song_meta": serialized_metas,
		"audio_normalization": serialized_audio_caches
	})
	file.store_string(text)
	
	file.close()
	
	
func save_cache():
	timer.start(0)

func get_cache_for_song(song):
	if not song.id in song_meta_cache:
		var new_cache = HBSongCacheEntry.new()
		new_cache.song_id = song.id
		song_cache_mutex.lock()
		song_meta_cache[song.id] = new_cache
		song_cache_mutex.unlock()
		return new_cache
	else:
		return song_meta_cache[song.id]

func is_song_audio_loudness_cached(song):
	if song.id in audio_normalization_cache:
		if FileAccess.file_exists(_get_song_audio_path(song)):
			var modified = FileAccess.get_modified_time(_get_song_audio_path(song))
			return modified == audio_normalization_cache[song.id].modified
	
	return false

func get_song_volume_offset(song):
	if is_song_audio_loudness_cached(song):
		return HBAudioNormalizer.get_offset_from_loudness(audio_normalization_cache[song.id].loudness)
	
	return 0.0

func clear_cache():
	song_meta_cache = {}
	_on_save_cache_timed_out()
