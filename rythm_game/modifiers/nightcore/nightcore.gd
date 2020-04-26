extends HBModifier

const NightcoreSettings = preload("res://rythm_game/modifiers/nightcore/nightcore_settings.gd")
func _init_plugin():
	options = {
		"speed": {
			"name": tr("Speed"),
			"description": "Percentage of speed to increase (or decrease) the song's playback",
			"minimum": 10,
			"maximum": 1000,
			"step": 5,
			"postfix": " %"
		}
	}

	modifier_settings_class = NightcoreSettings
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

static func get_modifier_description():
	return "Turns your manly voices into anime girls, who would have thought?"
