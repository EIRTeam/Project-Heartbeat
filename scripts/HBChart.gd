# Chart class, contains timing points for an individual difficulty
class_name HBChart

var layers = []
var editor_settings: HBPerSongEditorSettings = HBPerSongEditorSettings.new()
func _init():
	_populate_layers()

func _populate_layers():
	var disabled_types = [
		HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE),
		HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE),
	]
	for NOTE_TYPE in HBNoteData.NOTE_TYPE:
		if not NOTE_TYPE in disabled_types:
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
	
func _note_comparison(a, b):
	return a.time > b.time
# returns all the timing points in the chart, optionally ordered by end time
func get_timing_points(ordered=true):
	var points = []
	for layer in layers:
		var items = layer.timing_points
		points += items
	if ordered:
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

# Returns the max score, not including the extra hold score.
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
			if point.is_slide_hold_piece():
				continue
			else:
				notes += 1
				last_point = point
	max_score += notes * HBNoteData.NOTE_SCORES[HBJudge.JUDGE_RATINGS.COOL]
	
	return max_score
	
# returns all slide hold chains it can find in array[slide] = [items] format
static func get_slide_hold_chains(timing_points):
	var last_right_slide
	var last_left_slide
	var slide_hold_chains = {}
	
	for i in range(timing_points.size() - 1, -1, -1):
		var point = timing_points[i]
		if point is HBNoteData:
			if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
				last_left_slide = point
				slide_hold_chains[point] = []
			if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT:
				last_right_slide = point
				slide_hold_chains[point] = []
				
			if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE:
				if last_left_slide:
					slide_hold_chains[last_left_slide].append(point)
				else:
					print("Left slide hold piece found before left slide, this shouldn't happen")
			if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE:
				if last_right_slide:
					slide_hold_chains[last_right_slide].append(point)
				else:
					print( "Right slide hold piece found before right slide, this shouldn't happen")
	for slide in slide_hold_chains.keys():
		if slide_hold_chains[slide].size() == 0:
			slide_hold_chains.erase(slide)
	return slide_hold_chains
# gets layer by position
func get_layer_i(layer_name: String):
	for i in range(layers.size()):
		if layers[i].name == layer_name:
			return i
