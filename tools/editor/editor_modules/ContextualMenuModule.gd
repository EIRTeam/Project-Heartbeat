extends HBEditorModule

var offset_spinbox

var button_change_submenu: PopupMenu
var selection_modifier_submenu: HBEditorContextualMenuControl
var type_selection_modifier_submenu: HBEditorContextualMenuControl

const BUTTON_CHANGE_ALLOWED_TYPES = ["UP", "DOWN", "LEFT", "RIGHT", "SLIDE_LEFT", "SLIDE_RIGHT", "HEART"]

const TYPE_SELECTION_ITEMS = {
	"notes": "HBBaseNote",
	"double_notes": "HBDoubleNote",
	"sustains": "HBSustainNote",
	"sections": "HBChartSection",
	"tempo_changes": "HBTimingChange",
	"speed_changes": "HBBPMChange",
}

func _ready():
	super._ready()
	for action in [
			"make_normal", "toggle_double", "toggle_sustain", "make_slide", "toggle_hold",
			"select_all", "deselect", "shift_selection_left", "shift_selection_right",
			"select_2nd", "select_3rd", "select_4th",
			"smooth_bpm",
		]:
		add_shortcut("editor_" + action, "_on_contextual_menu_item_pressed", [action])
	
	for type in TYPE_SELECTION_ITEMS.keys():
		var action = "select_only_" + type
		add_shortcut("editor_" + action, "_on_contextual_menu_item_pressed", [action])
	
	add_shortcut("editor_change_note_up", "change_note_button_by", [-1])
	add_shortcut("editor_change_note_down", "change_note_button_by", [1])

func get_shortcut_from_action(action: String) -> int:
	var action_list = InputMap.action_get_events(action)
	var event = InputEventKey.new()
	
	for ev in action_list:
		if ev is InputEventKey:
			event = ev
			break
	
	return event.get_keycode_with_modifiers()

func set_editor(p_editor):
	super.set_editor(p_editor)
	
	var contextual_menu := get_contextual_menu()
	contextual_menu.connect("item_pressed", Callable(self, "_on_contextual_menu_item_pressed"))
	
	selection_modifier_submenu = HBEditorContextualMenuControl.new()
	selection_modifier_submenu.name = "SelectionModifierSubmenu"
	selection_modifier_submenu.connect("item_pressed", Callable(self, "_on_contextual_menu_item_pressed"))
	
	selection_modifier_submenu.add_contextual_item("Select all", "select_all")
	selection_modifier_submenu.add_contextual_item("Deselect", "deselect")
	
	selection_modifier_submenu.add_contextual_item("Shift selection Left", "shift_selection_left")
	selection_modifier_submenu.add_contextual_item("Shift selection Right", "shift_selection_right")
	
	selection_modifier_submenu.add_contextual_item("Select every 2nd note", "select_2nd")
	selection_modifier_submenu.add_contextual_item("Select every 3rd note", "select_3rd")
	selection_modifier_submenu.add_contextual_item("Select every 4th note", "select_4th")
	
	type_selection_modifier_submenu = HBEditorContextualMenuControl.new()
	type_selection_modifier_submenu.name = "TypeSelectionModifierSubmenu"
	type_selection_modifier_submenu.connect("item_pressed", Callable(self, "_on_contextual_menu_item_pressed"))
	
	for type in TYPE_SELECTION_ITEMS.keys():
		var action = "select_only_" + type
		var text = "Select only " + type.replace("_", " ").capitalize()
		type_selection_modifier_submenu.add_contextual_item(text, action)
	
	selection_modifier_submenu.add_child(type_selection_modifier_submenu)
	selection_modifier_submenu.add_submenu_item("Select only...", "TypeSelectionModifierSubmenu")
	
	contextual_menu.add_child(selection_modifier_submenu)
	contextual_menu.add_submenu_item("Modify selection", "SelectionModifierSubmenu")
	
	contextual_menu.add_separator()
	
	button_change_submenu = PopupMenu.new()
	button_change_submenu.name = "ChangeButtonSubmenu"
	button_change_submenu.connect("index_pressed", Callable(self, "_on_button_change_submenu_index_pressed"))
	
	for type in BUTTON_CHANGE_ALLOWED_TYPES:
		var pretty_name = type.capitalize()
		button_change_submenu.add_item(pretty_name)
	
	contextual_menu.add_child(button_change_submenu)
	contextual_menu.add_submenu_item("Change note type", "ChangeButtonSubmenu")
	
	contextual_menu.add_separator()
	
	contextual_menu.add_contextual_item("Convert to normal", "make_normal")
	contextual_menu.add_contextual_item("Toggle hold", "toggle_hold")
	contextual_menu.add_contextual_item("Toggle sustain", "toggle_sustain")
	contextual_menu.add_contextual_item("Toggle double", "toggle_double")
	contextual_menu.add_contextual_item("Make slide chain", "make_slide")
	contextual_menu.add_contextual_item("Smooth out BPM change", "smooth_bpm")
	
	update_shortcuts()

