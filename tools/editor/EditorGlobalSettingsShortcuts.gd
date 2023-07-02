extends Control

class_name EditorGlobalSettingsShortcuts

@onready var bind_window: ConfirmationDialog = get_node("Window")
@onready var binding_label: Label = get_node("Window/VBoxContainer/BindingLabel")
@onready var combination_label: RichTextLabel = get_node("Window/VBoxContainer/CombinationLabel")
@onready var reset_to_default_button: Button = get_node("Window/VBoxContainer/HBoxContainer/ResetToDefaultButton")
@onready var clear_button: Button = get_node("Window/VBoxContainer/HBoxContainer/ClearButton")
@onready var reset_all_confirmation_dialog: ConfirmationDialog = get_node("ResetAllConfirmationDialog")
@onready var reset_confirmation_dialog: ConfirmationDialog = get_node("ResetConfirmationDialog")
@onready var conflict_dialog: AcceptDialog = get_node("ConflictDialog")
@onready var conflict_list: ItemList = get_node("ConflictDialog/VBoxContainer/ItemList")

@onready var tree: Tree = get_node("VBoxContainer/Tree")

@onready var add_icon = preload("res://graphics/icons/icon_add.svg")
@onready var remove_icon = preload("res://tools/icons/icon_remove.svg")
@onready var reset_icon = preload("res://graphics/icons/refresh-small.svg")

var temp_event: InputEvent
var editor: HBEditor: set = set_editor

const EDITOR_ACTIONS := {
	"Menus": [
		"editor_settings",
		"editor_show_docs",
		"editor_open_script_manager",
		"toggle_diagnostics",
		"toggle_fps",
		"show_hidden",
		"editor_popup_visibility_editor",
	],
	"Files": [
		"editor_open",
		"editor_open_scripts_dir",
		"editor_save",
		"editor_save_as",
		"editor_new_script",
	],
	"Sync": [
		"editor_resolution_4",
		"editor_resolution_6",
		"editor_resolution_8",
		"editor_resolution_12",
		"editor_resolution_16",
		"editor_resolution_24",
		"editor_resolution_32",
		"editor_timeline_snap",
		"editor_increase_resolution",
		"editor_decrease_resolution",
		"editor_toggle_sfx",
		"editor_toggle_waveform",
		"editor_tap_metronome",
		"editor_toggle_metronome",
	],
	"Notes": [
		"note_up",
		"note_down",
		"note_left",
		"note_right",
		"slide_left",
		"slide_right",
		"heart_note",
		"editor_make_normal",
		"editor_toggle_hold",
		"editor_toggle_sustain",
		"editor_toggle_double",
		"editor_change_note_up",
		"editor_change_note_down",
	],
	"Placements": [
		"editor_grid",
		"editor_grid_snap",
		"editor_show_arrange_menu",
		"editor_arrange_l",
		"editor_arrange_r",
		"editor_arrange_u",
		"editor_arrange_d",
		"editor_arrange_ul",
		"editor_arrange_ur",
		"editor_arrange_dl",
		"editor_arrange_dr",
		"editor_arrange_center",
		"editor_fine_position_left",
		"editor_fine_position_right",
		"editor_fine_position_up",
		"editor_fine_position_down",
		"editor_move_left",
		"editor_move_right",
		"editor_move_up",
		"editor_move_down",
		"editor_rotate_center",
		"editor_rotate_left",
		"editor_rotate_right",
		"editor_rotate_screen_center",
	],
	"Angles": [
		"editor_flip_angle",
		"editor_flip_oscillation",
		"editor_interpolate_angle",
		"editor_interpolate_distance",
		"editor_flip_oscillation",
		"editor_move_angles_closer",
		"editor_move_angles_away",
		"editor_move_angles_closer_back",
		"editor_move_angles_away_back",
		"editor_angle_r",
		"editor_angle_dr",
		"editor_angle_d",
		"editor_angle_dl",
		"editor_angle_l",
		"editor_angle_ul",
		"editor_angle_u",
		"editor_angle_ur",
	],
	"Transforms": [
		"editor_mirror_h",
		"editor_mirror_v",
		"editor_flip_h",
		"editor_flip_v",
		"editor_make_circle_cw",
		"editor_make_circle_ccw",
		"editor_make_circle_cw_inside",
		"editor_make_circle_ccw_inside",
		"editor_circle_size_bigger",
		"editor_circle_size_smaller",
	],
	"Presets and Templates": [
		"editor_vertical_multi_left",
		"editor_vertical_multi_right",
		"editor_vertical_multi_straight",
		"editor_horizontal_multi_top",
		"editor_horizontal_multi_bottom",
		"editor_horizontal_multi_diagonal",
		"editor_quad",
		"editor_inner_quad",
		"editor_sideways_quad",
		"editor_triangle",
		"editor_triangle_inverted",
		"editor_create_template",
		"editor_refresh_templates",
		"editor_open_templates_dir",
	],
	"Events": [
		"editor_create_timing_change",
		"editor_create_speed_change",
		"editor_smooth_bpm",
		"editor_create_intro_skip",
		"editor_create_section",
		"editor_quick_lyric",
		"editor_quick_phrase_start",
		"editor_quick_phrase_end",
	],
	"Preview": [
		"editor_play",
		"editor_playtest",
		"editor_playtest_at_time",
		"editor_toggle_bg",
		"editor_toggle_video",
	],
	"Selection": [
#		"editor_select",
		"editor_select_all",
		"editor_deselect",
		"editor_shift_selection_left",
		"editor_shift_selection_right",
		"editor_select_2nd",
		"editor_select_3rd",
		"editor_select_4th",
		"editor_select_only_notes",
		"editor_select_only_double_notes",
		"editor_select_only_sustains",
		"editor_select_only_sections",
		"editor_select_only_tempo_changes",
		"editor_select_only_speed_changes",
		"editor_cut",
		"editor_copy",
		"editor_paste",
		"editor_delete",
	],
	"Miscellaneous": [
#		"editor_contextual_menu",
		"gui_accept",
		"gui_cancel",
		"gui_undo",
		"gui_redo",
		"editor_pan",
		"editor_move_playhead_left",
		"editor_move_playhead_right",
		"editor_scale_up",
		"editor_scale_down",
	],
}

