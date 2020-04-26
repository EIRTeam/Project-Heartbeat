# This class holds information regarding a game session that was played, and also
# doubles as a configuration class
extends HBSerializable

class_name HBGameInfo

enum GAME_SESSION_TYPE {
	OFFLINE,
	MULTIPLAYER
}

var game_session_type: int = GAME_SESSION_TYPE.OFFLINE
var time: int = 0
var result: HBResult = HBResult.new()
var modifiers = []
var used_autoplay = false
var song_id = ""
var difficulty = ""
func _init():
	._init()
	time = OS.get_unix_time()
	var test_modifier = {
		"modifier_type": "nightcore"
	}
	var options = preload("res://rythm_game/modifiers/nightcore/nightcore_settings.gd").new()
	options.speed = 125.0
	test_modifier["modifier_options"] = options
	modifiers.append(test_modifier)
	
	serializable_fields += ["game_session_type", "time", "result", "modifiers",
	"used_autoplay", "song_id", "difficulty"]
func is_valid():
	return used_autoplay or modifiers.size() > 0

func get_serialized_type():
	return "GameInfo"
