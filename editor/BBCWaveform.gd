extends Control

class_name BBCWaveform

var waveform_data : Dictionary setget set_waveform_data

var max_wave_value = 0
var min_position = 0.0 setget set_min_position
var max_position = 1.0 setget set_max_position

func set_min_position(value):
	min_position = value
	update()
	
func set_max_position(value):
	max_position = value
	update()

func set_waveform_data(value):
	max_wave_value = 0
	waveform_data = value
	
	for point in waveform_data.data:
		if max_wave_value < abs(point):
			max_wave_value = abs(point)
func _ready():
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw():
	if waveform_data:
		var starting_position = waveform_data["length"] * min_position
		var length = waveform_data["length"] * max_position - starting_position
		var point_interval : float = length / float(rect_size.x)
		var points = PoolVector2Array()
		
		var y_scale = ((rect_size.y * 0.5) / max_wave_value)
		for point in range(rect_size.x):
			var i = starting_position + point*point_interval
			points.append(Vector2(point, rect_size.y / 2 + waveform_data.data[i] * y_scale))
			#draw_line(Vector2(point, rect_size.y / 2), Vector2(point, rect_size.y / 2 - abs(waveform_data.data[i]) * y_scale ), Color.white)
		draw_polyline(points, Color.gray, 1.0, true)
