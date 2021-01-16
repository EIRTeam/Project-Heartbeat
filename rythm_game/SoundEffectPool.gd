extends Node

class_name HBSoundEffectPool

const MAX_VOICES = 5
const SFX_DEBOUNCE_TIME = 0.016*2.0

var loaded_effects = {}
var playing_effects = {}
var loaded_looping_effects = {}
var effects_debounce_times = {}

func _init():
	name = "SoundEffectPool"

func _create_sfx_player(sample, volume, bus="SFX") -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.bus = bus
	player.stream = sample
	player.volume_db = volume
	return player

func add_sfx(effect_name: String, sample, volume, bus="SFX"):
	var player = _create_sfx_player(sample, volume, bus)
	var players = [player]
	add_child(player)
	loaded_effects[effect_name] = player
	effects_debounce_times[effect_name] = SFX_DEBOUNCE_TIME
	playing_effects[effect_name] = []

func play_sfx(effect_name: String, bypass_debounce=false):
	if effects_debounce_times[effect_name] > SFX_DEBOUNCE_TIME or bypass_debounce:
		var player = loaded_effects[effect_name].duplicate() as AudioStreamPlayer
		add_child(player)
		player.connect("finished", self, "stop_sfx", [player])
		player.play()
		player.set_meta("effect_name", effect_name)
		effects_debounce_times[effect_name] = 0
		playing_effects[effect_name].append(player)
		return player

func add_looping_sfx(effect_name: String, sample, volume, bus="SFX"):
	var player = _create_sfx_player(sample, volume, bus)
	var players = [player]
	add_child(player)
	for _i in range(MAX_VOICES -1):
		var new_player = player.duplicate()
		players.append(new_player)
		add_child(new_player)

	loaded_looping_effects[effect_name] = players

func play_looping_sfx(effect_name: String) -> AudioStreamPlayer:
	var player = loaded_looping_effects[effect_name].pop_front() as AudioStreamPlayer
	# HACK: Godot is dumb and doesn't like you stopping and starting audio stream players
	# at close times
	player.stop()
	player.stream_paused = false

	player.play()
	loaded_looping_effects[effect_name].append(player)
	return player

func stop_looping_sfx(player: AudioStreamPlayer):
	# HACK: Godot is dumb and doesn't like you stopping and starting audio stream players
	# at close times
	player.stream_paused = true
	player.stop()
	
func stop_sfx(player: AudioStreamPlayer):
	player.stop()
	var player_effect_name = player.get_meta("effect_name")
	if player in playing_effects[player_effect_name]:
		playing_effects[player_effect_name].erase(player)
		player.queue_free()

func stop_all_looping_sfx():
	for effect in loaded_looping_effects:
		for player in loaded_looping_effects[effect]:
			stop_looping_sfx(player)

func stop_all_sfx():
	for effect in playing_effects:
		for player in playing_effects[effect]:
			stop_sfx(player)
	stop_all_looping_sfx()

func _process(delta):
	for effect_name in effects_debounce_times:
		effects_debounce_times[effect_name] += delta
