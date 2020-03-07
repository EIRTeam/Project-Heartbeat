class_name HBChart

var layers = []
var editor_settings: HBPerSongEditorSettings = HBPerSongEditorSettings.new()
func _init():
	pass
	_populate_layers()

func _populate_layers():
	for NOTE_TYPE in HBNoteData.NOTE_TYPE:
		layers.append({
			"name": NOTE_TYPE,
			"timing_points": []
		})
	# Extra slide layers
	
	layers.append({
		"name": HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.SLIDE_LEFT) + "2",
		"timing_points": []
	})
	
	layers.append({
		"name": HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.SLIDE_RIGHT) + "2",
		"timing_points": []
	})
	
	layers.append({
		"name": "Events",
		"timing_points": []
	})
	
# Notes are sorted by appearance time
func _note_comparison(a, b):
	return a.time > b.time
	
func get_timing_points():
	var points = []
	for layer in layers:
		var items = layer.timing_points
		points += items
	points.sort_custom(self, "_note_comparison")
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
		"layers": serialized_layers,
		"editor_settings": editor_settings.serialize()
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
	if data.has("editor_settings"):
		editor_settings = HBPerSongEditorSettings.deserialize(data.editor_settings)

func get_max_score():
	var tp = get_timing_points()
	var max_score = 0.0
	
	var last_point: HBNoteData
	
	var notes = 0
	
	for point in tp:
		if point is HBNoteData:
			if last_point:
				if last_point.time == point.time:
					continue
			notes += 1
			last_point = point
	max_score += round(notes / 2.0) * HBNoteData.NOTE_SCORES[HBJudge.JUDGE_RATINGS.FINE]
	max_score += round(notes / 2.0) * HBNoteData.NOTE_SCORES[HBJudge.JUDGE_RATINGS.COOL]
	
	return max_score
	
func get_layer_i(layer_name: String):
	for i in range(layers.size()):
		if layers[i].name == layer_name:
			return i
