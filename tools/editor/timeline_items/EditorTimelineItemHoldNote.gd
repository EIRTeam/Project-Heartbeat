extends "res://tools/editor/timeline_items/EditorTimelineItemSingleNote.gd"

func _init():
	update_affects_timing_points = true
func _ready():
	connect("property_changed", self, "_on_property_changed")
	set_texture()
	
func get_inspector_properties():
	var props = HBUtils.merge_dict(.get_inspector_properties(),  {
		"end_time": {
			"type": "int"
		}
	})
	return props

func _on_property_changed(property_name, old_value, new_value):
	if property_name == "note_type":
		set_texture()

func get_duration():
	return data.duration

func set_texture():
	.set_texture()
	update()
	
func _on_view_port_size_changed():
	if self.widget:
		# HACK: On linux we wait one frame because the size transformation doesn't
		# get applied on time, user should not notice this
		yield(get_tree(), "idle_frame")
		var new_pos = editor.rhythm_game.remap_coords(data.position)
		self.widget.rect_position = new_pos - self.widget.rect_size / 2
	
func connect_widget(widget: HBEditorWidget):
	.connect_widget(widget)
	
func _draw():
	pass
#	var line_color = Color(HBNoteData.NOTE_COLORS[data.note_type].color)
#	line_color.a = 1.0
#	draw_line(Vector2(0, rect_size.y/2), Vector2(rect_size.x, rect_size.y/2), Color.white, rect_size.y / 2)
#	draw_line(Vector2(0, rect_size.y/2), Vector2(rect_size.x, rect_size.y/2), line_color, rect_size.y / 4)
#	var note_pos = Vector2(rect_size.x - get_size().y / 2.0, 0)
#	var rect = Rect2(note_pos, Vector2(get_size().y, get_size().y))
#	draw_texture_rect(HBNoteData.NOTE_GRAPHICS[data.note_type].note, rect, false)

func get_editor_widget():
	return preload("res://tools/editor/widgets/NoteMovementWidget.tscn")

func _on_note_moved(new_position: Vector2):
	var old_pos = data.position
	data.position = editor.snap_position_to_grid(editor.rhythm_game.inv_map_coords(new_position + widget.rect_size/2))
	emit_signal("property_changed", "position", old_pos, data.position)
