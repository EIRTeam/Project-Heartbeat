extends HBEditorModule

var offset_spinbox

var hovered_time = 0

var button_change_submenu: PopupMenu

const BUTTON_CHANGE_ALLOWED_TYPES = ["UP", "DOWN", "LEFT", "RIGHT", "SLIDE_LEFT", "SLIDE_RIGHT", "HEART"]

func _ready():
	for action in ["make_normal", "toggle_double", "toggle_sustain", "toggle_hold"]:
		add_shortcut("editor_" + action, "_on_contextual_menu_item_pressed", [action])

func get_shortcut_from_action(action: String) -> int:
	var action_list = InputMap.get_action_list(action)
	var event = InputEventKey.new()
	
	for ev in action_list:
		if ev is InputEventKey:
			event = ev
			break
	
	return event.get_scancode_with_modifiers()

func set_editor(p_editor):
	.set_editor(p_editor)
	
	var contextual_menu := get_contextual_menu()
	contextual_menu.connect("about_to_show", self, "_on_contextual_menu_about_to_show")
	
	contextual_menu.connect("item_pressed", self, "_on_contextual_menu_item_pressed")
	
	button_change_submenu = PopupMenu.new()
	button_change_submenu.name = "ChangeButtonSubmenu"
	button_change_submenu.connect("index_pressed", self, "_on_button_change_submenu_index_pressed")
	
	contextual_menu.add_child(button_change_submenu)
	contextual_menu.add_submenu_item("Change type", "ChangeButtonSubmenu")
	
	for type in BUTTON_CHANGE_ALLOWED_TYPES:
		var pretty_name = type.capitalize()
		button_change_submenu.add_item(pretty_name)
	
	contextual_menu.add_separator()
	
	contextual_menu.add_contextual_item("Convert to normal", "make_normal")
	contextual_menu.add_contextual_item("Toggle double", "toggle_double")
	contextual_menu.add_contextual_item("Toggle sustain", "toggle_sustain")
	contextual_menu.add_contextual_item("Toggle hold", "toggle_hold")
	
	update_shortcuts()

func update_shortcuts():
	var contextual_menu := get_contextual_menu()
	
	# We havent created the items yet
	if not contextual_menu.name_id_map:
		return
	
	for i in range(button_change_submenu.get_item_count()):
		var name = button_change_submenu.get_item_text(i)
		
		var action_name = "note_" + name.to_lower()
		match name:
			"Slide Left":
				action_name = "slide_left"
			"Slide Right":
				action_name = "slide_right"
			"Heart":
				action_name = "heart_note"
		
		button_change_submenu.set_item_accelerator(i, get_shortcut_from_action(action_name))
	
	contextual_menu.set_contextual_item_accelerator("make_normal", get_shortcut_from_action("editor_make_normal"))
	contextual_menu.set_contextual_item_accelerator("toggle_double", get_shortcut_from_action("editor_toggle_double"))
	contextual_menu.set_contextual_item_accelerator("toggle_sustain", get_shortcut_from_action("editor_toggle_sustain"))
	contextual_menu.set_contextual_item_accelerator("toggle_hold", get_shortcut_from_action("editor_toggle_hold"))

func _on_contextual_menu_item_pressed(item_name: String):
	match item_name:
		"make_normal":
			change_note_type("Note")
		"toggle_double":
			toggle_double()
		"toggle_sustain":
			toggle_sustain()
		"toggle_hold":
			toggle_hold()

func _on_button_change_submenu_index_pressed(index: int):
	var new_button = BUTTON_CHANGE_ALLOWED_TYPES[index]
	change_note_button(new_button)
		
func change_note_button(new_button_name):
	var new_button = HBBaseNote.NOTE_TYPE[new_button_name]
	var changed_buttons = []
	if get_selected().size() > 0:
		undo_redo.create_action("Change note button to " + new_button_name)

		var layer_name = HBUtils.find_key(HBBaseNote.NOTE_TYPE, new_button)

		var new_layer = find_layer_by_name(layer_name)

		for item in get_selected():
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
			
			undo_redo.add_do_method(self, "add_item_to_layer", new_layer, new_item)
			undo_redo.add_do_method(item, "deselect")
			undo_redo.add_undo_method(self, "remove_item_from_layer", new_layer, new_item)
			
			undo_redo.add_do_method(self, "remove_item_from_layer", item._layer, item)
			undo_redo.add_undo_method(new_item, "deselect")
			undo_redo.add_undo_method(self, "add_item_to_layer", item._layer, item)
			changed_buttons.append(new_item)
		undo_redo.add_do_method(self, "timing_points_changed")
		undo_redo.add_undo_method(self, "timing_points_changed")
		undo_redo.add_undo_method(self, "deselect_all")
		undo_redo.add_do_method(self, "deselect_all")
		undo_redo.commit_action()
	return changed_buttons
		
