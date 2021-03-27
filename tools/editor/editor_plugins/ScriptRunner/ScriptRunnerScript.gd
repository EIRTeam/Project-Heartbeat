class_name ScriptRunnerScript

var _editor

var selected_timing_points = []
var _timing_point_changed_properties = {}
var _clone_to_original_timing_point_map = {}

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

func get_bpm_at_time(time: int) -> int:
	return _editor.rhythm_game.get_bpm_at_time(time)