const CONFLICT_FREE_GROUPS := [
	["slide_left", "slide_right", "heart_note"],
	["editor_contextual_menu", "editor_show_arrange_menu"],
]

var folded := {}

func _ready():
	set_process_input(false)
	
	# Set up tree
	tree.set_column_expand(0, true)
	tree.set_column_expand(1, true)
	tree.set_column_expand(2, true)
	tree.set_column_custom_minimum_width(0, 20)
	tree.set_column_custom_minimum_width(1, 1)
	tree.set_column_custom_minimum_width(2, 1)
	
	tree.connect("item_activated", Callable(self, "_on_item_double_clicked"))
	tree.connect("button_clicked", Callable(self, "_on_button_pressed"))
	tree.connect("item_collapsed", Callable(self, "_on_item_collapsed"))
	
	for category in EDITOR_ACTIONS:
		folded[category] = true
	
	bind_window.connect("confirmed", Callable(self, "_on_bind_window_confirmed"))
	bind_window.get_cancel_button().connect("pressed", Callable(self, "set_process_input").bind(false))
	
	reset_confirmation_dialog.connect("confirmed", Callable(self, "_reset_impl"))
	reset_all_confirmation_dialog.connect("confirmed", Callable(self, "reset_all_to_default"))
	
	conflict_dialog.get_ok_button().text = "Cancel"
	conflict_dialog.add_button("Clear Other Shortcuts", false, "clear_conflicts")
	conflict_dialog.add_button("Add Anyways", false, "force")
	
	conflict_dialog.connect("confirmed", Callable(self, "_cancel_conflict_resolution"))
	conflict_dialog.connect("custom_action", Callable(self, "_on_conflict_resolution_selected"))
	
	populate()

