# Base class for all song meta types
extends HBSerializable

class_name HBSong

const LOG_NAME = "HBSong"

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
var composers = []
var writers = []
var vocals = []
var audio = ""
var video = ""
var voice = ""
var creator = ""
var original_title = ""
var bpm = 150.0
var preview_start = 0
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

# not serialized
var loader = ""
var _comes_from_ugc = false
var id: String
var path: String

func get_leaderboard_name(difficulty: String):
	return id + "_%s" % difficulty
func get_serialized_type():
	return "Song"

func _init():
	serializable_fields += ["title", "romanized_title", "artist", "artist_alias", 
	"composers", "vocals", "writers", "audio", "creator", "original_title", "bpm",
	"preview_start", "charts", "preview_image", "background_image", "voice", 
	"circle_image", "circle_logo", "youtube_url", "use_youtube_for_video", "use_youtube_for_audio",
	"video", "ugc_service_name", "ugc_id", "allows_intro_skip", "intro_skip_min_time", "start_time",
	"end_time", "volume"]

func get_meta_string():
	var song_meta = []
	if writers.size() > 0:
		var writer_text = tr("Written by: ")
		song_meta.append(writer_text + PoolStringArray(writers).join(", "))
	if vocals.size() > 0 and vocals[0] != "":
		var vocals_text = tr("Vocals by: ")
		song_meta.append(vocals_text + PoolStringArray(vocals).join(", "))
	if composers.size() > 0:
		var composers_text = tr("Composed by: ")
		song_meta.append(composers_text + PoolStringArray(composers).join(", "))
	if creator != "":
		song_meta.append(tr("Chart by: %s") % creator)
	return song_meta
	
func get_volume_db() -> float:
	return linear2db(volume)
	
func get_fs_origin():
	if path.begins_with("res://"):
		return SONG_FS_ORIGIN.BUILT_IN
	return SONG_FS_ORIGIN.USER 
	
func get_chart_path(difficulty):
	return path.plus_file("/%s" % [charts[difficulty].file])
	
func get_song_audio_res_path():
	if audio:
		return path.plus_file("/%s" % [audio])
	else:
		return path.plus_file(HBUtils.get_valid_filename(title)) + ".ogg"
		
func get_song_voice_res_path():
	if voice:
		return path.plus_file("/%s" % [voice])
	else:
		return path.plus_file("/%s" % ["voice.ogg"])
func get_song_preview_res_path():
	if preview_image != "":
		return path.plus_file("/%s" % [preview_image])
	else:
		return null
		
func is_visible_in_editor():
	return true
		
func get_song_background_image_res_path():
	if background_image != "":
		return path.plus_file("/%s" % [background_image])
	else:
		return "res://graphics/background.png"
		
func get_song_circle_image_res_path():
	if circle_image != "":
		return path.plus_file("/%s" % [circle_image])
	else:
		return null
		
func get_song_video_res_path():
	if video != "":
		return path.plus_file("/%s" % [video])
	else:
		return null
func get_song_circle_logo_image_res_path():
	if circle_logo != "":
		return path.plus_file("/%s" % [circle_logo])
	else:
		return null
		
func get_meta_path():
	return path.plus_file("song.json")
	
		
# If video is enabled for this type of song
func has_video_enabled():
	return not UserSettings.user_settings.disable_video
		
func is_cached():
	var use_video = use_youtube_for_video
	if not has_video_enabled():
		use_video = false
	if youtube_url:
		return YoutubeDL.get_cache_status(youtube_url, use_video, use_youtube_for_audio) == YoutubeDL.CACHE_STATUS.OK
	elif audio:
		return true
	else:
		return false

# returns YTDL cache status (use is_cached instead of this)
func get_cache_status():
	return YoutubeDL.get_cache_status(youtube_url, use_youtube_for_video, use_youtube_for_audio)

func get_audio_stream():
	var audio_path = get_song_audio_res_path()
	if get_fs_origin() == SONG_FS_ORIGIN.BUILT_IN:
		return load(audio_path)
	else:
		if youtube_url:
			if use_youtube_for_audio:
				if YoutubeDL.get_cache_status(youtube_url, false, true) == YoutubeDL.CACHE_STATUS.OK:
					audio_path = YoutubeDL.get_audio_path(YoutubeDL.get_video_id(youtube_url))
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
func get_video_stream():
	var video_path = get_song_video_res_path()
	if use_youtube_for_video:
		if is_cached():
			video_path = YoutubeDL.get_video_path(YoutubeDL.get_video_id(youtube_url))
		else:
			Log.log(self, "Tried to get video stream from an uncached song!!")
			return null
	print("Loading video stream ", video_path)
	
	var video_stream = VideoStreamGDNative.new()
	video_stream.set_file(video_path)
	
	return video_stream
func get_voice_stream():
	if get_fs_origin() == SONG_FS_ORIGIN.BUILT_IN:
		return load(get_song_voice_res_path())
	else:
		return HBUtils.load_ogg(get_song_voice_res_path())
	
func save_song():
	# Ensure song directory exists
	var dir := Directory.new()
	dir.make_dir_recursive(path)
	
	save_to_file(get_meta_path())

func cache_data():
	if youtube_url:
		return YoutubeDL.cache_song(self)

func has_audio():
	if audio != "" or (use_youtube_for_audio and is_cached()):
		return true
	else:
		return false

func get_visible_title() -> String:
	if UserSettings.user_settings.romanized_titles_enabled and romanized_title:
		return romanized_title
	else:
		return title

func comes_from_ugc():
	return _comes_from_ugc

func get_max_score():
	var stars = 0
	for chart in charts:
		stars = max(stars, charts[chart].stars)
	return stars

func get_chart_for_difficulty(difficulty) -> HBChart:
	var chart_path = get_chart_path(difficulty)
	var file = File.new()
	file.open(chart_path, File.READ)
	var result = JSON.parse(file.get_as_text()).result
	var chart = HBChart.new()
	chart.deserialize(result)
	return chart
