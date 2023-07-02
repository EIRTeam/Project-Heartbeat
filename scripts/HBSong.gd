# Base class for all song meta types
extends HBSerializable

class_name HBSong

# warning-ignore:unused_signal
signal song_cached

var LOG_NAME = "HBSong"

# Because user loaded songs don't have .import files we have to load stuff like songs
# differently, seriously???
enum SONG_FS_ORIGIN {
	BUILT_IN,
	USER
}


var title := ""
var romanized_title := ""
var artist := ""
var artist_alias := ""
var composers = []: set = set_composers
var writers = []: set = set_writers
var vocals = []: set = set_vocals
var audio = ""
var video = ""
var voice = ""
var creator = ""
var original_title = ""
var bpm = 150.0: set = set_bpm, get = get_bpm
var _bpm_proxy: float
var bpm_string = "150"
var preview_start = 0
var preview_end = -1
var charts = {}
var preview_image = ""
var background_image = ""
var circle_image = ""
var circle_logo = ""
var youtube_url = ""
var use_youtube_for_audio = true
var use_youtube_for_video = true
var ugc_service_name = ""
var ugc_id = 0
var allows_intro_skip = false
var intro_skip_min_time = 30.0
var start_time = 0
var end_time = -1
var volume = 1.0
var hide_artist_name = false
var lyrics = []
var show_epilepsy_warning = false
var has_audio_loudness := false
var audio_loudness := 0.0
var song_variants = []
var sections = []
var skin_ugc_id := 0
var timing_changes := []: set = set_timing_changes

# not serialized
var loader = ""
var _comes_from_ugc = false
var id: String
var path: String
var _note_usage_cache = {}
var _note_usage_cache_lock = Mutex.new()
var _added_time: int = 0
var _released_time: int = 0
var _updated_time: int = 0

func get_leaderboard_name(difficulty: String):
	return id + "_%s" % difficulty
func get_serialized_type():
	return "Song"

func _init():
	serializable_fields += ["title", "romanized_title", "artist", "artist_alias", 
	"composers", "vocals", "writers", "audio", "creator", "original_title", "bpm", "bpm_string",
	"preview_start", "preview_end", "charts", "preview_image", "background_image", "voice", 
	"circle_image", "circle_logo", "youtube_url", "use_youtube_for_video", "use_youtube_for_audio",
	"video", "ugc_service_name", "ugc_id", "allows_intro_skip", "intro_skip_min_time", "start_time",
	"end_time", "volume", "hide_artist_name", "lyrics", "show_epilepsy_warning", "has_audio_loudness",
	"audio_loudness", "song_variants", "sections", "skin_ugc_id", "timing_changes"]
	
	update_bpm_string()

func get_meta_string():
	var song_meta = []
	if writers.size() > 0:
		var writer_text = tr("Written by: ")
		song_meta.append(writer_text + ", ".join(PackedStringArray(writers)))
	if vocals.size() > 0 and vocals[0] != "":
		var vocals_text = tr("Vocals by: ")
		song_meta.append(vocals_text + ", ".join(PackedStringArray(vocals)))
	if composers.size() > 0:
		var composers_text = tr("Composed by: ")
		song_meta.append(composers_text + ", ".join(PackedStringArray(composers)))
	if creator != "":
		song_meta.append(tr("Chart by: %s") % creator)
	return song_meta
	
func get_volume_db() -> float:
	return linear_to_db(volume)
	
func get_fs_origin():
	if path.begins_with("res://"):
		return SONG_FS_ORIGIN.BUILT_IN
	return SONG_FS_ORIGIN.USER 
	
func get_chart_path(difficulty):
	return path.path_join("/%s" % [charts[difficulty].file])
	
func get_song_audio_res_path():
	if audio:
		return path.path_join("/%s" % [audio])
	else:
		return path.path_join(HBUtils.get_valid_filename(title)) + ".ogg"
		
func get_song_voice_res_path():
	if voice:
		return path.path_join("/%s" % [voice])
	else:
		return path.path_join("/%s" % ["voice.ogg"])
func get_song_preview_res_path():
	if preview_image != "":
		return path.path_join("/%s" % [preview_image])
	else:
		return null

# Some songs might put vocals in the same file as they put instrumental, in a non-standard
# ogg channel layout of [instrumental_l, instrumental_r, voice_l, voice_r] enabling this
# will make the game attempt to extract a voice when loading the oggs
func uses_dsc_style_channels() -> bool:
	return false
