# This class holds information regarding a game session that was played, and also
# doubles as a configuration class for the session
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
var variant = -1
func _init():
	super._init()
	time = Time.get_unix_time_from_system()
	
	serializable_fields += ["game_session_type", "time", "result", "modifiers",
	"used_autoplay", "song_id", "difficulty"]

static func deserialize(data: Dictionary):
	var res = HBSerializable.deserialize(data)
	res.modifiers = {}
	if data.has("modifiers"):
		for modifier_id in data.modifiers:
			var modifier_settings = HBSerializable.deserialize(data.modifiers[modifier_id])
			res.modifiers[modifier_id] = modifier_settings
	return res
func serialize(serialize_defaults=false):
	var base_data = super.serialize(serialize_defaults)
	var new_modifiers = {}
	for modifier_id in modifiers:
		new_modifiers[modifier_id] = modifiers[modifier_id].serialize(serialize_defaults)
	base_data.modifiers = new_modifiers
	return base_data
func add_new_modifier(modifier_id: String):
	var modifier_class = ModifierLoader.get_modifier_by_id(modifier_id)
	if modifier_class:
		modifiers[modifier_id] = modifier_class.get_modifier_settings_class().new()
		
# Returns if the song is legal for uploading to leaderboards
# keep in mind this doedsn't take into account if cheats were used
# that should be checked separatedly
func is_leaderboard_legal():
	return modifiers.size() == 0 and not result.get_result_rating() == HBResult.RESULT_RATING.FAIL
	
func get_serialized_type():
	return "GameInfo"

func get_song():
	return SongLoader.songs[song_id]