func update_shortcuts():
	var contextual_menu := get_contextual_menu()
	
	# We havent created the items yet
	if not contextual_menu.name_id_map:
		return
	
	for action in ["select_all", "deselect", "shift_selection_left", "shift_selection_right", \
				   "select_2nd", "select_3rd", "select_4th"]:
		selection_modifier_submenu.set_contextual_item_accelerator(action, get_shortcut_from_action("editor_" + action))
	
	for type in TYPE_SELECTION_ITEMS.keys():
		var action = "select_only_" + type
		
		type_selection_modifier_submenu.set_contextual_item_accelerator(action, get_shortcut_from_action("editor_" + action))
	
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
	contextual_menu.set_contextual_item_accelerator("make_slide", get_shortcut_from_action("editor_make_slide"))
	contextual_menu.set_contextual_item_accelerator("toggle_hold", get_shortcut_from_action("editor_toggle_hold"))
	contextual_menu.set_contextual_item_accelerator("smooth_bpm", get_shortcut_from_action("editor_smooth_bpm"))

func _on_contextual_menu_item_pressed(item_name: String):
	if get_contextual_menu().get_contextual_item_disabled(item_name) and \
	   selection_modifier_submenu.get_contextual_item_disabled(item_name) and \
	   type_selection_modifier_submenu.get_contextual_item_disabled(item_name):
		return
	
	match item_name:
		"select_all":
			select_all()
		"deselect":
			deselect_all()
		"shift_selection_left":
			shift_selection_by(-1)
		"shift_selection_right":
			shift_selection_by(1)
		"select_2nd":
			select_subset(2)
		"select_3rd":
			select_subset(3)
		"select_4th":
			select_subset(4)
		"make_normal":
			change_note_type("Note")
		"toggle_double":
			toggle_double()
		"toggle_sustain":
			toggle_sustain()
		"make_slide":
			make_slide()
		"toggle_hold":
			toggle_hold()
		"smooth_bpm":
			smooth_bpm()
	
	var type_key = item_name.trim_prefix("select_only_")
	if type_key in TYPE_SELECTION_ITEMS.keys():
		select_type_subset(TYPE_SELECTION_ITEMS[type_key])

func _on_button_change_submenu_index_pressed(index: int):
	var new_button = BUTTON_CHANGE_ALLOWED_TYPES[index]
	change_note_button(new_button)
		
