extends "res://tools/editor/timeline_items/EditorTimelineItemNote.gd"

const WIDTH = 5.0

func _ready():
	set_texture()
	data.connect("note_type_changed", self, "set_texture")
	get_viewport().connect("size_changed", self, "_on_view_port_size_changed")
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

func get_editor_widget():
	return preload("res://tools/editor/widgets/NoteMovementWidget.tscn")

func _on_note_moved(new_position: Vector2):
	data.position = editor.snap_position_to_grid(editor.rhythm_game.inv_map_coords(new_position + widget.rect_size/2))
	emit_signal("item_changed")

func _on_view_port_size_changed():
	if self.widget:
		# HACK: On linux we wait one frame because the size transformation doesn't
		# get applied on time, user should not notice this
		yield(get_tree(), "idle_frame")
		var new_pos = editor.rhythm_game.remap_coords(data.position)
		self.widget.rect_position = new_pos - self.widget.rect_size / 2

func connect_widget(widget: HBEditorWidget):
	.connect_widget(widget)
	widget.connect("note_moved", self, "_on_note_moved")
