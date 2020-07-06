class_name HBGameMode

static func get_ui():
	pass
	
static func get_game():
	pass

static func get_game_mode_name() -> String:
	return "Base Game Mode"

static func get_serializable_song_types() -> Array:
	return []

static func get_input_manager() -> HBGameInputManager:
	return HBGameInputManager.new()
