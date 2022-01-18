extends HBEditorPlugin

var x_spinbox
var y_spinbox
var angle_spinbox

func _init(_editor).(_editor):
	var vbox_container = VBoxContainer.new()
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var pos_container = HBoxContainer.new()
	
	var pos_label = Label.new()
	pos_label.text = tr("Shift position by:")
	
	var x_label = Label.new()
	x_label.text = "x:"
	x_spinbox = HBEditorSpinBox.new()
	x_spinbox.size_flags_horizontal = x_spinbox.SIZE_EXPAND_FILL	
	x_spinbox.step = 1
	x_spinbox.max_value = 10000
	x_spinbox.min_value = -10000
	
	var y_label = Label.new()
	y_label.text = "y:"
	y_spinbox = HBEditorSpinBox.new()
	y_spinbox.size_flags_horizontal = y_spinbox.SIZE_EXPAND_FILL
	y_spinbox.step = 1
	y_spinbox.max_value = 10000
	y_spinbox.min_value = -10000
	
	pos_container.add_child(x_label)
	pos_container.add_child(x_spinbox)
	pos_container.add_child(y_label)
	pos_container.add_child(y_spinbox)
	
	var angle_container = HBoxContainer.new()
	
	var angle_label = Label.new()
	angle_label.text = tr("Shift angle by:")
	
	var degrees_label = Label.new()
	degrees_label.text = "Degrees:"
	angle_spinbox = HBEditorSpinBox.new()
	angle_spinbox.size_flags_horizontal = angle_spinbox.SIZE_EXPAND_FILL
	angle_spinbox.step = 1
	angle_spinbox.max_value = 360
	angle_spinbox.min_value = -360
	
	angle_container.add_child(degrees_label)
	angle_container.add_child(angle_spinbox)
	
	var action_container = HBoxContainer.new()
	
	var apply_button = Button.new()
	apply_button.text = "Shift"
	apply_button.size_flags_horizontal = apply_button.SIZE_EXPAND_FILL
	apply_button.connect("pressed", self, "_on_apply_button_pressed")
	action_container.add_child(apply_button)
	
	var reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.size_flags_horizontal = reset_button.SIZE_EXPAND_FILL
	reset_button.connect("pressed", self, "_on_reset_button_pressed")
	action_container.add_child(reset_button)
	
	vbox_container.add_child(pos_label)
	vbox_container.add_child(pos_container)
	vbox_container.add_child(angle_label)
	vbox_container.add_child(angle_container)
	vbox_container.add_child(action_container)
	
	add_tool_to_tools_tab(vbox_container, "Shift notes")

func _on_apply_button_pressed():
	var selected = _editor.selected
	var undo_redo = _editor.undo_redo as UndoRedo
	
	var pos_offset = Vector2(x_spinbox.value, y_spinbox.value)
	var angle_offset = angle_spinbox.value
	
	if selected:
		if pos_offset != Vector2.ZERO or angle_offset:
			undo_redo.create_action("Shift selected timing points")
			
			for item in selected:
				if item.data is HBBaseNote:
					var note = item.data as HBBaseNote
					
					var new_pos = note.position + pos_offset
					var new_angle = note.entry_angle + angle_offset
					undo_redo.add_do_property(note, "position", new_pos)
					undo_redo.add_undo_property(note, "position", note.position)
					undo_redo.add_do_property(note, "entry_angle", fmod(new_angle, 360.0))
					undo_redo.add_undo_property(note, "entry_angle", note.entry_angle)
					
					if pos_offset:
						undo_redo.add_do_property(note, "pos_modified", true)
						undo_redo.add_undo_property(note, "pos_modified", note.pos_modified)
					
					undo_redo.add_do_method(item, "update_widget_data")
					undo_redo.add_undo_method(item, "update_widget_data")
		
		undo_redo.add_do_method(_editor.inspector, "sync_visible_values_with_data")
		undo_redo.add_undo_method(_editor.inspector, "sync_visible_values_with_data")
		undo_redo.add_undo_method(_editor, "_on_timing_points_changed")
		undo_redo.add_do_method(_editor, "_on_timing_points_changed")
		undo_redo.commit_action()


func _on_reset_button_pressed():
	x_spinbox.value = 0
	y_spinbox.value = 0
	angle_spinbox.value = 0
