extends Node

const CACHE_PATH = "user://cache.hbdict"
var timer = Timer.new()

func _ready():
	timer.wait_time = 0.5
	timer.connect("timeout", self, "_on_save_cache_timed_out")
	timer.one_shot = true
	add_child(timer)

var song_meta_cache = {}
var audio_normalization_cache = {}
	
func _get_song_audio_path(song: HBSong) -> String:
	if song.youtube_url:
		if song.use_youtube_for_audio:
			if YoutubeDL.get_cache_status(song.youtube_url, false, true) == YoutubeDL.CACHE_STATUS.OK:
				return YoutubeDL.get_audio_path(YoutubeDL.get_video_id(song.youtube_url))
	return song.get_song_audio_res_path()
	
func update_loudness_for_song(song: HBSong, loudness: float):
	var audio_cache = HBAudioLoudnessCacheEntry.new()
	var file = File.new()
	audio_cache.modified = file.get_modified_time(_get_song_audio_path(song))
	audio_cache.loudness = loudness
	audio_normalization_cache[song.id] = audio_cache
	save_cache()
func update_cache_for_song(song: HBSong):
	var song_meta_path = song.get_meta_path()
	
	var cache = HBSongMetaCacheEntry.new()
	
	var file = File.new()
	cache.modified = file.get_modified_time(song_meta_path)
	cache.meta = song
	song_meta_cache[song.id] = cache
	
	save_cache()
	
func load_cache():
	var file = File.new()
	if file.file_exists(CACHE_PATH):
		file.open(CACHE_PATH, File.READ)
		var meta_caches = file.get_var()
		if meta_caches is Dictionary:
			for song_id in meta_caches:
				var r = HBSerializable.deserialize(meta_caches[song_id])
				if r is HBSongMetaCacheEntry:
					song_meta_cache[song_id] = r
				else:
					Log.log(self, "Error deserializing cache for song %s", [song_id])
					break
		var audio_normalization_caches = file.get_var()
		if meta_caches is Dictionary:
			for song_id in audio_normalization_caches:
				var r = HBSerializable.deserialize(audio_normalization_caches[song_id])
				if r is HBAudioLoudnessCacheEntry:
					audio_normalization_cache[song_id] = r
				else:
					Log.log(self, "Error deserializing audio normalization cache for song %s", [song_id])
					break
		else:
			Log.log(self, "Error loading cache", Log.LogLevel.ERROR)
		file.close()
	
func _on_save_cache_timed_out():
	var file = File.new()
	file.open(CACHE_PATH, File.WRITE)
	var serialized_metas = {}
	for song_id in song_meta_cache:
		var meta_cache = song_meta_cache[song_id] as HBSongMetaCacheEntry
		var serialized_meta = meta_cache.serialize()
		serialized_metas[song_id] = serialized_meta
	file.store_var(serialized_metas)
	
	var serialized_audio_caches = {}
	for song_id in audio_normalization_cache:
		var meta_cache = audio_normalization_cache[song_id] as HBAudioLoudnessCacheEntry
		var serialized_meta = meta_cache.serialize()
		serialized_audio_caches[song_id] = serialized_meta
	
	file.store_var(serialized_audio_caches)
	
	file.close()
	
	
func save_cache():
	timer.start(0)

func is_song_meta_cached(song_id, meta_path: String):
	if song_id in song_meta_cache:
		var file = File.new()
		var modified = file.get_modified_time(meta_path)
		return modified == song_meta_cache[song_id].modified
	return false

func get_cached_meta(song_id: String):
	return song_meta_cache[song_id].meta

func is_song_audio_loudness_cached(song: HBSong):
	if song.id in audio_normalization_cache:
		var file = File.new()
		var modified = file.get_modified_time(_get_song_audio_path(song))
		return modified == audio_normalization_cache[song.id].modified
	return false

func get_song_volume_offset(song: HBSong):
	return HBAudioNormalizer.get_offset_from_loudness(audio_normalization_cache[song.id].loudness)