extends "res://tools/editor/timeline_items/EditorTimelineItemSingleNote.gd"

func _init():
	update_affects_timing_points = true
	
func set_widget_positions():
	if widget:
		widget.set_start_position(editor.rhythm_game.remap_coords(data.position))
		widget.set_end_position(editor.rhythm_game.remap_coords(data.target_position))
func _ready():
	connect("item_changed", self, "set_texture")
	set_texture()
	get_viewport().connect("size_changed", self, "_on_view_port_size_changed")
	
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
func _on_end_moved(new_pos: Vector2):
	data.target_position = editor.snap_position_to_grid(editor.rhythm_game.inv_map_coords(new_pos))
	emit_signal("item_changed")
	
func _on_start_moved(new_pos: Vector2):
	data.position = editor.snap_position_to_grid(editor.rhythm_game.inv_map_coords(new_pos))
	emit_signal("item_changed")
	
func _on_view_port_size_changed():
	if self.widget:
		# HACK: On linux we wait one frame because the size transformation doesn't
		# get applied on time, user should not notice this
		yield(get_tree(), "idle_frame")
		set_widget_positions()
	
func connect_widget(widget: HBEditorWidget):
	.connect_widget(widget)
	self.widget.rect_position = Vector2()
	self.widget.connect("start_moved", self, "_on_start_moved")
	self.widget.connect("end_moved", self, "_on_end_moved")
	set_widget_positions()
	
func _draw():
	var line_color = Color(HBNoteData.NOTE_COLORS[data.note_type].color)
	line_color.a = 0.5
	draw_line(Vector2(0, rect_size.y/2), Vector2(rect_size.x, rect_size.y/2), line_color, rect_size.y / 4)
	for note in range(data.number_of_notes-1):
		var note_x = (rect_size.x) * ((note+1.0)/float(data.number_of_notes-1))
		var note_pos = Vector2(note_x - get_size().y / 2, 0)
		var rect = Rect2(note_pos, Vector2(get_size().y, get_size().y))
		draw_texture_rect(HBNoteData.NOTE_GRAPHICS[data.note_type].note, rect, false)

func get_editor_widget():
	return preload("res://tools/editor/widgets/DualNoteMovementWidget.tscn")
