class_name HBChart

var layers = []
func compare_notes(a, b):
	if a.time < b.time:
		return true
	return false
func get_timing_points():
	var points = []
	for layer in layers:
		var items = layer.timing_points
		points += items
	return points
		
func get_serialized_type():
	return "Chart"
	
func serialize():
	var serialized_layers = []
	for layer in layers:
		var timing_points = []
		for point in layer.timing_points:
			timing_points.append(point.serialize())
		var l = {
			"name": layer.name,
			"timing_points": timing_points
		}
		serialized_layers.append(l)
	return {
		"layers": serialized_layers
	}
