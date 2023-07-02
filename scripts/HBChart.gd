# Chart class, contains timing points for an individual difficulty
class_name HBChart

const CURRENT_FORMAT_VERSION = 2

var layers = []
var editor_settings: HBPerSongEditorSettings = HBPerSongEditorSettings.new()
var format_version := CURRENT_FORMAT_VERSION

enum ChartNoteUsage {
	ARCADE,
	CONSOLE
}

func _init():
	_populate_layers()

class SlideChain:
	var time: int = 0
	var pieces: Array = []
	var slide: HBNoteData
	var is_playing_loop: bool = false
	var accumulated_score: float = 0.0
	var blues: float = 0.0
	var pieces_hit: int = 0
func _populate_layers():
	var disabled_types = [
		HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT),
		HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT),
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
		points.sort_custom(Callable(self, "_note_comparison"))
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
		"editor_settings": editor_settings.serialize(),
		"format_version": format_version,
	}

func deserialize(data: Dictionary, song):
	for layer in data.layers:
		var timing_points := []
		for point in layer.timing_points:
			var _point = HBTimingPoint.deserialize(point)
			
			if "2" in layer.name:
				_point.set_meta("second_layer", true)
			else:
				_point.set_meta("second_layer", false)
			
			timing_points.append(_point)
		
		var found_matching_layer = false
		for l in self.layers:
			if l.name == layer.name:
				l.timing_points = timing_points
				found_matching_layer = true
				break
		if not found_matching_layer:
			self.layers.append({
				"name": layer.name,
				"timing_points": timing_points
			})
	
	if data.has("editor_settings"):
		self.editor_settings = HBPerSongEditorSettings.deserialize(data.editor_settings)
	
	self.format_version = data.format_version if data.has("format_version") else 1
	
	print("=== LOADING CHART ===")
	print("- Format version: " + str(self.format_version))
	print("- Timing changes (before porting): " + str(song.timing_changes))
	print("- Editor Settings: " + str(self.editor_settings.bpm) + "BPM, offset " + str(self.editor_settings.offset * 1000.0) + "ms, BPB " + str(self.editor_settings.beats_per_bar))
	print("- Song Settings: " + str(song.bpm) + "BPM, BPM string: " + song.bpm_string)
	
	while self.format_version != CURRENT_FORMAT_VERSION:
		if self.format_version < CURRENT_FORMAT_VERSION:
			port_chart(song)
		else:
			backport_chart(song)
	
	print("=== LOADED CHART ===")

func port_chart(song):
	match self.format_version:
		1:  # V1 to V2
			print("- Porting V1 to V2...")
			
			for layer in self.layers:
				if layer.name != "Events":
					continue
				
				for note in layer.timing_points:
					if note is HBBPMChange:
						print("	- Changing speed change to fixed BPM at " + str(note.time) + "ms")
						note.usage = HBBPMChange.USAGE_TYPES.FIXED_BPM
			
			if not song.timing_changes:
				print("	- Generating timing changes")
				
				# Migrate timing info
				var base_timing_change = HBTimingChange.new()
				base_timing_change.time = self.editor_settings.offset * 1000.0
				base_timing_change.bpm = song.bpm
				
				base_timing_change.time_signature.numerator = self.editor_settings.beats_per_bar
				if self.editor_settings.beats_per_bar == 1:
					base_timing_change.time_signature.denominator = 1
				
				print("	- Generated data: " + str(base_timing_change.bpm) + "BPM, time sig " + str(base_timing_change.time_signature.numerator) + "/" + str(base_timing_change.time_signature.denominator) + ", at " + str(base_timing_change.time) + "ms")
				
				song.timing_changes = [base_timing_change]
	
	self.format_version += 1

