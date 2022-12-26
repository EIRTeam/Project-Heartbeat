extends Control

class_name EditorGlobalSettingsShortcuts

onready var combination_label: Label = get_node("WindowDialog/VBoxContainer/Label2")
onready var bind_window: ConfirmationDialog = get_node("WindowDialog")
onready var reset_to_default_button: Button = get_node("WindowDialog/VBoxContainer/HBoxContainer/ResetToDefaultButton")
onready var clear_button: Button = get_node("WindowDialog/VBoxContainer/HBoxContainer/ClearButton")
onready var reset_confirmation_dialog: ConfirmationDialog = get_node("ResetConfirmationDialog")

onready var tree: Tree = get_node("VBoxContainer/Tree")

var temp_event: InputEvent
var current_item: TreeItem
var editor: HBEditor setget set_editor

const EDITOR_EVENTS = {
	"General": [
		"editor_move_playhead_left",
		"editor_move_playhead_right",
		"gui_undo",
		"gui_redo",
	],
	"Preview": [
		"editor_play",
		"editor_playtest",
		"editor_playtest_at_time",
		"editor_toggle_metronome",
		"editor_toggle_bg",
		"editor_toggle_video",
	],
	"Selection": [
		"editor_select_all",
		"editor_deselect",
		"editor_cut",
		"editor_copy",
		"editor_paste",
		"editor_delete",
	],
	"Notes": [
		"editor_toggle_hold",
		"editor_toggle_sustain",
		"editor_toggle_double",
		"editor_change_note_up",
		"editor_change_note_down",
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
		"editor_toggle_waveform"
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
	"Presets": [
		"editor_vertical_multi_left",
		"editor_vertical_multi_right",
		"editor_horizontal_multi_top",
		"editor_horizontal_multi_bottom",
		"editor_quad",
		"editor_inner_quad",
		"editor_sideways_quad",
		"editor_triangle",
		"editor_triangle_inverted",
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
	]
}

var tree_items = {}

func _ready():
	set_process_input(false)
	var root_item = tree.create_item()
	
	for category in EDITOR_EVENTS:
		var category_item = tree.create_item(root_item)
		category_item.set_text(0, category)
		
		for event_name in EDITOR_EVENTS[category]:
			var item := tree.create_item(category_item)
			
			var action_list = InputMap.get_action_list(event_name)
			var event = action_list[0] if action_list else InputEventKey.new()
			
			item.set_meta("event", event)
			item.set_meta("action_name", event_name)
			set_item_text(item, event_name, event)
			tree_items[event_name] = item
	
	tree.connect("item_activated", self, "_on_item_double_clicked")
	bind_window.connect("confirmed", self, "_on_bind_window_confirmed")
	bind_window.get_cancel().connect("pressed", self, "set_process_input", [false])
	reset_to_default_button.connect("pressed", self, "_on_reset_to_default_button_pressed")
	clear_button.connect("pressed", self, "_on_clear_button_pressed")
	reset_confirmation_dialog.connect("confirmed", self, "reset_all_to_default")

func _on_reset_to_default_button_pressed():
	var event_list = UserSettings.base_input_map[current_item.get_meta("action_name")]
	var ev = event_list[0] if event_list else InputEventKey.new()
	set_temp_event(ev)

func _on_clear_button_pressed():
	var ev = InputEventKey.new()
	set_temp_event(ev)

func _on_bind_window_confirmed():
	set_process_input(false)
	if temp_event:
		var item = tree.get_selected() as TreeItem
		var action_name: String = item.get_meta("action_name")
		var event: InputEvent = item.get_meta("event")
		item.set_meta("event", temp_event)
		set_item_text(item, action_name, temp_event)
		
		InputMap.action_erase_event(action_name, event)
		InputMap.action_add_event(action_name, temp_event)
		
		UserSettings.save_user_settings()
		editor.update_modules()

func set_item_text(item: TreeItem, action: String, event: InputEvent):
	var ev_text = get_event_text(event)
	
	if action in UserSettings.action_names:
		item.set_text(0, UserSettings.action_names[action])
	elif action.begins_with("editor_"):
		var base = action.substr(7).capitalize().to_lower()
		base[0] = (base[0] as String).to_upper()
		item.set_text(0, base)
	item.set_text(1, ev_text)
	
func _on_item_double_clicked():
	if tree.get_selected_column() == 1:
		current_item = tree.get_selected()
		bind_window.popup_centered()
		set_process_input(true)
		
		var action_list = InputMap.get_action_list(current_item.get_meta("action_name"))
		var ev = action_list[0] if action_list else InputEvent.new()
		combination_label.text = get_event_text(ev)
		
func set_temp_event(event: InputEvent):
	temp_event = event
	combination_label.text = get_event_text(event)

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			get_tree().set_input_as_handled()
			set_temp_event(event)
	elif event is InputEventMouseButton:
		# I wanna KMS
		if 	event.is_pressed() \
			and not clear_button.get_global_rect().has_point(get_global_mouse_position()) \
			and not reset_to_default_button.get_global_rect().has_point(get_global_mouse_position()) \
			and not bind_window.get_close_button().get_global_rect().has_point(get_global_mouse_position()) \
			and not bind_window.get_ok().get_global_rect().has_point(get_global_mouse_position()) \
			and not bind_window.get_cancel().get_global_rect().has_point(get_global_mouse_position()):
			set_temp_event(event)

func reset_all_to_default():
	for section in EDITOR_EVENTS:
		for action_name in EDITOR_EVENTS[section]:
			var item: TreeItem = tree_items[action_name]
			InputMap.action_erase_event(action_name, item.get_meta("event"))
			
			if not UserSettings.base_input_map.has(action_name):
				continue
			
			var event_list = UserSettings.base_input_map[action_name]
			var event = event_list[0] if event_list else InputEvent.new()
			
			InputMap.action_add_event(action_name, event)
			set_item_text(item, action_name, event)
	
	UserSettings.save_user_settings()
	editor.update_modules()

func get_event_text(event: InputEvent):
	var text = "None"
	
	if event is InputEventKey:
		text = event.as_text() if not "Physical" in event.as_text() else "None"
		if "Kp " in text:
			text = text.replace("Kp ", "Keypad ")
	elif event is InputEventMouseButton:
		text = "Mouse %d" % event.button_index
	
	return text

func set_editor(_editor: HBEditor):
	editor = _editor
