extends HBEditorPlugin

var offset_spinbox

func _init(_editor).(_editor):
	var vbox_container = VBoxContainer.new()
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var  hbox_container = HBoxContainer.new()
	var offset_label = Label.new()
	offset_label.text = tr("Offset (in milliseconds)")
	offset_spinbox = SpinBox.new()
	offset_spinbox.step = 1
	offset_spinbox.max_value = 10000
	offset_spinbox.min_value = -10000
	
	hbox_container.add_child(offset_label)
	hbox_container.add_child(offset_spinbox)
	
	vbox_container.add_child(hbox_container)
	
	var apply_button = Button.new()
	apply_button.text = "Apply offset"
	apply_button.clip_text = true
	apply_button.connect("pressed", self, "_on_apply_button_pressed")
	vbox_container.add_child(apply_button)
	
	add_tool_to_tools_tab(vbox_container, "Chart offset")

func _on_apply_button_pressed():
	var timeline = _editor.timeline
	var offset_value = offset_spinbox.value
	
	if offset_value != 0:
		var undo_redo = _editor.undo_redo as UndoRedo
		
		undo_redo.create_action("Offset all timing points")
		
		for layer in timeline.get_layers():
			for item in layer.get_editor_items():
				var data = item.data as HBTimingPoint
				var new_time = max(data.time + offset_value, 0)
				undo_redo.add_do_property(data, "time", new_time)
				undo_redo.add_undo_property(data, "time", data.time)
				
				if data is HBSustainNote:
					var new_end_time = max(data.end_time + offset_value, 0)
					undo_redo.add_do_property(data, "end_time", new_end_time)
					undo_redo.add_undo_property(data, "end_time", data.end_time)
					undo_redo.add_do_method(item, "sync_value", "end_time")
					undo_redo.add_undo_method(item, "sync_value", "end_time")
					
			undo_redo.add_do_method(layer, "place_all_children")
			undo_redo.add_undo_method(layer, "place_all_children")
		undo_redo.add_do_method(_editor.inspector, "sync_visible_values_with_data")
		undo_redo.add_undo_method(_editor.inspector, "sync_visible_values_with_data")
		undo_redo.add_undo_method(_editor, "_on_timing_points_changed")
		undo_redo.add_do_method(_editor, "_on_timing_points_changed")
		undo_redo.commit_action()
