class_name HBChart

var layers = []
func compare_notes(a, b):
	if a.time < b.time:
		return true
	return false
func get_timing_points():
	var points = []
	for layer in layers:
		var items = layer.items
		points += items
	return points
		
func get_serialized_type():
	return "Chart"
