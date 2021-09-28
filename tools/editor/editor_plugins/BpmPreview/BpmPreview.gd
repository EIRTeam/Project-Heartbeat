extends HBEditorPlugin

func _init(_editor).(_editor):
	var vbox_container = VBoxContainer.new()
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var create_button = Button.new()
	create_button.text = "Create metronome"
	create_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	create_button.connect("pressed", self, "_on_create_button_pressed")
	
	vbox_container.add_child(create_button)
	
	add_tool_to_tools_tab(vbox_container, "Metronome generator")

func _on_create_button_pressed():
	var interval = round(_editor.get_timing_interval())
	var offset = _editor.offset_box.value * 1000
	var layers = _editor.timeline.get_layers()
	var triangle_layer = layers[0]
	
	_editor.undo_redo.create_action("Create metronome")
	
	for t in range(_editor.get_song_length() * 1000 - offset):
		if not fmod(t, interval):
			var note = HBNoteData.new()
			note.time = _editor.snap_time_to_timeline(t + offset)
			note.note_type = HBBaseNote.NOTE_TYPE.UP
			var item = note.get_timeline_item()
			
			_editor.undo_redo.add_do_method(_editor, "add_item_to_layer", triangle_layer, item)
			_editor.undo_redo.add_undo_method(_editor, "remove_item_from_layer", triangle_layer, item)
	
	_editor.undo_redo.add_do_method(_editor, "_on_timing_points_changed")
	_editor.undo_redo.add_undo_method(_editor, "_on_timing_points_changed")
	
	_editor.undo_redo.commit_action()
