extends HBEditorPlugin

var creator_control

func _init(_editor).(_editor):
	creator_control = preload("res://tools/editor/editor_plugins/SlideHoldCreator/SlideHoldCreatorControl.tscn").instance()
	add_tool_to_tools_tab(creator_control, "Slide Hold Creator")
	creator_control.connect("create_notes", self, "_on_create_notes")

func _on_create_notes(notes_per_note: float, beats: float):
	# Slide Holds are set 1/32th of a note apart of eachother
	if _editor.selected.size() > 0:
		var timeline_item = _editor.selected[0] as EditorTimelineItem
		if timeline_item.data is HBNoteData:
			var note_data = timeline_item.data as HBNoteData
			if note_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT or note_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT:
				var bars_per_minute = _editor.get_bpm() / float(_editor.get_beats_per_bar())
				var seconds_per_bar = 60.0/bars_per_minute

#				var note_length = 1.0/4.0 # a quarter of a beat
#				var interval = (note_resolution / note_length) * beat_length
				
				var starting_time = note_data.time
				# base separation for slide hold pieces is 7500/bpm for placing them
				# every 1/32th
				var time_interval = (7500 / float(_editor.current_song.bpm)) * (1/float(notes_per_note) / (1.0/32.0))
				var notes_to_create = beats * (notes_per_note/4.0)
				var initial_x_offset = 48
				var interval_x_offset = 32
				_editor.undo_redo.create_action("Create slide hold pieces")
				for i in range(notes_to_create):
					var note_time = starting_time + ((i+1) * time_interval)
					var note_position = note_data.position
					var position_increment = initial_x_offset + interval_x_offset * i
					var new_note_type = HBNoteData.NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE
					if note_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
						position_increment += -1
						new_note_type = HBNoteData.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE
					note_position.x += position_increment
					var new_note = HBNoteData.new()
					new_note.note_type = new_note_type
					new_note.time = note_time
					new_note.position = note_position
					new_note.oscillation_amplitude = note_data.oscillation_amplitude
					new_note.oscillation_frequency = note_data.oscillation_frequency
					new_note.entry_angle = note_data.entry_angle
					var note_timeline_item = new_note.get_timeline_item()
					_editor.undo_redo.add_do_method(_editor, "add_item_to_layer", timeline_item._layer, note_timeline_item)
					_editor.undo_redo.add_do_method(_editor, "_on_timing_points_changed")
					_editor.undo_redo.add_undo_method(timeline_item._layer, "remove_item", note_timeline_item)
					_editor.undo_redo.add_undo_method(timeline_item._layer, "deselect")
					_editor.undo_redo.add_undo_method(_editor, "_on_timing_points_changed")
				_editor.undo_redo.commit_action()
			else:
				show_error(tr("You have to select a slide note for this to work!"))
			
