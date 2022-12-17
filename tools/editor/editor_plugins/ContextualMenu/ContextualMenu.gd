extends HBEditorPlugin

var offset_spinbox

var delete_icon = preload("res://tools/icons/icon_remove.svg")
var cut_icon = preload("res://tools/icons/ActionCut.svg")
var copy_icon = preload("res://tools/icons/icon_action_copy.svg")
var paste_icon = preload("res://tools/icons/icon_action_paste.svg")
var interp_icon = preload("res://tools/icons/InterpLinear.svg")
var hovered_time = 0

const BUTTON_CHANGE_ALLOWED_TYPES = ["UP", "DOWN", "LEFT", "RIGHT", "SLIDE_RIGHT", "SLIDE_LEFT", "HEART"]

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
	
	var button_change_submenu = PopupMenu.new()
	button_change_submenu.name = "ChangeButtonSubmenu"
	button_change_submenu.connect("index_pressed", self, "_on_button_change_submenu_index_pressed")
	
	contextual_menu.add_child(button_change_submenu)
	contextual_menu.add_submenu_item("Change type", "ChangeButtonSubmenu")
	
	for type in BUTTON_CHANGE_ALLOWED_TYPES:
		var pretty_name = type.capitalize()
		button_change_submenu.add_item(pretty_name)
	
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
			make_sustain()

		
func _on_button_change_submenu_index_pressed(index: int):
	var new_button = BUTTON_CHANGE_ALLOWED_TYPES[index]
	change_note_button(new_button)
		
func change_note_button(new_button_name):
	var editor = get_editor()
	var undo_redo = get_editor().undo_redo as UndoRedo
	var new_button = HBBaseNote.NOTE_TYPE[new_button_name]
	var changed_buttons = []
	if get_editor().selected.size() > 0:
		undo_redo.create_action("Change note button to " + new_button_name)

		var layer_name = HBUtils.find_key(HBBaseNote.NOTE_TYPE, new_button)

		var new_layer = get_editor().timeline.find_layer_by_name(layer_name)

		for item in get_editor().selected:
			var data = item.data as HBBaseNote
			if not data:
				continue
			var new_data_ser = data.serialize()
			
			new_data_ser["note_type"] = new_button
			
			# Fallbacks when converting illegal note types
			if new_button == HBBaseNote.NOTE_TYPE.SLIDE_LEFT or new_button == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
				new_data_ser["type"] = "Note"
			
			if new_button == HBBaseNote.NOTE_TYPE.HEART:
				if new_data_ser["type"] == "SustainNote":
					new_data_ser["type"] = "Note"
			var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
			
			var new_item = new_data.get_timeline_item()
			
			undo_redo.add_do_method(editor, "add_item_to_layer", new_layer, new_item)
			undo_redo.add_do_method(item, "deselect")
			undo_redo.add_undo_method(editor, "remove_item_from_layer", new_layer, new_item)
			
			undo_redo.add_do_method(editor, "remove_item_from_layer", item._layer, item)
			undo_redo.add_undo_method(new_item, "deselect")
			undo_redo.add_undo_method(editor, "add_item_to_layer", item._layer, item)
			changed_buttons.append(new_item)
		undo_redo.add_do_method(editor, "_on_timing_points_changed")
		undo_redo.add_undo_method(editor, "_on_timing_points_changed")
		undo_redo.add_undo_method(editor, "deselect_all")
		undo_redo.add_do_method(editor, "deselect_all")
		undo_redo.commit_action()
	return changed_buttons
		
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
				new_data_ser["end_time"] = data.time + get_sustain_size(editor)
			var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
			
			var new_item = new_data.get_timeline_item()
			
			undo_redo.add_do_method(editor, "add_item_to_layer", item._layer, new_item)
			undo_redo.add_do_method(item, "deselect")
			undo_redo.add_do_method(editor, "remove_item_from_layer", item._layer, item)

			undo_redo.add_undo_method(editor, "remove_item_from_layer", item._layer, new_item)
			undo_redo.add_undo_method(new_item, "deselect")
			undo_redo.add_undo_method(editor, "add_item_to_layer", item._layer, item)
		undo_redo.add_do_method(editor, "_on_timing_points_changed")
		undo_redo.add_undo_method(editor, "_on_timing_points_changed")
		undo_redo.add_undo_method(editor.inspector, "stop_inspecting")
		undo_redo.add_do_method(editor.inspector, "stop_inspecting")
		undo_redo.add_do_method(editor, "deselect_all")
		undo_redo.add_undo_method(editor, "deselect_all")
		
		undo_redo.add_do_method(editor, "force_game_process")
		undo_redo.add_undo_method(editor, "force_game_process")
		
		
		undo_redo.commit_action()
