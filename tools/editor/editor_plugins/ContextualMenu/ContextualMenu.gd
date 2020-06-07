extends HBEditorPlugin

var offset_spinbox

var delete_icon = preload("res://tools/icons/icon_remove.svg")
var cut_icon = preload("res://tools/icons/ActionCut.svg")
var copy_icon = preload("res://tools/icons/icon_action_copy.svg")
var paste_icon = preload("res://tools/icons/icon_action_paste.svg")
var interp_icon = preload("res://tools/icons/InterpLinear.svg")
var hovered_time = 0

func get_shortcut(keycode:int,modifier:=[]) -> int:
	var i := InputEventKey.new()
	i.control = modifier.has("ctrl")
	i.shift = modifier.has("shift")
	i.alt = modifier.has("alt")
	i.scancode = keycode
	return i.get_scancode_with_modifiers()

func _init(_editor).(_editor):
	var contextual_menu := get_contextual_menu()
	contextual_menu.connect("about_to_show", self, "_on_contextual_menu_about_to_show")

	contextual_menu.connect("item_pressed", self, "_on_contextual_menu_item_pressed")
	
	contextual_menu.add_contextual_item("Copy", "copy")
	contextual_menu.set_contextual_item_accelerator("copy", get_shortcut(KEY_C, ["ctrl"]))
	contextual_menu.set_contextual_item_icon("copy", copy_icon)
	
	contextual_menu.add_contextual_item("Cut", "cut")
	contextual_menu.set_contextual_item_icon("cut", cut_icon)
	contextual_menu.set_contextual_item_accelerator("cut", get_shortcut(KEY_X, ["ctrl"]))
	
	contextual_menu.add_contextual_item("Paste", "paste")
	contextual_menu.set_contextual_item_icon("paste", paste_icon)
	contextual_menu.set_contextual_item_accelerator("paste", get_shortcut(KEY_V, ["ctrl"]))
	
	contextual_menu.add_contextual_item("Delete", "delete")
	contextual_menu.set_contextual_item_icon("delete", delete_icon)
	contextual_menu.set_contextual_item_accelerator("delete", get_shortcut(KEY_DELETE))
	
	contextual_menu.add_separator()
	
	contextual_menu.add_contextual_item("Interpolate notes", "interpolate")
	contextual_menu.set_contextual_item_icon("interpolate", interp_icon)
	
	contextual_menu.add_separator()
	
	contextual_menu.add_contextual_item("Convert to normal", "make_normal")
	contextual_menu.add_contextual_item("Convert to double", "make_double")
	contextual_menu.add_contextual_item("Convert to sustain", "make_sustain")
func interpolate_selected():
	var selected_items := get_editor().selected as Array
	if selected_items.size() > 2:
		var undo_redo = get_editor().undo_redo as UndoRedo
		var min_note: HBBaseNote
		var max_note: HBBaseNote
		
		for item in selected_items:
			if item.data is HBBaseNote:
				if not min_note:
					min_note = item.data
					max_note = item.data
				if item.data.time > max_note.time:
					max_note = item.data
				if item.data.time < min_note.time:
					min_note = item.data
		if not min_note:
			return
		var selection_span = max_note.time - min_note.time
		
		if selection_span != 0:
		
			undo_redo.create_action("Interpolate selected notes")
	
			var starting_position = min_note.position
			var ending_position = max_note.position
	
			for item in selected_items:
				var item_data = item.data
				if item_data is HBBaseNote:
					var t = item_data.time - min_note.time
					var new_position = starting_position.linear_interpolate(ending_position, t/float(selection_span))
					undo_redo.add_do_property(item_data, "position", new_position)
					undo_redo.add_undo_property(item_data, "position", item_data.position)
			undo_redo.add_do_method(_editor.inspector, "sync_visible_values_with_data")
			undo_redo.add_undo_method(_editor.inspector, "sync_visible_values_with_data")
			undo_redo.add_undo_method(_editor, "_on_timing_points_changed")
			undo_redo.add_do_method(_editor, "_on_timing_points_changed")
			undo_redo.commit_action()
	
func _on_contextual_menu_item_pressed(item_name: String):
	match item_name:
		"copy":
			get_editor().copy_selected()
		"cut":
			get_editor().copy_selected()
			get_editor().delete_selected()
		"paste":
			get_editor().paste(hovered_time)
		"delete":
			get_editor().delete_selected()
		"interpolate":
			interpolate_selected()
		"make_normal":
			change_note_type("Note")
		"make_double":
			change_note_type("DoubleNote")
		"make_sustain":
			change_note_type("SustainNote")
func change_note_type(new_type: String):
	
	var editor = get_editor()
	var undo_redo = get_editor().undo_redo as UndoRedo
	
	if get_editor().selected.size() > 0:
		undo_redo.create_action("Convert note to " + new_type)

		for item in get_editor().selected:
			var data = item.data as HBBaseNote
			var new_data_ser = data.serialize()
			new_data_ser["type"] = new_type
			if new_type == "SustainNote":
				new_data_ser["end_time"] = data.time + 1000
			var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
			
			var new_item = new_data.get_timeline_item()
			
			undo_redo.add_do_method(editor, "add_item_to_layer", item._layer, new_item)
			undo_redo.add_do_method(item, "deselect")
			undo_redo.add_undo_method(item._layer, "remove_item", new_item)
			
			undo_redo.add_do_method(item._layer, "remove_item", item)
			undo_redo.add_undo_method(new_item, "deselect")
			undo_redo.add_undo_method(editor, "add_item_to_layer", item._layer, item)
		undo_redo.add_do_method(editor, "_on_timing_points_changed")
		undo_redo.add_undo_method(editor, "_on_timing_points_changed")
		undo_redo.add_undo_method(editor.inspector, "stop_inspecting")
		undo_redo.add_do_method(editor.inspector, "stop_inspecting")
		undo_redo.commit_action()
func _on_contextual_menu_about_to_show():
	hovered_time = get_editor().timeline.get_time_being_hovered()
	var contextual_menu := get_contextual_menu()
	var items_disabled = get_editor().selected.size() == 0
	for item in ["delete", "cut", "copy", "interpolate", "make_sustain", "make_double"]:
		contextual_menu.set_contextual_item_disabled(item, items_disabled)
	for selected in get_editor().selected:
		if selected.data is HBNoteData and selected.data.note_type == HBBaseNote.NOTE_TYPE.HEART:
			contextual_menu.set_contextual_item_disabled("make_sustain", true)
	for selected in get_editor().selected:
		if selected.data is HBNoteData and (selected.data.is_slide_note() or selected.data.is_slide_hold_piece()) \
				or selected.data.note_type == HBBaseNote.NOTE_TYPE.HEART:
			contextual_menu.set_contextual_item_disabled("make_double", true)
			contextual_menu.set_contextual_item_disabled("make_normal", true)
			contextual_menu.set_contextual_item_disabled("make_sustain", true)
			break
	contextual_menu.set_contextual_item_disabled("paste", get_editor().copied_points.size() == 0)