func change_note_button(new_button_name):
	var type = HBBaseNote.NOTE_TYPE[new_button_name]
	
	var changed_buttons = []
	if get_selected().size() > 0:
		undo_redo.create_action("Change selected note's type to " + new_button_name)
		
		var layer_name = HBUtils.find_key(HBBaseNote.NOTE_TYPE, type)
		var new_layer = find_layer_by_name(layer_name)
		
		for item in get_selected():
			var data = item.data as HBBaseNote
			if not data:
				continue
			
			var new_data_ser = data.serialize()
			
			new_data_ser["note_type"] = type
			if data is HBNoteData and data.is_slide_hold_piece():
				if type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT:
					new_data_ser["note_type"] = HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT
				
				if type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
					new_data_ser["note_type"] = HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT
			
			# Fallbacks when converting illegal note types
			if type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT or type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
				new_data_ser["type"] = "Note"
				new_data_ser["hold"] = false
			elif type == HBBaseNote.NOTE_TYPE.HEART:
				new_data_ser["hold"] = false
			
			var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
			
			new_data.set_meta("second_layer", layer_name.ends_with("2"))
			
			var new_item = new_data.get_timeline_item()
			
			undo_redo.add_do_method(self.add_item_to_layer.bind(new_layer, new_item))
			undo_redo.add_do_method(item.deselect)
			undo_redo.add_undo_method(self.remove_item_from_layer.bind(new_layer, new_item))
			
			undo_redo.add_do_method(self.remove_item_from_layer.bind(item._layer, item))
			undo_redo.add_undo_method(new_item.deselect)
			undo_redo.add_undo_method(self.add_item_to_layer.bind(item._layer, item))
			
			changed_buttons.append(new_item)
		
		undo_redo.add_do_method(self.timing_points_changed)
		undo_redo.add_undo_method(self.timing_points_changed)
		
		undo_redo.add_undo_method(self.deselect_all)
		undo_redo.add_do_method(self.deselect_all)
		
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
			
			undo_redo.add_do_method(self.add_item_to_layer.bind(item._layer, new_item))
			undo_redo.add_do_method(item.deselect)
			undo_redo.add_do_method(self.remove_item_from_layer.bind(item._layer, item))

			undo_redo.add_undo_method(self.remove_item_from_layer.bind(item._layer, new_item))
			undo_redo.add_undo_method(new_item.deselect)
			undo_redo.add_undo_method(self.add_item_to_layer.bind(item._layer, item))
		
		undo_redo.add_do_method(self.timing_points_changed)
		undo_redo.add_undo_method(self.timing_points_changed)
		
		undo_redo.add_do_method(self.deselect_all)
		undo_redo.add_undo_method(self.deselect_all)
		
		undo_redo.commit_action()

func update_selected():
	var contextual_menu := get_contextual_menu()
	
	var disable_all = get_selected().size() <= 0
	
	for item in ["make_normal", "toggle_sustain", "make_slide", "toggle_double", "toggle_hold", "smooth_bpm"]:
		contextual_menu.set_contextual_item_disabled(item, disable_all)
	
	for i in range(button_change_submenu.get_item_count()):
		button_change_submenu.set_item_disabled(i, disable_all)
	
	for item in [
			"deselect", "shift_selection_left", "shift_selection_right",
			"select_2nd", "select_3rd", "select_4th",
		]:
		selection_modifier_submenu.set_contextual_item_disabled(item, disable_all)
	
	for type in TYPE_SELECTION_ITEMS.keys():
		var action = "select_only_" + type
		type_selection_modifier_submenu.set_contextual_item_disabled(action, disable_all)
	
	if disable_all:
		return
	
	contextual_menu.set_contextual_item_disabled("make_slide", true)
	contextual_menu.set_contextual_item_disabled("smooth_bpm", true)
	
	var slide_count := 0
	for selected in get_selected():
		if not selected.data is HBBaseNote:
			continue
		if selected.data is HBNoteData and (selected.data.is_slide_note() or selected.data.is_slide_hold_piece()):
			contextual_menu.set_contextual_item_disabled("make_normal", true)
			contextual_menu.set_contextual_item_disabled("toggle_double", true)
			contextual_menu.set_contextual_item_disabled("toggle_sustain", true)
			contextual_menu.set_contextual_item_disabled("toggle_hold", true)
			
			slide_count += 1
			if slide_count == 2:
				contextual_menu.set_contextual_item_disabled("make_slide", false)
				break
	
	if get_selected().size() == 1:
		if get_selected()[0].data is HBBPMChange or get_selected()[0].data is HBTimingChange:
				contextual_menu.set_contextual_item_disabled("smooth_bpm", false)

