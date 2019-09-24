extends "res://editor/timeline_items/EditorTimelineItemNote.gd"

enum NOTE_TYPE {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

const NOTE_PROPERTIES = {
	NOTE_TYPE.UP: {
		"color": "eeb136"
	},
	NOTE_TYPE.DOWN: {
		"color": "87d639"
	},
	NOTE_TYPE.LEFT: {
		"color": "4296f3"
	},
	NOTE_TYPE.RIGHT: {
		"color": "e02828"
	}
}

export (NOTE_TYPE) var note_type = NOTE_TYPE.RIGHT setget set_note_type

const WIDTH = 5.0

func _ready():
	set_color()

func set_color():
	get_stylebox("panel").bg_color = Color(NOTE_PROPERTIES[note_type].color)

func set_note_type(value):
	note_type = value
	set_color()
func get_size():
	return Vector2(WIDTH, rect_size.y)

func get_inspector_properties():
	var props = HBUtils.merge_dict(.get_inspector_properties(),  {
		"note_type": "NoteTypeSelector"
	})
	return props 

