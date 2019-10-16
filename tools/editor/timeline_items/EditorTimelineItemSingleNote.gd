extends "res://tools/editor/timeline_items/EditorTimelineItemNote.gd"



const WIDTH = 5.0

func _ready():
	set_texture()
	data.connect("note_type_changed", self, "set_texture")
	
func set_texture():
	$TextureRect.texture = HBNoteData.NOTE_GRAPHICS[data.note_type].note
	$TextureRect.rect_size = Vector2(get_size().y, get_size().y)
	$TextureRect.rect_position = Vector2(-get_size().y / 2, 0)
func get_size():
	return Vector2(WIDTH, rect_size.y)

func get_inspector_properties():
	var props = HBUtils.merge_dict(.get_inspector_properties(),  {
		"note_type": "NoteTypeSelector"
	})
	return props 

func get_duration():
	return 100
