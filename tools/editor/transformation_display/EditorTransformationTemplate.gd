extends EditorTransformation

class_name EditorTransformationTemplate

# Transformation templates, note_type to transformation properties
var template = null

# Returns a note:transformation dictionary, includes template notes for missing types
func transform_notes(notes: Array) -> Dictionary:
	var notes_to_transform_map = {}
	
	var found_types = []
	
	for note in notes:
		if template.has_type_template(note.note_type, note.get_meta("second_layer", false)):
			notes_to_transform_map[note] = template.get_type_template(note.note_type, note.get_meta("second_layer"))
	
	return notes_to_transform_map
