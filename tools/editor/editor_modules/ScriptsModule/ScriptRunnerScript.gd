class_name ScriptRunnerScript

var _editor

var selected_timing_points = []
var _timing_point_changed_properties = {}
var _clone_to_original_timing_point_map = {}
var new_timing_points = []

func init_script():
	selected_timing_points = []
	# We clone the editor timing points
	for data in _editor.selected:
		var point = data.data
		if point is HBTimingPoint:
			var clone = point.clone()
			selected_timing_points.append(clone)
			_clone_to_original_timing_point_map[clone] = data

func run_script():
	pass
	
func get_selected_timing_points() -> Array:
	return selected_timing_points

func set_timing_point_property(timing_point: HBTimingPoint, property_name: String, value):
	if not timing_point in _timing_point_changed_properties:
		_timing_point_changed_properties[timing_point] = {}
	_timing_point_changed_properties[timing_point][property_name] = value

func bsearch_time(a, b):
	var a_t = a
	var b_t = b
	if a is HBTimingPoint:
		a_t = a.time
	if b is HBTimingPoint:
		b_t = b.time
	return a_t < b_t

func get_points_at_time(time: int):
	var notes = []
	for note in selected_timing_points:
		if note is HBTimingPoint:
			if note.time == time:
				notes.append(note)
	return notes

func get_timing_info_at_time(time: int) -> HBTimingChange:
	for timing_change in _editor.get_timing_changes():
		if timing_change.data.time <= time:
			return timing_change.data
	
	return null

func get_bpm_at_time(time: int) -> float:
	print("WARNING: The function get_bpm_at_time has been deprecated.")
	print("Please use get_timing_info_at_time or get_note_speed_at_time instead.")
	var timing_info = get_timing_info_at_time(time)
	return timing_info.bpm if timing_info else 0.03

func get_note_speed_at_time(time: int) -> float:
	return _editor.rhythm_game.get_note_speed_at_time(time)

func get_note_resolution() -> float:
	return _editor.get_note_resolution()

func get_timing_changes() -> Array:
	return _editor.get_timing_changes()

func get_timing_map() -> Array:
	return _editor.get_timing_map()

func get_normalized_timing_map() -> Array:
	return _editor.get_normalized_timing_map()

func get_signature_map() -> Array:
	return _editor.get_signature_map()

func get_metronome_map() -> Array:
	return _editor.get_metronome_map()

func create_timing_point(timing_point: HBTimingPoint):
	new_timing_points.append(timing_point)

func bsearch_upper(array: Array, value: int) -> int:
	return HBUtils.bsearch_upper(array, value)

func bsearch_closest(array: Array, value: int) -> int:
	return HBUtils.bsearch_closest(array, value)

func bsearch_linear(array: Array, value: int) -> float:
	return HBUtils.bsearch_linear(array, value)

func get_time_as_eight(time: int) -> float:
	return _editor.get_time_as_eight(time)
