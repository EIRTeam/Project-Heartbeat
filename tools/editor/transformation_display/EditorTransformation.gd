class_name EditorTransformation

func transform_notes(notes: Array):
	pass

func get_center_for_notes(notes: Array) -> Vector2:
	var average_position = Vector2(0, 0)
	var average_count = 0
	for note in notes:
		average_position += note.position
		average_count += 1
	average_position /= float(average_count)
	return average_position
