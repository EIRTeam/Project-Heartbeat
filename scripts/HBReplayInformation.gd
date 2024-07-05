extends HBSerializable

class_name HBReplayInformation

var game_info: HBGameInfo
var song_ugc_id: String
var song_ugc_service: String
var song_title: String
var song_title_romanized: String
var user_id: String
var user_persona_name: String
var user_service: String
var chart_hash: String

func get_serialized_type():
	return "ReplayInformation"

func _init():
	serializable_fields += [
		"game_info", "song_ugc_id", "song_ugc_service", "song_title",
		"song_title_romanized", "user_id", "user_persona_name", "user_service",
		"chart_hash"
	]

static func from_game_info(game_info: HBGameInfo) -> HBReplayInformation:
	var out := HBReplayInformation.new()
	
	var song := game_info.get_song() as HBSong
	out.game_info = game_info
	if song.comes_from_ugc():
		out.song_ugc_id = str(song.ugc_id)
		out.song_ugc_service = song.ugc_service_name
	out.song_title = song.title
	out.song_title_romanized = song.romanized_title
	
	if Steamworks.is_valid():
		out.user_service = "steam"
		var local_user := Steamworks.user.get_local_user()
		out.user_id = str(local_user.steam_id)
		out.user_persona_name = local_user.persona_name
	else:
		var user_name_candidate := OS.get_environment("USERNAME")
		if not user_name_candidate.is_empty():
			out.user_id = user_name_candidate
			out.user_persona_name = user_name_candidate
		else:
			out.user_persona_name = "Unknown"
		out.user_service = "local"
	
	out.chart_hash = song.generate_chart_hash(game_info.difficulty)
	
	return out
