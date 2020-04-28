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
var modifiers = {}
var used_autoplay = false
var song_id = ""
var difficulty = ""
func _init():
	._init()
	time = OS.get_unix_time()
	
	serializable_fields += ["game_session_type", "time", "result", "modifiers",
	"used_autoplay", "song_id", "difficulty"]
#func is_valid():
#	return used_autoplay or modifiers.size() > 0
static func deserialize(data: Dictionary):
	var res = .deserialize(data)
	res.modifiers = {}
	if data.has("modifiers"):
		for modifier_id in data.modifiers:
			var modifier_settings = HBSerializable.deserialize(data.modifiers[modifier_id])
			res.modifiers[modifier_id] = modifier_settings
	return res
func serialize():
	var base_data = .serialize()
	var new_modifiers = {}
	for modifier_id in modifiers:
		new_modifiers[modifier_id] = modifiers[modifier_id].serialize()
	base_data.modifiers = new_modifiers
	return base_data
func add_new_modifier(modifier_id: String):
	var modifier_class = ModifierLoader.get_modifier_by_id(modifier_id)
	if modifier_class:
		modifiers[modifier_id] = modifier_class.get_modifier_settings_class().new()
func is_leaderboard_legal():
	return modifiers.size() == 0
	
func get_serialized_type():
	return "GameInfo"
