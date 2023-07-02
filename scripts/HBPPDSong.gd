# Class for a song that comes from PPD
extends HBSong

class_name HBPPDSong

const EXTENDED_PROPERTY_PREFIX = "project_heartbeat_"
const ALLOWED_EXTENDED_PROPERTIES = ["title", "author", "preview_image", "background_image", "youtube_url", "creator"]
var ppd_offset = 0
var guid = ""
var ppd_website_id = ""
var uses_native_video = false

func _init():
	serializable_fields += ["ppd_offset", "guid", "ppd_website_id", "uses_native_video"]
	LOG_NAME = "HBPPDSong"
# Returns a HBPPDSong meta from an ini file
static func from_ini(content: String, id: String, ext_data=null, script="res://scripts/HBPPDSong.gd") -> HBSong:
	var dict = HBINIParser.parse(content)
	var song := load(script).new() as HBSong
	song.title = id
	song.artist = "[PPD]"
	if dict.setting.has("authorname"):
		song.creator = dict.setting.authorname
	if dict.setting.has("bpm"):
		song.bpm = float(dict.setting.bpm)
		
		var bpm_timing_change = HBTimingChange.new()
		bpm_timing_change.bpm = float(dict.setting.bpm)
		song.timing_changes = [bpm_timing_change]
	if dict.setting.has("thumbtimestart"):
		song.preview_start = int(float(dict.setting.thumbtimestart)*1000.0)
	var difficulties = ["easy", "normal", "hard", "extreme"]
	
	var song_settings = dict["setting"]
	
	# For stars we match the first floating point number we can find, fun...
	var star_regex := RegEx.new()
	star_regex.compile("[+-]?([0-9]*[.])?[0-9]+")
	
	for key in song_settings:
		for difficulty in difficulties:
			if key == "difficulty " + difficulty:
				# The things I have to do...
				var regex_result := star_regex.search(song_settings[key])
				var stars_f = 0.0
				if regex_result and regex_result.strings.size() > 0:
					if regex_result.strings[0].is_valid_float():
						stars_f = float(regex_result.strings[0])
				else:
					# Special case for star counts
					for star_char in ["★", "☆"]:
						var stc = song_settings[key].count(star_char)
						if stc == song_settings[key].length():
							stars_f = stc
							break
				if song_settings[key].length() > 0:
					song.charts[difficulty] = {
						"file": difficulty.capitalize() + ".ppd",
						"stars": stars_f
					}

	if dict.setting.has("start"):
		song.start_time = int(float(dict.setting.start) * 1000.0)
	if dict.setting.has("end"):
		song.end_time = int(float(dict.setting.end) * 1000.0)
	if dict.setting.has("guid"):
		song.guid = dict.setting.guid
	# This allows PPD songs to take advantage of PH specific features
	for setting in dict.setting:
		if setting.begins_with(EXTENDED_PROPERTY_PREFIX):
			var property_name = setting.substr(EXTENDED_PROPERTY_PREFIX.length(), setting.length() - EXTENDED_PROPERTY_PREFIX.length())
			if property_name in ALLOWED_EXTENDED_PROPERTIES:
				song.set(property_name, dict.setting[setting])
	
	return song

# If video is enabled for this type of song
func has_video_enabled():
	if super.has_video_enabled():
		return not UserSettings.user_settings.disable_ppd_video

func get_song_video_res_path():
	if uses_native_video:
		if video != "":
			return path.path_join("/%s" % [video])
		else:
			return null
	else:
		return super.get_song_video_res_path()

func line2phrase(line: String):
	var split_l = line.split(":")
	var time = int(float(split_l[0]) * 1000.0)
	var phrase = HBLyricsPhrase.new()
	phrase.time = time
	var lyric = HBLyricsLyric.new()
	lyric.time = time
	if split_l.size() > 0:
		lyric.value = split_l[1]
	phrase.lyrics = [lyric]
	return phrase
func cache_lyrics():
	var lyrics_txt = path.path_join("kasi.txt")
	if FileAccess.file_exists(lyrics_txt):
		var file = FileAccess.open(lyrics_txt, FileAccess.READ)
		var err = FileAccess.get_open_error()
		if err == OK:
			var lyr = []
			var lines = []
			while not file.eof_reached():
				lines.append(file.get_line())
			for i in range(lines.size()):
				if lines[i] and ":" in lines[i]:
					var phrase = line2phrase(lines[i])
					if not phrase.lyrics[0].value.strip_edges() == "":
						if i < lines.size() - 1:
							var next_phrase = line2phrase(lines[i+1])
							phrase.end_time = next_phrase.time
							phrase.lyrics[0].value = phrase.lyrics[0].value.replace("０　", "")
							lyr.append(phrase)
			lyrics = lyr
					
		else:
			Log.log(self, "Error opening lyrics for PPD song %s, error %d" % [id, err])

func get_chart_for_difficulty(difficulty) -> HBChart:
	var chart_path = get_chart_path(difficulty)
	cache_lyrics()
	return PPDLoader.PPD2HBChart(chart_path, bpm, ppd_offset)

func get_meta_path():
	return path.path_join("data.ini")

func get_serialized_type():
	return "PPDSong"

func is_cached(variant := -1):
	if uses_native_video:
		return (video and FileAccess.file_exists(get_song_video_res_path())) and FileAccess.file_exists(get_song_audio_res_path())
	else:
		return super.is_cached(variant)

func get_video_stream(variant := -1):
	if uses_native_video:
		# TODOGD4: Replace This
		var video_stream = VideoStreamTheora.new()
		video_stream.set_file(get_song_video_res_path())
		return video_stream
	else:
		return super.get_video_stream(variant)