# Change note type by an amount.
func change_note_button_by(amount):
	var new_items = []
	
	var found = false
	for item in get_selected():
		if item is EditorTimelineItemNote:
			found = true
			break
	
	if not found: 
		return
	
	var new_types := {}
	for item in get_selected():
		if item is EditorTimelineItemNote:
			if not check_valid_change(amount, item, new_types):
				return
	
	# Yes, its flipped. Blame the editor layer order.
	if amount < 0:
		undo_redo.create_action("Increase note type")
	else:
		undo_redo.create_action("Decrease note type")
	
	for item in get_selected():
		if item is EditorTimelineItemNote:
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
			
			undo_redo.add_do_method(self.add_item_to_layer.bind(new_layer, new_item))
			undo_redo.add_undo_method(self.remove_item_from_layer.bind(new_layer, new_item))
			
			undo_redo.add_do_method(self.remove_item_from_layer.bind(item._layer, item))
			undo_redo.add_undo_method(self.add_item_to_layer.bind(item._layer, item))
	
	undo_redo.add_do_method(self.timing_points_changed)
	undo_redo.add_undo_method(self.timing_points_changed)
	
	undo_redo.add_do_method(self.deselect_all)
	undo_redo.add_undo_method(self.deselect_all)
	
	var selected = get_selected()
	for i in new_items.size():
		undo_redo.add_do_method(self.select_item.bind(new_items[i], true))
		undo_redo.add_undo_method(self.select_item.bind(selected[i], true))
	
	undo_redo.commit_action()

func check_valid_change(amount: int, item: EditorTimelineItem, new_types: Dictionary):
	# Use mod 4 so that all values range from 0 to 3, add 4 so that we only ever deal with naturals.
	var new_type = (item.data.note_type + amount + 4) % 4
	
	if item.data.time in new_types and new_type in new_types[item.data.time]:
		return false
	
	for i in get_items_at_time(item.data.time):
		if i.data is HBBaseNote and i.data.note_type == new_type and not i in get_selected():
			return false
	
	if item.data.note_type >= HBNoteData.NOTE_TYPE.UP and item.data.note_type <= HBNoteData.NOTE_TYPE.RIGHT:
		if not item.data.time in new_types:
			new_types[item.data.time] = []
		
		new_types[item.data.time].append(new_type)
		
		return true
	else:
		return false


