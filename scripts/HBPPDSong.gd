# Class for a song that comes from PPD
extends HBSong

class_name HBPPDSong

const EXTENDED_PROPERTY_PREFIX = "project_heartbeat_"
const ALLOWED_EXTENDED_PROPERTIES = ["title", "author", "preview_image", "background_image", "youtube_url"]
var ppd_offset = 0
var guid = ""
func _ready():
	pass

func _init():
	serializable_fields += ["ppd_offset", "guid"]
# Returns a HBPPDSong meta from an ini file
static func from_ini(content: String, id: String) -> HBSong:
	var dict = HBINIParser.parse(content)
	var song := load("res://scripts/HBPPDSong.gd").new() as HBSong
	song.title = id
	song.artist = "[PPD]"
	if dict.setting.has("authorname"):
		song.creator = dict.setting.authorname
	if dict.setting.has("bpm"):
		song.bpm = float(dict.setting.bpm)
	if dict.setting.has("thumbtimestart"):
		song.preview_start = int(float(dict.setting.thumbtimestart)*1000.0)
	var difficulties = ["easy", "normal", "hard", "extreme"]
	
	var song_settings = dict["setting"]
	
	for key in song_settings:
		for difficulty in difficulties:
			if key == "difficulty " + difficulty:
				if song_settings[key].length() > 0:
					song.charts[difficulty] = {
						"file": difficulty.capitalize() + ".ppd",
						"stars": float(song_settings[key].substr(1, song_settings[key].length()-1))
					}

	if dict.setting.has("start"):
		song.ppd_offset = -int(float(dict.setting.start) * 1000.0)
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
	if .has_video_enabled():
		return not UserSettings.user_settings.disable_ppd_video

func get_chart_for_difficulty(difficulty) -> HBChart:
	var chart_path = get_chart_path(difficulty)
	return PPDLoader.PPD2HBChart(chart_path, bpm, ppd_offset)
func get_meta_path():
	return path.plus_file("data.ini")
func get_serialized_type():
	return "PPDSong"
func is_visible_in_editor():
	return false
