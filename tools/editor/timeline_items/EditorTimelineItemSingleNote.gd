extends "res://tools/editor/timeline_items/EditorTimelineItemNote.gd"

const WIDTH = 5.0

func _ready():
	set_texture()
	data.connect("note_type_changed", self, "set_texture")
	data.connect("hold_toggled", self, "set_texture")
	data.connect("hold_toggled", self, "update")
	get_viewport().connect("size_changed", self, "_on_view_port_size_changed")
func set_texture():
	if data is HBSustainNote:
		$TextureRect.texture = HBNoteData.get_note_graphic(data.note_type, "sustain_note")
	elif data is HBDoubleNote:
		$TextureRect.texture = HBNoteData.get_note_graphic(data.note_type, "double_note")
	else:
		if data.is_slide_hold_piece():
			$TextureRect.texture = HBNoteData.get_note_graphic(data.note_type, "target")
		else:
			$TextureRect.texture = HBNoteData.get_note_graphic(data.note_type, "note")
	
	if has_node("HoldTextureRect"):
		if data is HBNoteData and data.hold:
			$HoldTextureRect.show()
		else:
			$HoldTextureRect.hide()
		
		$HoldTextureRect.set_deferred("rect_size", Vector2(get_size().y, get_size().y))
		$HoldTextureRect.rect_position = Vector2(-get_size().y / 2, 0)
	
	$TextureRect.set_deferred("rect_size", Vector2(get_size().y, get_size().y))
	$TextureRect.rect_position = Vector2(-get_size().y / 2, 0)

func get_size():
	return Vector2(WIDTH, rect_size.y)

func get_duration():
	return 100

func get_editor_widget():
	return preload("res://tools/editor/widgets/NoteMovementWidget.tscn")

func select():
	.select()
	$TextureRect.modulate = Color(0.5, 0.5, 0.5, 1.0)

func deselect():
	.deselect()
	$TextureRect.modulate = Color.white
#	emit_signal("property_changed", "position", old_pos, data.position)

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
	if data is HBNoteData and data.hold:
		var y = $TextureRect.rect_size.y/2.0
		var target = Vector2(editor.scale_msec(editor.get_hold_size(data)), y)
		draw_line(Vector2(0.0, y), target, ResourcePackLoader.get_note_trail_color(data.note_type))
