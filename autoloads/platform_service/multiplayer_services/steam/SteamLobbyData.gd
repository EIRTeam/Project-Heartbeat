class_name HeartbeatSteamLobbyData

var song_title: String
var song_id: String
var is_song_from_ugc: bool
var song_ugc_id: int
var song_variant: int
var difficulty: String
var lobby_name: String

func to_dictionary() -> Dictionary:
	return {
		"song_title": song_title,
		"song_id": song_id,
		"is_song_from_ugc": is_song_from_ugc,
		"song_ugc_id": song_ugc_id,
		"song_variant": song_variant,
		"difficulty": difficulty,
		"lobby_name": lobby_name,
	}

static func from_dictionary(dict: Dictionary) -> HeartbeatSteamLobbyData:
	var out := HeartbeatSteamLobbyData.new()
	out.song_title = dict.get("song_title", "")
	out.song_id = dict.get("song_id", "")
	out.is_song_from_ugc = dict.get("is_song_from_ugc", false)
	out.song_ugc_id = dict.get("song_ugc_id", "")
	out.song_variant = dict.get("song_variant", "")
	out.difficulty = dict.get("difficulty", "")
	out.lobby_name = dict.get("lobby_name", "")
	return out
