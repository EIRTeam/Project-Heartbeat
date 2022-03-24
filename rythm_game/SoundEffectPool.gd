extends Node

class_name HBSoundEffectPool

const MAX_VOICES = 5
const SFX_DEBOUNCE_TIME = 0.016*2.0

var loaded_effects = {}
var playing_effects = {}
var loaded_looping_effects = {}
var effects_debounce_times = {}

var effect_datas := {}

class EffectData:
	var name := ""
	var volume_linear := 1.0

func _init():
	name = "SoundEffectPool"

func add_sfx(sfx_name: String, volume_linear: float):
	var effect_data := EffectData.new()
	effect_data.name = sfx_name
	effect_data.volume_linear = volume_linear
	effect_datas[sfx_name] = effect_data
	effects_debounce_times[sfx_name] = SFX_DEBOUNCE_TIME + 1.0
	playing_effects[sfx_name] = []
	print("REGISTER %s %d" % [sfx_name, volume_linear])

func play_sfx(effect_name: String, bypass_debounce=false) -> ShinobuGodotSoundPlayback:
	if effects_debounce_times[effect_name] >= SFX_DEBOUNCE_TIME or bypass_debounce:
		var sound := ShinobuGodot.instantiate_sound(effect_name, "sfx")
		var effect_data := effect_datas[effect_name] as EffectData
		sound.volume = effect_data.volume_linear
		sound.start()
		sound.set_meta("effect_name", effect_name)
		effects_debounce_times[effect_name] = 0
		playing_effects[effect_name].append(sound)
		return sound
	return null

func stop_sfx(player: ShinobuGodotSoundPlayback):
	player.stop()
	var player_effect_name = player.get_meta("effect_name")
	if player in playing_effects[player_effect_name]:
		playing_effects[player_effect_name].erase(player)

func stop_all_sfx():
	for effect in playing_effects:
		for player in playing_effects[effect]:
			stop_sfx(player)

func _process(delta):
	for effect_name in effects_debounce_times:
		effects_debounce_times[effect_name] += delta
	var sfx_to_erase := []
	for effect_name in playing_effects:
		for player in playing_effects[effect_name]:
			var p := player as ShinobuGodotSoundPlayback
			if not p.looping_enabled:
				if p.get_playback_position_msec() >= p.get_length_msec():
					sfx_to_erase.append(p)
	for sfx in sfx_to_erase:
		stop_sfx(sfx)