func get_song_background_image_res_path():
	if background_image != "":
		return path.path_join("/%s" % [background_image])
	else:
		return "res://graphics/background.png"
		
func get_song_circle_image_res_path():
	if circle_image != "":
		return path.path_join("/%s" % [circle_image])
	else:
		return null
		
func get_song_video_res_path():
	if video != "":
		return path.path_join("/%s" % [video])
	else:
		return null
func get_song_circle_logo_image_res_path():
	if circle_logo != "":
		return path.path_join("/%s" % [circle_logo])
	else:
		return null
		
func get_meta_path():
	return path.path_join("song.json")
	
		
# If video is enabled for this type of song
func has_video_enabled():
	if HBGame.platform_settings is HBPlatformSettingsSwitch:
		return false
	return not UserSettings.user_settings.disable_video
		
func is_cached(variant=-1):
	var use_video = use_youtube_for_video
	if not has_video_enabled():
		use_video = false
	if variant != -1 and song_variants:
		return (song_variants[variant] as HBSongVariantData).is_cached(use_video)
	if youtube_url:
		return YoutubeDL.get_cache_status(youtube_url, use_video, use_youtube_for_audio) == YoutubeDL.CACHE_STATUS.OK
	elif audio:
		return true
	else:
		return false

# returns YTDL cache status (use is_cached instead of this)
func get_cache_status():
	return YoutubeDL.get_cache_status(youtube_url, use_youtube_for_video, use_youtube_for_audio)

func get_audio_stream(variant := -1):
	var audio_path = get_song_audio_res_path()
	if youtube_url:
		if use_youtube_for_audio:
			var variant_url = get_variant_data(variant).variant_url
			if YoutubeDL.get_cache_status(get_variant_data(variant).variant_url, false, true) == YoutubeDL.CACHE_STATUS.OK:
				audio_path = YoutubeDL.get_audio_path(YoutubeDL.get_video_id(variant_url))
			else:
				Log.log(self, "Tried to get audio stream from an uncached song!!")
	return HBUtils.load_ogg(audio_path)
	
# Return the canonical text to use for sorting
# It goes in this order:
# Circle name (if a circle logo is present) -> Artist alias -> artist
func get_artist_sort_text():
	if circle_logo and artist:
		return artist
	elif artist_alias:
		return artist_alias
	elif artist:
		return artist
	else:
		return ""
func get_video_stream(variant := -1):
	var video_path = get_song_video_res_path()
	if use_youtube_for_video and not youtube_url.is_empty():
		if is_cached(variant):
			if variant == -1 or song_variants[variant].audio_only:
				video_path = YoutubeDL.get_video_path(YoutubeDL.get_video_id(youtube_url))
			else:
				video_path = YoutubeDL.get_video_path(YoutubeDL.get_video_id(song_variants[variant].variant_url))
		else:
			Log.log(self, "Tried to get video stream from an uncached song!!")
			return null
	print("Loading video stream ", video_path)
	
	if video_path:
		var video_stream = VideoStream.new()
		video_stream.set_file(video_path)
		
		return video_stream
	else:
		return null

func get_voice_stream():
	return HBUtils.load_ogg(get_song_voice_res_path())
	
func save_song():
	# Ensure song directory exists
	DirAccess.make_dir_recursive_absolute(path)
	
	save_to_file(get_meta_path())

func cache_data(variant := -1):
	if youtube_url:
		return YoutubeDL.cache_song(self, variant)

func has_audio():
	if audio != "" or (use_youtube_for_audio and is_cached()):
		return true
	else:
		return false

func get_visible_title(variant := -1) -> String:
	var rt = ""
	if UserSettings.user_settings.romanized_titles_enabled and romanized_title:
		rt = get_sanitized_field("romanized_title")
	else:
		rt = get_sanitized_field("title")
	if variant != -1:
		rt += " (%s)" % [get_variant_data(variant).variant_name]
	return rt

func comes_from_ugc():
	return _comes_from_ugc

func get_max_score():
	var stars = 0
	for chart in charts:
		stars = max(stars, charts[chart].stars)
	return stars

func get_min_score():
	var stars = 0
	if charts.size() > 0:
		stars = charts.values()[0].stars
		for chart in charts:
			stars = min(stars, charts[chart].stars)
	return -1

