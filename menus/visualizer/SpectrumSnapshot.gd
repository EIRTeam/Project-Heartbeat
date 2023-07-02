extends Node

class_name HBSpectrumSnapshot

var arr := PackedFloat32Array()
const STEP := 78 # 78 hz step
const min_freq := 20
var max_freq := 20_000
var max_db := 0
var min_db := -40

const BASE_MIN_DB = -60

var decay_per_ms := 0.0024

var definition := 256

@onready var timer := Timer.new()
const UPDATE_INTERVAL_SEC = 0.050

var analyzer: ShinobuSpectrumAnalyzerEffect

var enabled := true: set = set_enabled

func set_enabled(val):
	enabled = val
	if is_inside_tree():
		timer.paused = !val
		set_process(val)

func _init(_definition):
	definition = _definition
	arr.resize(definition)
	for i in range(arr.size()):
		arr.set(i, 0.0)
		
func _ready():
	add_child(timer)
	timer.wait_time = UPDATE_INTERVAL_SEC
	timer.connect("timeout", Callable(self, "snap"))
	timer.start()
	set_enabled(enabled)
		
func set_volume(volume_db: float):
	max_db = volume_db + linear_to_db(HBGame.music_group.volume)
	min_db = BASE_MIN_DB + volume_db + linear_to_db(HBGame.music_group.volume)
	
func snap():
	var interval = (max_freq - min_freq) / float(definition)
	
	for i in range(arr.size()):
		var freq = min_freq + interval * i
		var freqrange_low = float(freq - min_freq) / float(max_freq - min_freq)
		freqrange_low = pow(freqrange_low, 2.0)
		freqrange_low = lerp(min_freq, max_freq, freqrange_low)
		
		freq += interval
		var freqrange_high = float(freq - min_freq) / float(max_freq - min_freq)
		freqrange_high = pow(freqrange_high, 2.0)
		freqrange_high = lerp(min_freq, max_freq, freqrange_high)
		
		
		var mag = analyzer.get_magnitude_for_frequency_range(freqrange_low, freqrange_high)
		mag = linear_to_db(mag.length())
		mag = (mag - min_db) / (max_db - min_db)
		mag += 0.3 * (freq - min_freq) / (max_freq - min_freq)
		mag = clamp(mag, 0.00, 1)
		
		if mag > arr[i]:
			arr.set(i, mag)

func get_value_at_i(i: int) -> float:
	return arr[i]
func set_value_at_i(i: int, val: float):
	arr.set(i, val)

func _process(delta):
	if UserSettings.user_settings.visualizer_enabled:
		decay(delta)

func decay(delta: float):
	var decay_factor = (delta * 1000.0) * decay_per_ms
	for i in range(256):
		var val := HBGame.spectrum_snapshot.get_value_at_i(i) as float
		val -= decay_factor * (val + 0.015)
		HBGame.spectrum_snapshot.set_value_at_i(i, max(val, 0))