func toggle_sustain():
	var open_sustains = []
	var closed_sustains = []
	var existing_sustains = []
	
	var selected = get_selected()
	if selected.size() < 1:
		return
	
	selected.sort_custom(Callable(self, "_sort_by_data_time"))
	
	for item in selected:
		if item.data is HBBaseNote and not item.data is HBSustainNote and \
		   not (item.data is HBNoteData and (item.data.is_slide_note() or item.data.is_slide_hold_piece())):
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
		
		var start_data = start.data as HBBaseNote
		var new_data_ser = start_data.serialize()
		new_data_ser["type"] = "SustainNote"
		new_data_ser["end_time"] = end.data.time
		
		var new_data = HBSerializable.deserialize(new_data_ser) as HBSustainNote
		var new_item = new_data.get_timeline_item()
		
		undo_redo.add_do_method(self.add_item_to_layer.bind(start._layer, new_item))
		undo_redo.add_do_method(self.remove_item_from_layer.bind(end._layer, end))
		undo_redo.add_do_method(self.remove_item_from_layer.bind(end._layer, start))
		undo_redo.add_do_method(start.deselect)
		undo_redo.add_do_method(end.deselect)
		
		undo_redo.add_undo_method(new_item.deselect)
		undo_redo.add_undo_method(self.remove_item_from_layer.bind(start._layer, new_item))
		undo_redo.add_undo_method(self.add_item_to_layer.bind(start._layer, start))
		undo_redo.add_undo_method(self.add_item_to_layer.bind(end._layer, end))
	
	for item in open_sustains:
		var data = item.data as HBBaseNote
		
		var new_data_ser = data.serialize()
		new_data_ser["type"] = "SustainNote"
		new_data_ser["end_time"] = data.time + get_sustain_size(data.time)
		
		var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
		var new_item = new_data.get_timeline_item()
		
		undo_redo.add_do_method(self.add_item_to_layer.bind(item._layer, new_item))
		undo_redo.add_do_method(item.deselect)
		undo_redo.add_do_method(self.remove_item_from_layer.bind(item._layer, item))

		undo_redo.add_undo_method(self.remove_item_from_layer.bind(item._layer, new_item))
		undo_redo.add_undo_method(new_item.deselect)
		undo_redo.add_undo_method(self.add_item_to_layer.bind(item._layer, item))
	
	for item in existing_sustains:
		var data = item.data as HBBaseNote
	
		var new_data_ser = data.serialize()
		new_data_ser["type"] = "Note"
		
		var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
		var new_item = new_data.get_timeline_item()
		
		undo_redo.add_do_method(self.remove_item_from_layer.bind(item._layer, item))
		undo_redo.add_do_method(item.deselect)
		undo_redo.add_do_method(self.add_item_to_layer.bind(item._layer, new_item))
		
		undo_redo.add_undo_method(self.remove_item_from_layer.bind(item._layer, new_item))
		undo_redo.add_undo_method(new_item.deselect)
		undo_redo.add_undo_method(self.add_item_to_layer.bind(item._layer, item))
	
	undo_redo.add_do_method(self.timing_points_changed)
	undo_redo.add_undo_method(self.timing_points_changed)
	
	undo_redo.add_do_method(self.deselect_all)
	undo_redo.add_undo_method(self.deselect_all)
	
	undo_redo.commit_action()

func get_sustain_size(time: int):
	var normalized_timing_map = get_normalized_timing_map()
	
	var start_idx = bsearch_closest(normalized_timing_map, time)
	var end_idx = min(start_idx + 2, normalized_timing_map.size() - 1)
	
	return normalized_timing_map[end_idx] - normalized_timing_map[start_idx]

func make_slide():
	var open_slides := []
	var closed_slides := []
	
	var selected = get_selected()
	if selected.size() < 1:
		return
	
	selected.sort_custom(Callable(self, "_sort_by_data_time"))
	
	for item in selected:
		if item.data is HBNoteData and item.data.is_slide_note():
			var found = false
			for open_slide in open_slides:
				if item.data.note_type == open_slide.data.note_type:
					open_slides.erase(open_slide)
					closed_slides.append([open_slide, item])
					found = true
					break
			
			if not found:
				open_slides.append(item)
	
	undo_redo.create_action("Make slide chain")
	
	for pair in closed_slides:
		var start = pair[0]
		var end = pair[1]
		
		var start_data = start.data as HBNoteData
		
		var timing_map = get_timing_map()
		var start_idx = bsearch_upper(timing_map, start_data.time)
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
				new_note.set_meta("second_layer", "2" in start._layer.layer_name)
				
				var new_item = new_note.get_timeline_item()
				
				undo_redo.add_do_method(self.add_item_to_layer.bind(start._layer, new_item))
				undo_redo.add_undo_method(self.remove_item_from_layer.bind(start._layer, new_item))
				undo_redo.add_undo_method(new_item.deselect)
		
		undo_redo.add_do_method(self.remove_item_from_layer.bind(end._layer, end))
		undo_redo.add_undo_method(self.add_item_to_layer.bind(end._layer, end))
		
		undo_redo.add_do_method(start.deselect)
		undo_redo.add_do_method(end.deselect)
		undo_redo.add_undo_method(start.deselect)
		undo_redo.add_undo_method(end.deselect)
	
	undo_redo.add_do_method(self.timing_points_changed)
	undo_redo.add_undo_method(self.timing_points_changed)
	
	undo_redo.add_do_method(self.deselect_all)
	undo_redo.add_undo_method(self.deselect_all)
	
	undo_redo.commit_action()

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
		
		undo_redo.add_do_method(self.remove_item_from_layer.bind(item._layer, item))
		undo_redo.add_do_method(item.deselect)
		undo_redo.add_do_method(self.add_item_to_layer.bind(item._layer, new_item))
		
		undo_redo.add_undo_method(self.remove_item_from_layer.bind(item._layer, new_item))
		undo_redo.add_undo_method(new_item.deselect)
		undo_redo.add_undo_method(self.add_item_to_layer.bind(item._layer, item))
	
	undo_redo.add_do_method(self.timing_points_changed)
	undo_redo.add_undo_method(self.timing_points_changed)
	
	undo_redo.add_do_method(self.deselect_all)
	undo_redo.add_undo_method(self.deselect_all)
	
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
			
			undo_redo.add_do_method(self.remove_item_from_layer.bind(item._layer, item))
			undo_redo.add_do_method(self.add_item_to_layer.bind(item._layer, new_item))
			
			undo_redo.add_undo_method(self.remove_item_from_layer.bind(item._layer, new_item))
			undo_redo.add_undo_method(self.add_item_to_layer.bind(item._layer, item))
	
	undo_redo.add_do_method(editor.inspector.sync_visible_values_with_data)
	undo_redo.add_undo_method(editor.inspector.sync_visible_values_with_data)
	
	undo_redo.add_do_method(self.timing_points_changed)
	undo_redo.add_undo_method(self.timing_points_changed)
	
	undo_redo.add_do_method(self.deselect_all)
	undo_redo.add_undo_method(self.deselect_all)
	
	undo_redo.commit_action()

