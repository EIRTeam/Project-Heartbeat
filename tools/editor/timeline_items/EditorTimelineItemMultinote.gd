extends "res://tools/editor/timeline_items/EditorTimelineItemSingleNote.gd"

func _init():
	update_affects_timing_points = true
	
func _ready():
	connect("item_changed", self, "set_texture")
	set_texture()
	
func get_inspector_properties():
	var props = HBUtils.merge_dict(.get_inspector_properties(),  {
		"duration": "int",
		"number_of_notes": "int"
	})
	return props 

func get_duration():
	return data.duration

func set_texture():
	.set_texture()
	update()
	
func _draw():
	var line_color = Color(HBNoteData.NOTE_COLORS[data.note_type].color)
	line_color.a = 0.5
	draw_line(Vector2(0, rect_size.y/2), Vector2(rect_size.x, rect_size.y/2), line_color, rect_size.y / 4)
	for note in range(data.number_of_notes-1):
		var note_x = (rect_size.x) * ((note+1.0)/float(data.number_of_notes-1))
		var note_pos = Vector2(note_x - get_size().y / 2, 0)
		var rect = Rect2(note_pos, Vector2(get_size().y, get_size().y))
		draw_texture_rect(HBNoteData.NOTE_GRAPHICS[data.note_type].note, rect, false)