func change_note_type(new_type: String):
	if get_selected().size() > 0:
		undo_redo.create_action("Convert note to " + new_type)
		
		for item in get_selected():
			var data = item.data as HBBaseNote
			var new_data_ser = data.serialize()
			new_data_ser["type"] = new_type
			
			if new_type == "SustainNote":
				new_data_ser["end_time"] = data.time + get_sustain_size(data.time)
			
			if new_type == "Note":
				new_data_ser["hold"] = false
			
			var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
			var new_item = new_data.get_timeline_item()
			
			undo_redo.add_do_method(self, "add_item_to_layer", item._layer, new_item)
			undo_redo.add_do_method(item, "deselect")
			undo_redo.add_do_method(self, "remove_item_from_layer", item._layer, item)

			undo_redo.add_undo_method(self, "remove_item_from_layer", item._layer, new_item)
			undo_redo.add_undo_method(new_item, "deselect")
			undo_redo.add_undo_method(self, "add_item_to_layer", item._layer, item)
		
		undo_redo.add_do_method(self, "timing_points_changed")
		undo_redo.add_undo_method(self, "timing_points_changed")
		
		undo_redo.add_do_method(self, "deselect_all")
		undo_redo.add_undo_method(self, "deselect_all")
		
		undo_redo.commit_action()

func _on_contextual_menu_about_to_show():
	hovered_time = get_time_being_hovered()
	var contextual_menu := get_contextual_menu()
	contextual_menu.set_contextual_item_disabled("paste", editor.copied_points.size() == 0)
	
	var disable_all = get_selected().size() <= 0
	
	for item in ["make_normal", "toggle_sustain", "toggle_double", "toggle_hold"]:
		contextual_menu.set_contextual_item_disabled(item, disable_all)
	
	for i in range(button_change_submenu.get_item_count()):
		button_change_submenu.set_item_disabled(i, disable_all)
	
	if disable_all:
		return
	
	for selected in get_selected():
		if not selected.data is HBBaseNote:
			continue
		if selected.data is HBNoteData and (selected.data.is_slide_note() or selected.data.is_slide_hold_piece()):
			contextual_menu.set_contextual_item_disabled("make_normal", true)
			contextual_menu.set_contextual_item_disabled("toggle_double", true)
			contextual_menu.set_contextual_item_disabled("toggle_sustain", true)
			contextual_menu.set_contextual_item_disabled("toggle_hold", true)

# Change note type by an amount.
func change_note_button_by(amount):
	var new_items = []
	
	var found = false
	for item in get_selected():
		if item is EditorTimelineItemNote:
			found = true
	
	if not found: 
		return
	
	# Yes, its flipped. Blame the editor layer order.
	if amount < 0:
		undo_redo.create_action("Increase note type")
	else:
		undo_redo.create_action("Decrease note type")
	
	for item in get_selected():
		if item is EditorTimelineItemNote:
			if check_valid_change(amount, item):
				# Use mod 4 so that all values range from 0 to 3, add 4 so that we only ever deal with naturals.
				var new_note_type = (item.data.note_type + amount + 4) % 4
				
				var layer_name = HBUtils.find_key(HBBaseNote.NOTE_TYPE, new_note_type)
				var new_layer = find_layer_by_name(layer_name)
				
				var data = item.data as HBBaseNote
				if not data:
					continue
				
				var new_data_ser = data.serialize()
				new_data_ser["note_type"] = new_note_type
				
				var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
				var new_item = new_data.get_timeline_item()
				new_items.append(new_item)
				
				undo_redo.add_do_method(self, "add_item_to_layer", new_layer, new_item)
				undo_redo.add_undo_method(self, "remove_item_from_layer", new_layer, new_item)
				
				undo_redo.add_do_method(self, "remove_item_from_layer", item._layer, item)
				undo_redo.add_undo_method(self, "add_item_to_layer", item._layer, item)
			else:
				new_items.append(item)
	
	undo_redo.add_do_method(self, "timing_points_changed")
	undo_redo.add_undo_method(self, "timing_points_changed")
	
	undo_redo.add_do_method(self, "deselect_all")
	undo_redo.add_undo_method(self, "deselect_all")
	
	var selected = get_selected()
	for i in new_items.size():
		undo_redo.add_do_method(self, "select_item", new_items[i], true)
		undo_redo.add_undo_method(self, "select_item", selected[i], true)
	
	undo_redo.commit_action()

func check_valid_change(amount, item):
	var new_type = item.data.note_type + amount
	
	for note in get_notes_at_time(item.data.time):
		if note.note_type == new_type:
			return false
	
	return item.data.note_type >= HBNoteData.NOTE_TYPE.UP and item.data.note_type <= HBNoteData.NOTE_TYPE.RIGHT


