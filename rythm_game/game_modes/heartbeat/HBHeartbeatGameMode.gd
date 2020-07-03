extends HBGameMode

class_name HBHeartbeatGameMode

static func get_ui():
	return preload("res://rythm_game/rhythm_game_ui.tscn")
	
static func get_game():
	preload("res://rythm_game/RhythmGameHeartbeat.gd")

static func get_game_mode_name() -> String:
	return "Base Game Mode"

static func get_serializable_song_types() -> Array:
	return ["Song"]
