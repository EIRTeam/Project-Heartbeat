extends HBModifier

const AutoplaySettings = preload("res://rythm_game/modifiers/autoplay/autoplay_settings.gd")

func _init():
	modifier_settings = get_modifier_settings_class().new()

func _init_plugin():
	# Base init plugin must always be called after local init
	super._init_plugin()

func _pre_game(song: HBSong, game: HBRhythmGame):
	game.game_mode = HBRhythmGame.GAME_MODE.AUTOPLAY
func _post_game(song: HBSong, game: HBRhythmGame):
	pass
static func get_modifier_name():
	return "Autoplay"
	
func get_modifier_list_name():
	return "Autoplay"
	
static func get_modifier_description():
	return TranslationServer.tr("Makes the game play itself.")
static func get_modifier_settings_class() -> Script:
	return AutoplaySettings