func _on_contextual_menu_about_to_show():
	hovered_time = get_editor().timeline.get_time_being_hovered()
	var contextual_menu := get_contextual_menu()
	contextual_menu.set_contextual_item_disabled("paste", get_editor().copied_points.size() == 0)
	
	var disable_all =  get_editor().selected.size() <= 0
	
	for item in ["delete", "cut", "copy", "interpolate", "make_sustain", "make_double", "make_normal"]:
		contextual_menu.set_contextual_item_disabled(item, disable_all)
	
	if disable_all:
		return
	
	for selected in get_editor().selected:
		if not selected.data is HBBaseNote:
			continue
		if selected.data is HBNoteData and (selected.data.is_slide_note() or selected.data.is_slide_hold_piece()):
			contextual_menu.set_contextual_item_disabled("make_double", true)
			contextual_menu.set_contextual_item_disabled("make_normal", true)
			contextual_menu.set_contextual_item_disabled("make_sustain", true)


# Change note type by an amount.
func change_note_button_by(amount):
	var editor = get_editor()
	var undo_redo = get_editor().undo_redo as UndoRedo
	var new_items = []
	# Yes, its flipped. Blame the editor layer order.
	if amount < 0:
		undo_redo.create_action("Increase note type")
	else:
		undo_redo.create_action("Decrease note type")
	
	for item in editor.selected:
		if item is EditorTimelineItemNote:
			if check_valid_change(amount, item):
				# Use mod 4 so that all values range from 0 to 3, add 4 so that we only ever deal with naturals.
				var new_note_type = (item.data.note_type + amount + 4) % 4
				
				var layer_name = HBUtils.find_key(HBBaseNote.NOTE_TYPE, new_note_type)
				var new_layer = get_editor().timeline.find_layer_by_name(layer_name)
				
				var data = item.data as HBBaseNote
				if not data:
					continue
				
				var new_data_ser = data.serialize()
				new_data_ser["note_type"] = new_note_type
				
				var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
				var new_item = new_data.get_timeline_item()
				new_items.append(new_item)
				
				undo_redo.add_do_method(editor, "add_item_to_layer", new_layer, new_item)
				undo_redo.add_undo_method(editor, "remove_item_from_layer", new_layer, new_item)
				
				undo_redo.add_do_method(editor, "remove_item_from_layer", item._layer, item)
				undo_redo.add_undo_method(editor, "add_item_to_layer", item._layer, item)
			else:
				new_items.append(item)
	
	undo_redo.add_do_method(editor, "_on_timing_points_changed")
	undo_redo.add_undo_method(editor, "_on_timing_points_changed")
	
	undo_redo.add_do_method(editor, "deselect_all")
	undo_redo.add_undo_method(editor, "deselect_all")
	for i in new_items.size():
		undo_redo.add_do_method(editor, "select_item", new_items[i], true)
		undo_redo.add_undo_method(editor, "select_item", editor.selected[i], true)
	
	undo_redo.commit_action()

func check_valid_change(amount, item):
	var editor = get_editor()
	var new_type = item.data.note_type + amount
	
	for editor_item in editor.get_items_at_time(item.data.time):
		if editor_item is EditorTimelineItemNote:
			if editor_item.data.note_type == new_type:
				if not editor_item in editor.selected or not check_valid_change(amount, editor_item):
					return false
	
	return item.data.note_type >= HBNoteData.NOTE_TYPE.UP and item.data.note_type <= HBNoteData.NOTE_TYPE.RIGHT


