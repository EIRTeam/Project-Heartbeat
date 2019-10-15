extends "res://tools/editor/timeline_items/EditorTimelineItemNote.gd"



const WIDTH = 5.0

func _ready():
	set_color()
	data.connect("note_type_changed", self, "set_color")
	

func set_color():
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(data.NOTE_COLORS[data.note_type].color)
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
