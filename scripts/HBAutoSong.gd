# Class for generating a song live
extends HBSong

class_name HBAutoSong


var pattern = {
	"layers": {},
	"repeat": 1,
	"spacing": 0
}
var loudness: float
var offset := 0
var audio_path
var chart: HBChart


func _init(_pattern: Dictionary, _audio_path: String, _loudness: float, _offset: int = 0):
	super._init()
	pattern = _pattern
	audio_path = _audio_path
	loudness = _loudness
	offset = _offset
	
	generate_chart()


func generate_chart():
	chart = HBChart.new()
	

	if timing_changes.size() == 0:
		var event_layer := chart.layers.size()-1
		var timing_change := HBTimingChange.new()
		chart.layers[event_layer].timing_points.push_back(timing_change)
		timing_changes.push_back(timing_change)
	for i in range(pattern.repeat):
		for j in pattern.layers.size():
			var layer = pattern.layers[j]
			var timing_points = []
			
			for point in layer.timing_points:
				point = HBTimingPoint.deserialize(point)
				point.time = offset + (pattern.spacing * i) + (point.time * i)
				point.position = Vector2(1920, 1080) * 0.5
				
				timing_points.append(point)
			
			chart.layers[j].timing_points.append_array(timing_points)


func get_audio_stream(variant := -1):
	return load(audio_path)