func _sort_by_data_time(a, b):
	return a.data.time < b.data.time

func _is_type_selected(item, selected_types) -> bool:
	for _class_name in selected_types:
		if _class_name in item.data._inheritance or _class_name == item.data._class_name:
			return true
	
	return false

func _get_base_type(item) -> String:
	if "HBBaseNote" in item.data._inheritance:
		return "HBBaseNote"
	
	return item.data._class_name

func shift_selection_by(by: int):
	var items := get_timeline_items()
	items.sort_custom(Callable(self, "_sort_by_data_time"))
	
	var selected := get_selected()
	
	var selected_types := []
	for item in selected:
		var _class_name = _get_base_type(item)
		
		if not _class_name in selected_types:
			selected_types.append(_class_name)
	
	var total := 0.0
	var div := 0
	for i in range(1, selected.size()):
		var diff := get_time_as_eight(selected[i].data.time) - \
					get_time_as_eight(selected[i - 1].data.time)
		
		if diff != 0:
			total += diff
			div += 1
	
	var max_diff := 9999999999999999999.0
	if div:
		max_diff = total / div
	
	var new_selected := []
	for i in range(items.size()):
		if items[i] in selected:
			var j = clamp(i + by, 0, items.size() - 1)
			while not _is_type_selected(items[j], selected_types):
				if j <= 0:
					j = 0
					break
				if j >= items.size() - 1:
					j = items.size() - 1
					break
				
				j += by
			
			var diff := abs(get_time_as_eight(items[i].data.time) - \
							get_time_as_eight(items[j].data.time))
			
			if diff <= max_diff and _is_type_selected(items[j], selected_types):
				new_selected.append(items[j])
	
	deselect_all()
	for item in new_selected:
		select_item(item, true)

func select_subset(subset: int):
	var selected := get_selected()
	if selected.size() < 1:
		return
	
	var new_selected := []
	for i in range(selected.size()):
		if i % subset != 0:
			continue
		
		new_selected.append(selected[i])
	
	deselect_all()
	for item in new_selected:
		select_item(item, true)

func select_type_subset(type: String):
	var selected := get_selected()
	if selected.size() < 1:
		return
	
	var new_selected := []
	for item in selected:
		if _is_type_selected(item, [type]):
			new_selected.append(item)
	
	deselect_all()
	for item in new_selected:
		select_item(item, true)

