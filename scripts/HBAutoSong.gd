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


func _init(pattern: Dictionary, audio_path: String, loudness: float, offset: int = 0):
	._init()
	self.pattern = pattern
	self.audio_path = audio_path
	self.loudness = loudness
	self.offset = offset
	
	generate_chart()


func generate_chart():
	chart = HBChart.new()
	
	for i in range(pattern.repeat):
		for j in pattern.layers.size():
			var layer = pattern.layers[j]
			var timing_points = []
			
			for point in layer.timing_points:
				point = HBTimingPoint.deserialize(point)
				point.time = offset + (pattern["spacing"] * i) + (point.time * i)
				
				timing_points.append(point)
			
			chart.layers[j].timing_points.append_array(timing_points)


func get_audio_stream():
	return load(audio_path)