func make_sustain(toggle = false):
	var editor = get_editor() as HBEditor
	var undo_redo = editor.undo_redo
	var open_sustains = []
	var closed_sustains = []
	var existing_sustains = []
	
	if editor.selected.size() < 1:
		return
	
	var selected = editor.selected
	selected.sort_custom(self, "_sort_by_data_time")
	
	for item in selected:
		if item.data is HBBaseNote and not item.data is HBSustainNote:
			var found = false
			for open_sustain in open_sustains:
				if item.data.note_type == open_sustain.data.note_type:
					open_sustains.erase(open_sustain)
					closed_sustains.append([open_sustain, item])
					found = true
					break
			
			if not found:
				open_sustains.append(item)
		elif item.data is HBSustainNote:
			existing_sustains.append(item)
	
	if not toggle:
		undo_redo.create_action("Convert note to SustainNote")
	else:
		undo_redo.create_action("Toggle sustain")
	
	for pair in closed_sustains:
		var start = pair[0]
		var end = pair[1]
		
		if pair[0].data is HBNoteData and pair[0].data.is_slide_note():
			# It will say convert to sustain but it will create a slide instead
			# This will trigger my ocd but at least the shortcut will be the same ig
			var start_data = start.data as HBNoteData
			var notes_per_note = editor.get_note_resolution() / 2.0
			var beats = (end.data.time - start_data.time) / (editor.get_note_resolution() * editor.note_resolution_box.value) 
			
			var time_interval = (7500 / float(editor.bpm)) * ((1.0/32.0) / notes_per_note)
			time_interval = time_interval
			var notes_to_create = ceil(beats * (notes_per_note/4.0)) * 2
			
			var initial_x_offset = 48
			var interval_x_offset = 32
			
			for i in range(notes_to_create):
				var note_time = start_data.time + ((i+1) * time_interval)
				var note_position = start_data.position
				var position_increment = initial_x_offset + interval_x_offset * i
				var new_note_type = HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT
				if start_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
					position_increment *= -1
					new_note_type = HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT
				note_position.x += position_increment
				var new_note = HBNoteData.new()
				new_note.note_type = new_note_type
				new_note.time = note_time
				new_note.position = note_position
				new_note.oscillation_amplitude = start_data.oscillation_amplitude
				new_note.oscillation_frequency = start_data.oscillation_frequency
				new_note.entry_angle = start_data.entry_angle
				var new_item = new_note.get_timeline_item()
				editor.undo_redo.add_do_method(editor, "add_item_to_layer", start._layer, new_item)
				editor.undo_redo.add_undo_method(editor, "remove_item_from_layer", start._layer, new_item)
				editor.undo_redo.add_undo_method(new_item, "deselect")
			
			undo_redo.add_do_method(editor, "remove_item_from_layer", end._layer, end)
			undo_redo.add_undo_method(editor, "add_item_to_layer", end._layer, end)
			
			editor.undo_redo.add_do_method(start, "deselect")
			editor.undo_redo.add_do_method(end, "deselect")
			editor.undo_redo.add_undo_method(start, "deselect")
			editor.undo_redo.add_undo_method(end, "deselect")
		else:
			var start_data = start.data as HBBaseNote
			var new_data_ser = start_data.serialize()
			new_data_ser["type"] = "SustainNote"
			new_data_ser["end_time"] = end.data.time
			
			var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
			var new_item = new_data.get_timeline_item()
			
			undo_redo.add_do_method(editor, "add_item_to_layer", start._layer, new_item)
			undo_redo.add_do_method(start, "deselect")
			undo_redo.add_do_method(end, "deselect")
			undo_redo.add_undo_method(start._layer, "remove_item", new_item)
			
			undo_redo.add_do_method(editor, "remove_item_from_layer", end._layer, start)
			undo_redo.add_do_method(editor, "remove_item_from_layer", end._layer, end)
			undo_redo.add_undo_method(new_item, "deselect")
			undo_redo.add_undo_method(editor, "add_item_to_layer", start._layer, start)
			undo_redo.add_undo_method(editor, "add_item_to_layer", end._layer, end)
	
	for item in open_sustains:
		if item.data is HBNoteData and item.data.is_slide_note():
			continue
		
		var data = item.data as HBBaseNote
		
		var new_data_ser = data.serialize()
		new_data_ser["type"] = "SustainNote"
		new_data_ser["end_time"] = data.time + get_sustain_size(editor)
		
		var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
		var new_item = new_data.get_timeline_item()
		
		undo_redo.add_do_method(editor, "add_item_to_layer", item._layer, new_item)
		undo_redo.add_do_method(item, "deselect")
		undo_redo.add_undo_method(item._layer, "remove_item", new_item)
		
		undo_redo.add_do_method(editor, "remove_item_from_layer", item._layer, item)
		undo_redo.add_undo_method(new_item, "deselect")
		undo_redo.add_undo_method(editor, "add_item_to_layer", item._layer, item)
	
	for item in existing_sustains:
		if toggle:
			var data = item.data as HBBaseNote
		
			var new_data_ser = data.serialize()
			new_data_ser["type"] = "Note"
			
			var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
			var new_item = new_data.get_timeline_item()
			
			undo_redo.add_do_method(editor, "add_item_to_layer", item._layer, new_item)
			undo_redo.add_do_method(item, "deselect")
			undo_redo.add_undo_method(item._layer, "remove_item", new_item)
			
			undo_redo.add_do_method(editor, "remove_item_from_layer", item._layer, item)
			undo_redo.add_undo_method(new_item, "deselect")
			undo_redo.add_undo_method(editor, "add_item_to_layer", item._layer, item)
	
	undo_redo.add_do_method(editor, "_on_timing_points_changed")
	undo_redo.add_undo_method(editor, "_on_timing_points_changed")
	undo_redo.add_undo_method(editor.inspector, "stop_inspecting")
	undo_redo.add_do_method(editor.inspector, "stop_inspecting")
	undo_redo.add_do_method(editor, "deselect_all")
	undo_redo.add_undo_method(editor, "deselect_all")
	
	undo_redo.commit_action()