func toggle_sustain():
	var open_sustains = []
	var closed_sustains = []
	var existing_sustains = []
	
	var selected = get_selected()
	if selected.size() < 1:
		return
	
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
	
	undo_redo.create_action("Toggle sustain")
	
	for pair in closed_sustains:
		var start = pair[0]
		var end = pair[1]
		
		if pair[0].data is HBNoteData and pair[0].data.is_slide_note():
			# It will say convert to sustain but it will create a slide instead
			# This will trigger my ocd but at least the shortcut will be the same ig
			var start_data = start.data as HBNoteData
			
			var timing_map = get_timing_map()
			var start_idx = upper_bound(timing_map, start_data.time)
			var end_idx = timing_map.bsearch(end.data.time)
			
			var initial_x_offset = 48
			var interval_x_offset = 32
			
			for i in range(start_idx, end_idx + 1):
				# Make 2 notes per grid division
				for j in range(2):
					var note_time = timing_map[i]
					if j == 0:
						note_time += timing_map[i - 1]
						note_time /= 2.0
					
					var note_position = start_data.position
					var position_increment = initial_x_offset + interval_x_offset * ((i - start_idx) * 2 + j)
					note_position.x += position_increment
					
					var new_note_type = HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT
					if start_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
						position_increment *= -1
						new_note_type = HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT
					
					var new_note = HBNoteData.new()
					new_note.note_type = new_note_type
					new_note.time = note_time
					new_note.position = note_position
					new_note.oscillation_amplitude = start_data.oscillation_amplitude
					new_note.oscillation_frequency = start_data.oscillation_frequency
					new_note.entry_angle = start_data.entry_angle
					
					var new_item = new_note.get_timeline_item()
					
					undo_redo.add_do_method(self, "add_item_to_layer", start._layer, new_item)
					undo_redo.add_undo_method(self, "remove_item_from_layer", start._layer, new_item)
					undo_redo.add_undo_method(new_item, "deselect")
			
			undo_redo.add_do_method(self, "remove_item_from_layer", end._layer, end)
			undo_redo.add_undo_method(self, "add_item_to_layer", end._layer, end)
			
			undo_redo.add_do_method(start, "deselect")
			undo_redo.add_do_method(end, "deselect")
			undo_redo.add_undo_method(start, "deselect")
			undo_redo.add_undo_method(end, "deselect")
		else:
			var start_data = start.data as HBBaseNote
			var new_data_ser = start_data.serialize()
			new_data_ser["type"] = "SustainNote"
			new_data_ser["end_time"] = end.data.time
			
			var new_data = HBSerializable.deserialize(new_data_ser) as HBSustainNote
			var new_item = new_data.get_timeline_item()
			
			undo_redo.add_do_method(self, "add_item_to_layer", start._layer, new_item)
			undo_redo.add_do_method(self, "remove_item_from_layer", end._layer, end)
			undo_redo.add_do_method(self, "remove_item_from_layer", end._layer, start)
			undo_redo.add_do_method(start, "deselect")
			undo_redo.add_do_method(end, "deselect")
			
			undo_redo.add_undo_method(new_item, "deselect")
			undo_redo.add_undo_method(self, "remove_item_from_layer", start._layer, new_item)
			undo_redo.add_undo_method(self, "add_item_to_layer", start._layer, start)
			undo_redo.add_undo_method(self, "add_item_to_layer", end._layer, end)
	
	for item in open_sustains:
		if item.data is HBNoteData and item.data.is_slide_note():
			continue
		
		var data = item.data as HBBaseNote
		
		var new_data_ser = data.serialize()
		new_data_ser["type"] = "SustainNote"
		new_data_ser["end_time"] = data.time + get_sustain_size(data.time)
		
		var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
		var new_item = new_data.get_timeline_item()
		
		undo_redo.add_do_method(self, "add_item_to_layer", item._layer, new_item)
		undo_redo.add_do_method(item, "deselect")
		undo_redo.add_do_method(self, "remove_item_from_layer", item._layer, item)

		undo_redo.add_undo_method(self, "remove_item_from_layer", item._layer, new_item)
		undo_redo.add_undo_method(new_item, "deselect")
		undo_redo.add_undo_method(self, "add_item_to_layer", item._layer, item)
	
	for item in existing_sustains:
		var data = item.data as HBBaseNote
	
		var new_data_ser = data.serialize()
		new_data_ser["type"] = "Note"
		
		var new_data = HBSerializable.deserialize(new_data_ser) as HBSustainNote
		var new_item = new_data.get_timeline_item()
		
		undo_redo.add_do_method(self, "remove_item_from_layer", item._layer, item)
		undo_redo.add_do_method(item, "deselect")
		undo_redo.add_do_method(self, "add_item_to_layer", item._layer, new_item)
		
		undo_redo.add_undo_method(self, "remove_item_from_layer", item._layer, new_item)
		undo_redo.add_undo_method(new_item, "deselect")
		undo_redo.add_undo_method(self, "add_item_to_layer", item._layer, item)
	
	undo_redo.add_do_method(self, "timing_points_changed")
	undo_redo.add_undo_method(self, "timing_points_changed")
	
	undo_redo.add_do_method(self, "deselect_all")
	undo_redo.add_undo_method(self, "deselect_all")
	
	undo_redo.commit_action()

