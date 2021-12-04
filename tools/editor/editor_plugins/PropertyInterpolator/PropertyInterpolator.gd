extends HBEditorPlugin

var property_dropdown: OptionButton

var properties = [
	"time",
	"end_time",
	"time_out",
	"entry_angle",
	"oscillation_amplitude",
	"oscillation_frequency",
	"distance",
]

func _init(_editor).(_editor):
	var vbox_container = VBoxContainer.new()
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	property_dropdown = OptionButton.new()
	for property in properties:
		property_dropdown.add_item(property)
	
	var apply_button = Button.new()
	apply_button.text = "Interpolate"
	apply_button.size_flags_horizontal = apply_button.SIZE_EXPAND_FILL
	apply_button.connect("pressed", self, "_on_apply_button_pressed")
	
	vbox_container.add_child(property_dropdown)
	vbox_container.add_child(apply_button)
	
	add_tool_to_tools_tab(vbox_container, "Interpolate property")

func _on_apply_button_pressed():
	var selected = _editor.selected
	var undo_redo = _editor.undo_redo as UndoRedo
	var property = properties[property_dropdown.selected]
	
	var notes = []
	var items = {}
	
	for item in selected:
		if property in item.data:
			notes.append(item.data)
			items[item.data] = item
	notes.sort_custom(self, "_sort_by_time")
	
	if notes.size() > 2:
		undo_redo.create_action("Interpolate " + property)
		
		var min_time = notes[0].time
		var max_time = notes[-1].time
		var time_range = float(max_time - min_time)
		
		var first_property = notes[0][property]
		var last_property = notes[-1][property]
		
		if property == "entry_angle":
			first_property = fmod(fmod(first_property, 360) + 360, 360)
			last_property = fmod(fmod(last_property, 360) + 360, 360)
		
		for i in notes.size():
			var note = notes[i] as HBBaseNote
			var item = items[note]
			
			var t = 0
			if time_range > 0:
				if property == "time":
					t = i * (1 / float(notes.size() - 1))
				else:
					t = (note.time - min_time) / time_range
			
			var new_value = lerp(first_property, last_property, t)
			
			undo_redo.add_do_property(note, property, stepify(new_value, 2))
			undo_redo.add_undo_property(note, property, note[property])
			undo_redo.add_do_method(item, "update_widget_data")
			undo_redo.add_undo_method(item, "update_widget_data")
			
			if property == "time" or property == "end_time":
				undo_redo.add_do_method(item._layer, "place_child", item)
				undo_redo.add_undo_method(item._layer, "place_child", item)
			
			if property == "time" and note is HBSustainNote:
				var dt = new_value - note[property]
				undo_redo.add_do_property(note, "end_time", note.end_time + dt)
				undo_redo.add_undo_property(note, "end_time", note.end_time)
				undo_redo.add_do_method(item, "sync_value", "end_time")
				undo_redo.add_undo_method(item, "sync_value", "end_time")
		
		undo_redo.add_do_method(_editor.inspector, "sync_visible_values_with_data")
		undo_redo.add_undo_method(_editor.inspector, "sync_visible_values_with_data")
		undo_redo.add_undo_method(_editor, "_on_timing_points_changed")
		undo_redo.add_do_method(_editor, "_on_timing_points_changed")
		
		undo_redo.commit_action()

func _sort_by_time(a, b):
	return a.time < b.time