func get_action_text(action) -> String:
	if action in UserSettings.action_names:
		return UserSettings.action_names[action]
	
	var text = "New Action"
	print("Found unlabeled action: " + action)
	
	if action.begins_with("editor_"):
		text = action.substr(7).capitalize().to_lower()
		text[0] = (text[0] as String).to_upper()
	
	return text

func get_mapping_conflicts(event: InputEvent, og_event: InputEvent, og_action: String, first_only: bool) -> bool:
	mapping_conflicts.clear()
	
	var conflict_free_actions := []
	for group in CONFLICT_FREE_GROUPS:
		if og_action in group:
			for action in group:
				if not action == og_action and not action in conflict_free_actions:
					conflict_free_actions.append(action)
	
	for category in EDITOR_ACTIONS:
		for action_name in EDITOR_ACTIONS[category]:
			var event_list = InputMap.action_get_events(action_name)
			
			for ev in event_list:
				if ev.is_match(event, true) and \
				   HBUtils.get_event_text(ev) != "None" and \
				   not (og_event.is_match(event) and action_name == og_action) and \
				   not action_name in conflict_free_actions:
					mapping_conflicts.append({"action_name": action_name, "event": ev})
					
					if first_only:
						return true
	
	return mapping_conflicts.size() != 0

func populate():
	tree.clear()
	
	var root_item = tree.create_item()
	
	for category in EDITOR_ACTIONS:
		var category_item = tree.create_item(root_item)
		category_item.set_text(0, category)
		category_item.collapsed = folded[category]
		
		for action_name in EDITOR_ACTIONS[category]:
			var action_item := tree.create_item(category_item)
			action_item.disable_folding = true
			
			action_item.set_text(0, get_action_text(action_name))
			
			action_item.add_button(1, add_icon, -1, false, "Add Shortcut")
			action_item.add_button(2, reset_icon, -1, false, "Reset To Default")
			
			action_item.set_meta("matches_event", false)
			action_item.set_meta("action_name", action_name)
			
			var event_list = InputMap.action_get_events(action_name)
			for event in event_list:
				if not event is InputEventWithModifiers:
					continue
				
				var event_text := HBUtils.get_event_text(event)
				if event_text == "None":
					continue
				
				var conflict = get_mapping_conflicts(event, event, action_name, true)
				if conflict:
					event_text += " (Conflicting)"
				
				var item := tree.create_item(action_item)
				item.set_text(0, event_text)
				
				item.add_button(2, remove_icon, -1, false, "Delete Shortcut")
				
				item.set_meta("matches_event", true)
				item.set_meta("event", event)
				item.set_meta("event_text", event_text)
				item.set_meta("action_name", action_name)

func _on_item_double_clicked():
	if tree.get_selected_column() == 0 or tree.get_selected_column() == 1:
		selected_item = tree.get_selected()
		if not selected_item.get_meta("matches_event", false):
			return
		
		popup_binding_window(selected_item)

func _on_button_pressed(item: TreeItem, column: int, id: int, mouse_button: int):
	if item.get_meta("matches_event"):
		match column:
			2:
				erase_shortcut(item)
	else:
		match column:
			1:
				selected_item = item
				popup_binding_window(item)
			2:
				popup_reset_window(item)

func _on_item_collapsed(item: TreeItem):
	var category = item.get_text(0)
	
	folded[category] = item.collapsed

var selected_item: TreeItem
func popup_binding_window(item: TreeItem):
	bind_window.popup_centered()
	set_process_input(true)
	
	selected_item = item
	
	var action_name = item.get_meta("action_name")
	var action_text = get_action_text(action_name)
	
	var split = binding_label.text.split("\n")
	binding_label.text = split[0] + '\n"' + action_text + '"'
	
	if item.get_meta("matches_event", false):
		var event = item.get_meta("event")
		set_temp_event(event)
	else:
		set_temp_event(InputEventKey.new())

