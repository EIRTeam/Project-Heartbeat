# Class for a song that comes from PPD
extends HBSong

class_name HBPPDSong

func _ready():
	pass

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
		song.start_time = max(int(float(dict.setting.start) * 1000.0), 0)
	if dict.setting.has("end"):
		song.end_time = int(float(dict.setting.end) * 1000.0)
	var file = File.new()
	file.open("user://ppdtest.json", File.WRITE)
	file.store_string(JSON.print(song.serialize(), "  "))
	
	return song
# If video is enabled for this type of song
func has_video_enabled():
	if .has_video_enabled():
		return not UserSettings.user_settings.disable_ppd_video
