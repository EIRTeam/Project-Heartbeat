extends HBModifier

const NightcoreSettings = preload("res://rythm_game/modifiers/nightcore/nightcore_settings.gd")

func _init():
	modifier_settings = get_modifier_settings_class().new()

func _init_plugin():
	# Base init plugin must always be called after local init
	._init_plugin()

func _pre_game(song: HBSong, game: HBRhythmGame):
	game.audio_stream_player.pitch_scale = float(modifier_settings.speed)/100.0
	game.audio_stream_player_voice.pitch_scale = float(modifier_settings.speed)/100.0
func _post_game(song: HBSong, game: HBRhythmGame):
	game.audio_stream_player.pitch_scale = 1.0
	game.audio_stream_player_voice.pitch_scale = 1.0
	
static func get_modifier_name():
	return "Nightcore"
	
# Some modifiers might use a different name based on settings
func get_modifier_list_name():
	return "Nightcore %d %%" % [modifier_settings.speed]

static func get_modifier_description():
	return "Turns your manly voices into anime girls."
static func get_modifier_settings_class() -> Script:
	return NightcoreSettings
static func get_option_settings() -> Dictionary:
	return {
		"speed": {
			"name": "Speed",
			"description": "Percentage of speed to increase (or decrease) the song's playback",
			"minimum": 10,
			"maximum": 1000,
			"step": 5,
			"postfix": " %",
			"default_value": 100
		}
	}