func get_sustain_size(editor: HBEditor):
	var timing_interval = editor.get_timing_interval()
	return timing_interval * editor.note_resolution_box.value / 2.0

func toggle_double():
	var editor = get_editor() as HBEditor
	var undo_redo = editor.undo_redo
	
	if editor.selected.size() < 1:
		return
	
	undo_redo.create_action("Toggle sustain")
	
	for item in editor.selected:
		var new_type = "DoubleNote"
		if item.data is HBDoubleNote:
			new_type = "Note"
		
		var data = item.data as HBBaseNote
		
		var new_data_ser = data.serialize()
		new_data_ser["type"] = new_type
		
		var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
		var new_item = new_data.get_timeline_item()
		
		undo_redo.add_do_method(editor, "add_item_to_layer", item._layer, new_item)
		undo_redo.add_do_method(item, "deselect")
		undo_redo.add_undo_method(item._layer, "remove_item", new_item)
		
		undo_redo.add_do_method(editor, "remove_item_from_layer", item._layer, item)
		undo_redo.add_undo_method(new_item, "deselect")
		undo_redo.add_undo_method(editor, "add_item_to_layer", item._layer, item)
	
	undo_redo.add_do_method(editor, "_on_timing_points_changed")
	undo_redo.add_undo_method(editor, "_on_timing_points_changed")
	undo_redo.add_undo_method(editor.inspector, "stop_inspecting")
	undo_redo.add_do_method(editor.inspector, "stop_inspecting")
	undo_redo.add_do_method(editor, "deselect_all")
	undo_redo.add_undo_method(editor, "deselect_all")
	
	undo_redo.commit_action()

func _sort_by_data_time(a, b):
	return a.data.time < b.data.time


func _unhandled_input(event):
	if event.is_action("editor_change_note_up", true) and event.pressed:
		change_note_button_by(-1)
	elif event.is_action("editor_change_note_down", true) and event.pressed:
		change_note_button_by(1)
		
	if event.is_action("editor_toggle_sustain", true) and event.pressed and not event.echo:
		make_sustain(true)
	if event.is_action("editor_toggle_double", true) and event.pressed and not event.echo:
		toggle_double()
