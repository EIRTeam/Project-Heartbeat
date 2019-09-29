extends "res://editor/timeline_items/EditorTimelineItemNote.gd"

const NOTE_PROPERTIES = {
	HBNoteData.NOTE_TYPE.UP: {
		"color": "eeb136"
	},
	HBNoteData.NOTE_TYPE.DOWN: {
		"color": "87d639"
	},
	HBNoteData.NOTE_TYPE.LEFT: {
		"color": "4296f3"
	},
	HBNoteData.NOTE_TYPE.RIGHT: {
		"color": "e02828"
	}
}

const WIDTH = 5.0

func _ready():
	set_color()

func set_color():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(NOTE_PROPERTIES[data.note_type].color)
	add_stylebox_override("panel", style_box)
func get_size():
	return Vector2(WIDTH, rect_size.y)

func get_inspector_properties():
	var props = HBUtils.merge_dict(.get_inspector_properties(),  {
		"note_type": "NoteTypeSelector"
	})
	return props 

func get_duration():
	return 100
