extends Node

class_name HBSoundEffectPool

const MAX_VOICES = 5
const SFX_DEBOUNCE_TIME = 0.016*2.0

var loaded_effects = {}
var loaded_looping_effects = {}
var effects_debounce_times = {}

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
	for _i in range(MAX_VOICES -1):
		var new_player = player.duplicate()
		players.append(new_player)
		add_child(new_player)
	loaded_effects[effect_name] = players
	effects_debounce_times[effect_name] = SFX_DEBOUNCE_TIME

func play_sfx(effect_name: String):
	if effects_debounce_times[effect_name] > SFX_DEBOUNCE_TIME:
		var player = loaded_effects[effect_name].pop_front() as AudioStreamPlayer
		player.play()
		player.stream_paused = false
		effects_debounce_times[effect_name] = 0
		loaded_effects[effect_name].append(player)

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

func _process(delta):
	for effect_name in effects_debounce_times:
		effects_debounce_times[effect_name] += delta