func smooth_bpm():
	if not get_selected():
		return
	
	var speed_change := get_selected()[0].data as HBTimingPoint
	
	var last_speed_change := HBBPMChange.new()
	var last_timing_change: HBTimingChange
	var last_change
	
	var speed_changes := get_speed_changes()
	for change in speed_changes:
		if change.time == speed_change.time:
			break
		
		if change is HBBPMChange:
			last_speed_change = change
		
		if change is HBTimingChange:
			last_timing_change = change
		
		last_change = change
	
	if not last_change or not last_timing_change:
		return
	
	var end_bpm
	if speed_change is HBBPMChange and speed_change.usage == HBBPMChange.USAGE_TYPES.AUTO_BPM:
		end_bpm = (speed_change.speed_factor / 100.0) * last_timing_change.bpm
	elif speed_change is HBTimingChange and last_speed_change.usage == HBBPMChange.USAGE_TYPES.AUTO_BPM:
		end_bpm = (last_speed_change.speed_factor / 100.0) * speed_change.bpm
	else:
		end_bpm = speed_change.bpm
	
	var timeout = HBBaseNote.new().get_time_out(end_bpm)
	
	var start_t = speed_change.time - timeout
	start_t = max(start_t, last_change.time)
	
	var cut_off = (start_t == last_change.time)
	
	var start_bpm
	if last_speed_change.time > last_timing_change.time and last_speed_change.usage == HBBPMChange.USAGE_TYPES.FIXED_BPM:
		start_bpm = last_speed_change.bpm
	elif last_speed_change.usage == HBBPMChange.USAGE_TYPES.AUTO_BPM:
		start_bpm = (last_speed_change.speed_factor / 100.0) * last_timing_change.bpm
	else:
		start_bpm = last_timing_change.bpm
	
	var times_to_interpolate := []
	for point in get_timing_points():
		if not point is HBBaseNote:
			continue
		
		if point.time >= start_t and point.time < speed_change.time and not point.time in times_to_interpolate:
			times_to_interpolate.append(point.time)
	
	if cut_off and not start_t in times_to_interpolate:
		times_to_interpolate.append(start_t)
	
	times_to_interpolate.reverse()
	
	if not times_to_interpolate:
		return
	
	var events_layer = find_layer_by_name("Events")
	var start_i = 1 if cut_off else 0
	
	undo_redo.create_action("Smooth out BPM change.")
	for i in range(start_i, times_to_interpolate.size()):
		var time = times_to_interpolate[i]
		var w := float(i) / float(times_to_interpolate.size())
		
		var new_speed_change = HBBPMChange.new()
		new_speed_change.time = time
		
		if last_speed_change.usage == HBBPMChange.USAGE_TYPES.AUTO_BPM and \
		   speed_change is HBBPMChange and \
		   speed_change.usage == HBBPMChange.USAGE_TYPES.AUTO_BPM:
			var speed_factor = lerp(last_speed_change.speed_factor, speed_change.speed_factor, w)
			
			new_speed_change.speed_factor = speed_factor
		else:
			var bpm = lerp(start_bpm, end_bpm, w)
			
			new_speed_change.usage = HBBPMChange.USAGE_TYPES.FIXED_BPM
			new_speed_change.bpm = bpm
		
		var item = new_speed_change.get_timeline_item()
		
		undo_redo.add_do_method(self.add_item_to_layer.bind(events_layer, item))
		
		undo_redo.add_undo_method(self.deselect_item.bind(item))
		undo_redo.add_undo_method(self.remove_item_from_layer.bind(events_layer, item))
	
	undo_redo.add_do_method(self.timing_points_changed)
	undo_redo.add_undo_method(self.timing_points_changed)
	
	undo_redo.add_do_method(self.sort_items)
	undo_redo.add_undo_method(self.sort_items)
	
	undo_redo.commit_action()