func backport_chart(song):
	match self.format_version:
		2:  # V2 to V1
			var events_layer = null
			for layer in self.layers:
				if layer.name == "Events":
					events_layer = layer
			
			if not events_layer:
				return
			
			# Get old speed changes
			var speed_events := []
			for note in events_layer.timing_points:
				if note is HBBPMChange:
					speed_events.append(note)
			
			# Remove them
			for note in speed_events:
				events_layer.timing_points.erase(note)
			
			# Merge tempo map
			song.timing_changes.sort_custom(Callable(self, "_note_comparison"))
			song.timing_changes.reverse()
			
			speed_events.append(HBBPMChange.new())
			speed_events.append_array(song.timing_changes)
			speed_events.sort_custom(Callable(self, "_note_comparison"))
			speed_events.reverse()
			
			# Build fixed bpm map
			var bpm = song.timing_changes[0].bpm if song.timing_changes else 120
			var last_speed_change := HBBPMChange.new()
			last_speed_change.speed_factor = 100
			for event in speed_events:
				if event is HBTimingChange:
					bpm = event.bpm
				
				if event is HBBPMChange:
					last_speed_change = event
					
					if last_speed_change.usage == HBBPMChange.USAGE_TYPES.FIXED_BPM:
						events_layer.timing_points.append(last_speed_change)
						continue
				
				if last_speed_change.usage == HBBPMChange.USAGE_TYPES.AUTO_BPM:
					var bpm_change = HBBPMChange.new()
					bpm_change.time = event.time
					bpm_change.usage = HBBPMChange.USAGE_TYPES.FIXED_BPM
					bpm_change.bpm = bpm * (last_speed_change.speed_factor / 100.0)
					
					events_layer.timing_points.append(bpm_change)
			
			if song.timing_changes:
				self.editor_settings.offset = song.timing_changes[0].time / 1000.0
				self.editor_settings.bpm = song.timing_changes[0].bpm
				self.editor_settings.beats_per_bar = song.timing_changes[0].time_signature.numerator
	
	self.format_version -= 1

# Returns the max score, not including the extra hold score.
func get_max_score():
	var tp = get_timing_points()
	var max_score = 0.0
	
	var last_point: HBBaseNote
	
#	var notes = 0
	
	for point in tp:
		if point is HBSustainNote:
			max_score += point.get_score(HBJudge.JUDGE_RATINGS.COOL)
#			notes += 1
		if point is HBBaseNote:
			if last_point:
				if last_point.time == point.time:
					continue
			if point is HBNoteData and point.is_slide_hold_piece():
				continue
			else:
#				notes += 1
				last_point = point
				max_score += point.get_score(HBJudge.JUDGE_RATINGS.COOL)
	return max_score
	
static func get_slide_hold_chains_for_points(timing_points):
	var last_right_slide
	var last_left_slide
	var slide_hold_chains = {}
	for i in range(timing_points.size() - 1, -1, -1):
		var point = timing_points[i]
		if point is HBNoteData:
			if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
				last_left_slide = point
				slide_hold_chains[point] = SlideChain.new()
				slide_hold_chains[point].slide = point
			if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT:
				last_right_slide = point
				slide_hold_chains[point] = SlideChain.new()
				slide_hold_chains[point].slide = point
				
			if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT:
				if last_left_slide:
					slide_hold_chains[last_left_slide].pieces.append(point)
				else:
					print("Left slide hold piece found before left slide, this shouldn't happen")
			if point.note_type == HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT:
				if last_right_slide:
					slide_hold_chains[last_right_slide].pieces.append(point)
				else:
					print( "Right slide hold piece found before right slide, this shouldn't happen")
	for slide in slide_hold_chains.keys():
		if slide_hold_chains[slide].pieces.size() == 0:
			slide_hold_chains.erase(slide)
	return slide_hold_chains
# returns all slide hold chains it can find in array[slide] = [items] format
func get_slide_hold_chains():
	var target_layers = ["SLIDE_LEFT", "SLIDE_LEFT2", "SLIDE_RIGHT", "SLIDE_RIGHT2"]
	var slide_hold_chains = {}
	for layer_name in target_layers:
		var layer_i = get_layer_i(layer_name)
		if layer_i != -1:
			var points = layers[layer_i].timing_points
			points.sort_custom(Callable(self, "_note_comparison"))
			var r = get_slide_hold_chains_for_points(points)
			slide_hold_chains = HBUtils.merge_dict(slide_hold_chains, r)
	return slide_hold_chains
# gets layer by position
func get_layer_i(layer_name: String):
	var result = -1
	for i in range(layers.size()):
		if layers[i].name == layer_name:
			result = i
	return result

func get_note_usage() -> Array:
	var notes_used = []
	var tpoints = get_timing_points()
	for point in tpoints:
		if point is HBBaseNote:
			if point is HBSustainNote or point is HBDoubleNote or point.note_type == HBNoteData.NOTE_TYPE.HEART:
				if not ChartNoteUsage.CONSOLE in notes_used:
					notes_used.append(ChartNoteUsage.CONSOLE)
			elif point is HBNoteData:
				if point.is_slide_note() or point.hold:
					if not ChartNoteUsage.ARCADE in notes_used:
						notes_used.append(ChartNoteUsage.ARCADE)
		if notes_used.size() > 1:
			break
	return notes_used
