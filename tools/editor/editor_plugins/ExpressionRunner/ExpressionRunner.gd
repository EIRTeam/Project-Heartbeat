extends HBEditorPlugin

const ALLOWED_OUTPUTS = {
	"position": TYPE_VECTOR2,
	"time": TYPE_INT,
	"entry_angle": TYPE_REAL,
	"oscillation_amplitude": TYPE_REAL,
	"oscillation_frequency": TYPE_REAL,
	"time_out": TYPE_INT
}

var line_edit

enum EXPRESSION_MODES {
	Y_OUT,
	X_OUT
}

var expression = Expression.new()
var output_selector = OptionButton.new()


func _init(_editor).(_editor):
	var vbox_container = VBoxContainer.new()
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Output label & option selector
	
	var output_label = Label.new()
	output_label.text = tr("Output to:")
	
	var i = 0
	for possibility in ALLOWED_OUTPUTS:
		output_selector.add_item(possibility.capitalize())
		output_selector.set_item_metadata(i, possibility)
		i += 1
	
	# Expression input
	
	var expression_label = Label.new()
	expression_label.text = tr("Expression:")
	line_edit = LineEdit.new()
	
	vbox_container.add_child(output_label)
	vbox_container.add_child(output_selector)
	vbox_container.add_child(expression_label)
	vbox_container.add_child(line_edit)
	
	var apply_button = Button.new()
	apply_button.text = "Execute expression"
	apply_button.clip_text = true
	apply_button.connect("pressed", self, "_on_apply_button_pressed")
	vbox_container.add_child(apply_button)
	
	add_tool_to_tools_tab(vbox_container, "Expression Runner")

func _on_apply_button_pressed():
	var value = line_edit.text
	
	var editor = get_editor() as HBEditor
	var undo_redo = editor.undo_redo as UndoRedo
	
	if get_editor().selected.size() > 0:
		var outputs = {}
	
		for timeline_item in get_editor().selected:
			expression.parse(value, ["note"])
			var note_data = timeline_item.data as HBBaseNote
			
			var result = expression.execute([note_data])
			
			if expression.has_execute_failed():
				show_error("Error executing expression: %s" % [expression.get_error_text()])
				outputs = {}
				break
			elif typeof(result) == ALLOWED_OUTPUTS[output_selector.get_selected_metadata()]:
				outputs[timeline_item] = result
			else:
				 # Type error
				show_error("Type error, are you sure your output matches the type of the selected output property? got %s" % [result.get_type()])
				outputs = {}
				break
		if outputs.size() > 0:
			var property_name = output_selector.get_selected_metadata()
			undo_redo.create_action("Run expression for %s" % [output_selector.get_selected_metadata()])
			
			for selected_item in outputs:
				var note_data = selected_item.data as HBBaseNote
				
				var result = outputs[selected_item]

				var old_value = note_data.get(property_name)
				
				undo_redo.add_do_property(note_data, property_name, result)
				undo_redo.add_do_method(editor, "_on_timing_points_changed")
				undo_redo.add_do_method(selected_item._layer, "place_child", selected_item)
				
				undo_redo.add_undo_property(note_data, property_name, old_value)
				undo_redo.add_undo_method(editor, "_on_timing_points_changed")
				undo_redo.add_undo_method(selected_item._layer, "place_child", selected_item)
				
				if property_name == "position" or property_name:
					undo_redo.add_do_method(selected_item, "update_widget_data")
					undo_redo.add_undo_method(selected_item, "update_widget_data")
				
			undo_redo.commit_action()
			get_editor().inspector.sync_visible_values_with_data()
