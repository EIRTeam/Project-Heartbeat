extends HBGameMode

class_name HBHeartbeatGameMode

static func get_ui():
	return preload("res://rythm_game/game_modes/heartbeat/HeartbeatRhythmGameUI.tscn")
	
static func get_game():
	return preload("res://rythm_game/game_modes/heartbeat/RhythmGameHeartbeat.gd")

static func get_game_mode_name() -> String:
	return "Base Game Mode"

static func get_serializable_song_types() -> Array:
	return ["Song", "PPDSong"]

static func get_input_manager() -> HBGameInputManager:
	return HeartbeatInputManager.new()
