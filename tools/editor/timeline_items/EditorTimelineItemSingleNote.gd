extends EditorTimelineItemNote

class_name EditorTimelineItemSingleNote

const WIDTH = 5.0

func _init():
	_class_name = "EditorTimelineItemSingleNote" # Workaround for godot#4708
	_inheritance.append("EditorTimelineItemNote")

func _ready():
	super._ready()
	set_texture()
	data.connect("note_type_changed", Callable(self, "set_texture"))
	data.connect("hold_toggled", Callable(self, "set_texture"))
	data.connect("hold_toggled", Callable(self, "queue_redraw"))
	get_viewport().connect("size_changed", Callable(self, "_on_view_port_size_changed"))
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
		
		$HoldTextureRect.set_deferred("size", Vector2(get_size().y, get_size().y))
		$HoldTextureRect.position = Vector2(-get_size().y / 2, 0)
	
	$TextureRect.set_deferred("size", Vector2(get_size().y, get_size().y))
	$TextureRect.position = Vector2(-get_size().y / 2, 0)

func get_timeline_item_size():
	return Vector2(WIDTH, size.y)

func get_duration():
	return 100

func get_editor_widget():
	return preload("res://tools/editor/widgets/NoteMovementWidget.tscn")

func select():
	super.select()
	$TextureRect.modulate = Color(0.5, 0.5, 0.5, 1.0)

func deselect():
	super.deselect()
	$TextureRect.modulate = Color.WHITE
#	emit_signal("property_changed", "position", old_pos, data.position)

func _on_view_port_size_changed():
	if self.widget:
		# HACK: On linux we wait one frame because the size transformation doesn't
		# get applied on time, user should not notice this
		await get_tree().process_frame
		var new_pos = editor.rhythm_game.remap_coords(data.position)
		self.widget.position = new_pos - self.widget.size / 2

func connect_widget(widget: HBEditorWidget):
	super.connect_widget(widget)

func _draw():
	if data is HBNoteData and data.hold:
		var y = $TextureRect.size.y/2.0
		var target = Vector2(editor.scale_msec(editor.get_hold_size(data)), y)
		draw_line(Vector2(0.0, y), target, ResourcePackLoader.get_note_trail_color(data.note_type))
