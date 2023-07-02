class_name EditorTransformation

var use_stage_center := false
var editor : set = set_editor

func transform_notes(notes: Array):
	pass

func get_center_for_notes(notes: Array) -> Vector2:
	if use_stage_center:
		return Vector2(1920, 1080) / 2.0
	var average_position = Vector2(0, 0)
	var average_count = 0
	for note in notes:
		average_position += note.position
		average_count += 1
	average_position /= float(average_count)
	return average_position

func set_editor(_editor):
	editor = _editor

func get_notes_at_time(t: int):
	var points = editor.get_notes_at_time(t)
	var result = []
	
	for point in points:
		if point is HBBaseNote:
			result.append(point)
	
	return result
