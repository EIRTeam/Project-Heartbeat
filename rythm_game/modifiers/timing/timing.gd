extends HBModifier

const TimingSettings = preload("res://rythm_game/modifiers/timing/timing_settings.gd")

func _init():
	modifier_settings = get_modifier_settings_class().new()

func _init_plugin():
	# Base init plugin must always be called after local init
	super._init_plugin()
func _pre_game(song: HBSong, game: HBRhythmGame):
	game.judge.timing_window_scale = modifier_settings.timing_window / 256.0

static func get_modifier_name():
	return "Timing Window Change"

# Some modifiers might use a different name based on settings
func get_modifier_list_name():
	var cool_timing = int(32.0 * modifier_settings.timing_window / 256.0)
	return "Timing Window Change: %d ms (COOL: %d ms)" % [modifier_settings.timing_window, cool_timing] 

static func get_modifier_description():
	return "Changes the timing window size, (lower values might not be possible/not work properly on more modest systems)."
static func get_modifier_settings_class() -> Script:
	return TimingSettings
static func get_option_settings() -> Dictionary:
	return {
		"timing_window": {
			"name": TranslationServer.tr("Timing Window"),
			"description": TranslationServer.tr("Duration of the overall timing window (in ms)"),
			"minimum": 16,
			"maximum": 512,
			"step": 1,
			"postfix": " ms",
			"default_value": 256
		}
	}
