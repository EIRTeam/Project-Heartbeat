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
	
	
# Gets timing points that are simplified, so multi notes are turned into individual notes
func get_simplified_timing_points():
	var points = []
	for layer in layers:
		var items = layer.timing_points
		for item in items:
			var simplified = item.get_simplified()
			if simplified is Array:
				points += simplified
			else:
				points.append(item)
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
	
func deserialize(data: Dictionary):
	for layer in data.layers:
		var timing_points = []
		for point in layer.timing_points:
			var _point = HBTimingPoint.deserialize(point)
			timing_points.append(_point)
		layers.append({
			"name": layer.name,
			"timing_points": timing_points
		})