func get_chart_for_difficulty(difficulty) -> HBChart:
	var chart_path = get_chart_path(difficulty)
	var file = FileAccess.open(chart_path, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var result = test_json_conv.data
	var chart = HBChart.new()
	if not result:
		return null
	chart.deserialize(result, self)
	return chart

func is_chart_note_usage_known(difficulty: String):
	if "note_usage" in charts[difficulty]:
		return true
	else:
		var cache = SongDataCache.get_cache_for_song(self) as HBSongCacheEntry
		return cache.is_note_usage_cached(difficulty)

# Same as above but for all charts
func is_chart_note_usage_known_all():
	for chart in charts:
		if not is_chart_note_usage_known(chart):
			return false
	return true

# Returns note usage, used in main menu badges
func get_chart_note_usage(difficulty: String):
	# HACKish...
	if not FileAccess.file_exists(get_chart_path(difficulty)):
		return []
	var cache = SongDataCache.get_cache_for_song(self) as HBSongCacheEntry
	if difficulty in charts:
		if "note_usage" in charts[difficulty]:
			return charts[difficulty].note_usage
	if cache.is_note_usage_cached(difficulty):
		return cache.get_note_usage(difficulty)
	var chart = get_chart_for_difficulty(difficulty)
	var notes_used = chart.get_note_usage()
	cache.update_note_usage(difficulty, notes_used)
	SongDataCache.save_cache()
	return notes_used

func generate_chart_hash(chart: String) -> String:
	if chart in charts:
		var chart_p := get_chart_path(chart) as String
		var f := FileAccess.open(chart_p, FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			return f.get_as_text().sha1_text()
	return ""

func save_chart_info():
	if not SongDataCache.is_song_audio_loudness_cached(self):
		var norm = HBAudioNormalizer.new()
		norm.set_target_ogg(get_audio_stream())
		print("Loudness cache not found, normalizing...")
		while not norm.work_on_normalization():
			pass
		var res = norm.get_normalization_result()
		SongDataCache.update_loudness_for_song(self, res)
	
	has_audio_loudness = true
	audio_loudness = SongDataCache.audio_normalization_cache[id].loudness
	
	for difficulty in charts:
		charts[difficulty]["hash"] = generate_chart_hash(difficulty)
		var curr_chart = get_chart_for_difficulty(difficulty) as HBChart
		charts[difficulty]["max_score"] = curr_chart.get_max_score()
		charts[difficulty]["note_usage"] = curr_chart.get_note_usage()
	save_song()

func set_writers(value):
	writers = value
	for i in range(writers.size()-1, -1, -1):
		if (writers[i] as String).strip_edges().is_empty():
			writers.remove_at(i)
			
func set_composers(value):
	composers = value
	for i in range(composers.size()-1, -1, -1):
		if (composers[i] as String).strip_edges().is_empty():
			composers.remove_at(i)
			
func set_vocals(value):
	vocals = value
	for i in range(vocals.size()-1, -1, -1):
		if (vocals[i] as String).strip_edges().is_empty():
			vocals.remove_at(i)

func get_variant_offset(variant := -1) -> int:
	if variant == -1:
		return 0
	else:
		return (song_variants[variant] as HBSongVariantData).variant_offset - start_time

func get_variant_data(variant := -1):
	if variant < 0:
		var d = HBSongVariantData.new()
		d.variant_url = youtube_url
		d.variant_normalization = audio_loudness
		d.audio_only = !use_youtube_for_video
		return d
	else:
		return song_variants[variant]

func get_audio_stream_start_time(variant := -1):
	if variant == -1:
		return start_time
	else:
		return song_variants[variant].variant_offset - start_time
		
func get_video_offset(variant := -1):
	if variant == -1 or song_variants[variant].audio_only:
		return -0.0
	else:
		return song_variants[variant].variant_offset

func set_timing_changes(p_timing_changes: Array):
	timing_changes = p_timing_changes
	
	update_bpm_string()

func set_bpm(p_bpm: float):
	bpm = p_bpm
	_bpm_proxy = p_bpm
	
	update_bpm_string()

func get_bpm() -> float:
	return _bpm_proxy

func update_bpm_string():
	var bpm_range = [INF, -INF]
	for timing_change in timing_changes:
		bpm_range = [ \
			min(timing_change.bpm, bpm_range[0]), \
			max(timing_change.bpm, bpm_range[1])  \
		]
	
	if not timing_changes:
		if bpm:
			bpm_string = "%d" % bpm
	else:
		_bpm_proxy = timing_changes[0].bpm
		
		if bpm_range[0] != bpm_range[1]:
			bpm_string = "%s-%s" % [str(bpm_range[0]), str(bpm_range[1])]
		else:
			bpm_string = "%s" % str(bpm_range[0])
