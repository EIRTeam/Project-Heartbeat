extends EditorTransformation

class_name EditorTransformationTemplate

# Transformation templates, note_type to transformation properties
var template := {}
var dynamic = false

func transform_notes_dynamic():
	pass

# Returns a note:transformation dictionary, includes template notes for missing types
func transform_notes(notes: Array) -> Dictionary:
	var notes_to_transform_map = {}
	var template_to_use = template

	var found_types = []

	for note in notes:
		if note.note_type in template_to_use:
			notes_to_transform_map[note] = template_to_use[note.note_type]
			found_types.append(note.note_type)
	for note_type in template:
		if not note_type in found_types:
			var n = HBNoteData.new()
			notes_to_transform_map[n] = template_to_use[note_type]
	if dynamic:
		var center = get_center_for_notes(notes)
		for note in notes_to_transform_map:
			if not "position" in notes_to_transform_map[note]:
				notes_to_transform_map[note]["position"] = Vector2.ZERO
			notes_to_transform_map[note].position += center
	return notes_to_transform_map
