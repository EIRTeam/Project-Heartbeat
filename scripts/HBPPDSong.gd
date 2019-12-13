extends HBSong

class_name HBPPDSong

const LOG_NAME = "HBPPDSong"

func _ready():
	pass

static func from_ini(content: String, id: String):
	var dict = HBINIParser.parse(content)
	var song := load("res://scripts/HBPPDSong.gd").new() as HBSong
	song.title = id
	song.artist = "[PPD]"
	if dict.setting.has("authorname"):
		song.creator = dict.setting.authorname
	if dict.setting.has("bpm"):
		song.bpm = float(dict.setting.bpm)
		
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
	var file = File.new()
	file.open("user://ppdtest.json", File.WRITE)
	file.store_string(JSON.print(song.serialize(), "  "))
	
	return song
