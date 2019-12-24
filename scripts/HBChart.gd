class_name HBChart

var layers = []

func _init():
	pass
	_populate_layers()

func _populate_layers():
	for NOTE_TYPE in HBNoteData.NOTE_TYPE:
		layers.append({
			"name": NOTE_TYPE,
			"timing_points": []
		})
	layers.append({
		"name": "Events",
		"timing_points": []
	})
	
func _note_comparison(a, b):
	return a.time < b.time
	
func get_timing_points():
	var points = []
	for layer in layers:
		var items = layer.timing_points
		points += items
	points.sort_custom(self, "_note_comparison")
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
			
		var found_matching_layer = false
		for l in layers:
			if l.name == layer.name:
				l.timing_points = timing_points
				found_matching_layer = true
				break
		if not found_matching_layer:
			layers.append({
				"name": layer.name,
				"timing_points": timing_points
			})