var mapping_conflicts := []
func _on_bind_window_confirmed():
	set_process_input(false)
	
	if mapping_conflicts:
		conflict_list.clear()
		
		for conflict in mapping_conflicts:
			var action_text = get_action_text(conflict.action_name)
			conflict_list.add_item(action_text)
		
		conflict_dialog.popup_centered()
		return
	
	if temp_event and selected_item:
		var action_name: String = selected_item.get_meta("action_name")
		
		if selected_item.get_meta("matches_event", false):
			var event: InputEvent = selected_item.get_meta("event")
			
			InputMap.action_erase_event(action_name, event)
		
		InputMap.action_add_event(action_name, temp_event)
		
		UserSettings.save_user_settings()
		editor.update_shortcuts()
	
	populate()

func _force_mapping():
	conflict_dialog.hide()
	
	mapping_conflicts.clear()
	_on_bind_window_confirmed()

func _clear_conflicts():
	conflict_dialog.hide()
	
	for conflict in mapping_conflicts:
		InputMap.action_erase_event(conflict.action_name, conflict.event)
	
	mapping_conflicts.clear()
	_on_bind_window_confirmed()

func _cancel_conflict_resolution():
	conflict_dialog.hide()
	
	popup_binding_window(selected_item)

func _on_conflict_resolution_selected(action: String):
	if action == "clear_conflicts":
		_clear_conflicts()
	elif action == "force":
		_force_mapping()
	else:
		print("ERROR: Invalid conflict resolution action: " + action)

func set_temp_event(event: InputEvent):
	temp_event = event
	
	var og_event = selected_item.get_meta("event") if selected_item.get_meta("matches_event", false) else InputEventKey.new()
	var conflict := get_mapping_conflicts(temp_event, og_event, selected_item.get_meta("action_name"), false)
	
	var text = "[center]"
	if conflict:
		text += "[color=#EE6B7E]"
	
	text += HBUtils.get_event_text(temp_event)
	
	if conflict:
		text += "[/color]"
	text += "[/center]"
	
	combination_label.text = text

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			get_viewport().set_input_as_handled()
			set_temp_event(event)
	elif event is InputEventMouseButton:
		# I wanna KMS
		if event.is_pressed() \
		   and not bind_window.get_ok_button().get_global_rect().has_point(get_global_mouse_position()) \
		   and not bind_window.get_cancel_button().get_global_rect().has_point(get_global_mouse_position()):
			set_temp_event(event)

func erase_shortcut(item: TreeItem):
	if not item.get_meta("matches_event", false):
		return
	
	var action_name = item.get_meta("action_name")
	var event = item.get_meta("event")
	
	InputMap.action_erase_event(action_name, event)
	
	UserSettings.save_user_settings()
	editor.update_shortcuts()
	
	populate()

func popup_reset_window(item: TreeItem):
	if item.get_meta("matches_event", false):
		return
	
	reset_action_name = item.get_meta("action_name")
	
	reset_confirmation_dialog.popup_centered()

var reset_action_name: String
func _reset_impl():
	reset_action(reset_action_name)
	
	UserSettings.save_user_settings()
	editor.update_shortcuts()
	
	populate()

func reset_action(action_name: String):
	var event_list = InputMap.action_get_events(action_name)
	
	for event in event_list:
		if not event is InputEventWithModifiers:
			continue
		
		InputMap.action_erase_event(action_name, event)
	
	if not UserSettings.base_input_map.has(action_name):
		return
	
	var default_event_list = UserSettings.base_input_map[action_name]
	for event in default_event_list:
		if not event is InputEventWithModifiers:
			continue
		
		InputMap.action_add_event(action_name, event)

func reset_all_to_default():
	for section in EDITOR_ACTIONS:
		for action_name in EDITOR_ACTIONS[section]:
			reset_action(action_name)
	
	UserSettings.save_user_settings()
	editor.update_shortcuts()
	
	populate()

func set_editor(_editor: HBEditor):
	editor = _editor
	
	if not UserSettings.user_settings.editor_migrated_shortcuts:
		reset_all_to_default()
		
		UserSettings.user_settings.editor_migrated_shortcuts = true
