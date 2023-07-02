extends HBModifier

const NightcoreSettings = preload("res://rythm_game/modifiers/nightcore/nightcore_settings.gd")

func _init():
	disables_video = true
	modifier_settings = get_modifier_settings_class().new()

func _init_plugin():
	# Base init plugin must always be called after local init
	super._init_plugin()

func _pre_game(song: HBSong, game: HBRhythmGame):
	game.audio_playback.set_pitch_scale(float(modifier_settings.speed)/100.0)
	if game.voice_audio_playback:
		game.voice_audio_playback.set_pitch_scale(float(modifier_settings.speed)/100.0)
func _post_game(song: HBSong, game: HBRhythmGame):
	game.audio_playback.set_pitch_scale(1.0)
	if game.voice_audio_playback:
		game.voice_audio_playback.set_pitch_scale(1.0)
	
static func get_modifier_name():
	return "Nightcore"
	
# Some modifiers might use a different name based on settings
func get_modifier_list_name():
	return "Nightcore %d %%" % [modifier_settings.speed]

static func get_modifier_description():
	return TranslationServer.tr("Turns your manly voices into anime girls.")
static func get_modifier_settings_class() -> Script:
	return NightcoreSettings
static func get_option_settings() -> Dictionary:
	return {
		"speed": {
			"name": TranslationServer.tr("Speed"),
			"description": TranslationServer.tr("Percentage of speed to increase (or decrease) the song's playback"),
			"minimum": 10,
			"maximum": 1000,
			"step": 5,
			"postfix": " %",
			"default_value": 100
		}
	}