func get_sustain_size(time: int):
	var normalized_timing_map = get_normalized_timing_map()
	
	var start_idx = closest_bound(normalized_timing_map, time)
	var end_idx = min(start_idx + 2, normalized_timing_map.size() - 1)
	
	return normalized_timing_map[end_idx] - normalized_timing_map[start_idx]

func toggle_double():
	var selected := get_selected()
	if selected.size() < 1:
		return
		
	var notes_to_process := []
	
	for item in selected:
		if item.data is HBNoteData and (item.data.is_slide_note() or item.data.is_slide_hold_piece()):
			continue
		notes_to_process.append(item)
	
	if notes_to_process.size() == 0:
		return
	
	undo_redo.create_action("Toggle double")
	
	for item in notes_to_process:
		var new_type = "DoubleNote"
		if item.data is HBDoubleNote:
			new_type = "Note"
		
		var data = item.data as HBBaseNote
		
		var new_data_ser = data.serialize()
		new_data_ser["type"] = new_type
		
		var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
		var new_item = new_data.get_timeline_item()
		
		undo_redo.add_do_method(self, "remove_item_from_layer", item._layer, item)
		undo_redo.add_do_method(item, "deselect")
		undo_redo.add_do_method(self, "add_item_to_layer", item._layer, new_item)
		
		undo_redo.add_undo_method(self, "remove_item_from_layer", item._layer, new_item)
		undo_redo.add_undo_method(new_item, "deselect")
		undo_redo.add_undo_method(self, "add_item_to_layer", item._layer, item)
	
	undo_redo.add_do_method(self, "timing_points_changed")
	undo_redo.add_undo_method(self, "timing_points_changed")
	
	undo_redo.add_do_method(self, "deselect_all")
	undo_redo.add_undo_method(self, "deselect_all")
	
	undo_redo.commit_action()

func toggle_hold():
	var selected = get_selected()
	if selected.size() < 1:
		return
	
	undo_redo.create_action("Toggle hold")
	
	for item in selected:
		if item.data is HBNoteData:
			undo_redo.add_do_property(item.data, "hold", not item.data.hold)
			undo_redo.add_undo_property(item.data, "hold", item.data.hold)
		else:
			var new_data_ser = item.data.serialize()
			new_data_ser["type"] = "Note"
			new_data_ser["hold"] = true
			
			var new_data = HBSerializable.deserialize(new_data_ser) as HBNoteData
			var new_item = new_data.get_timeline_item()
			
			undo_redo.add_do_method(self, "remove_item_from_layer", item._layer, item)
			undo_redo.add_do_method(self, "add_item_to_layer", item._layer, new_item)
			
			undo_redo.add_undo_method(self, "remove_item_from_layer", item._layer, new_item)
			undo_redo.add_undo_method(self, "add_item_to_layer", item._layer, item)
	
	undo_redo.add_do_method(editor.inspector, "sync_visible_values_with_data")
	undo_redo.add_undo_method(editor.inspector, "sync_visible_values_with_data")
	
	undo_redo.add_do_method(self, "timing_points_changed")
	undo_redo.add_undo_method(self, "timing_points_changed")
	
	undo_redo.add_do_method(self, "deselect_all")
	undo_redo.add_undo_method(self, "deselect_all")
	
	undo_redo.commit_action()

func _sort_by_data_time(a, b):
	return a.data.time < b.data.time


func _unhandled_input(event):
	if shortcuts_blocked():
		return
	
	if event.is_action("editor_change_note_up", true) and event.pressed:
		change_note_button_by(-1)
	elif event.is_action("editor_change_note_down", true) and event.pressed:
		change_note_button_by(1)
	
	if event.is_action("editor_make_normal", true) and event.pressed and not event.echo:
		change_note_type("HBBaseNote")
	if event.is_action("editor_toggle_sustain", true) and event.pressed and not event.echo:
		toggle_sustain()
	if event.is_action("editor_toggle_double", true) and event.pressed and not event.echo:
		toggle_double()
	if event.is_action("editor_toggle_hold", true) and event.pressed and not event.echo:
		toggle_hold()
