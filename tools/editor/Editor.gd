extends Control

class_name HBEditor

signal scale_changed(prev_scale, scale)
signal playhead_position_changed
signal timing_information_changed
signal timing_points_changed
signal song_editor_settings_changed
signal modules_update_settings(settings)
signal modules_update_user_settings
signal paused

const EDITOR_LAYER_SCENE = preload("res://tools/editor/EditorLayer.tscn")
const EDITOR_TIMELINE_ITEM_SCENE = preload("res://tools/editor/timeline_items/EditorTimelineItemSingleNote.tscn")
const EDITOR_PLUGINS_DIR = "res://tools/editor/editor_plugins"
const EDITOR_MODULES_DIR = "res://tools/editor/editor_modules"

onready var save_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/SaveButton")
onready var save_as_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/SaveAsButton")
onready var timeline = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/EditorTimeline")
onready var rhythm_game = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/RhythmGame")
onready var game_preview = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview")
onready var grid_renderer = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/GridRenderer")
onready var inspector = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Control2/TabContainer/Inspector")
onready var current_title_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/CurrentTitleButton")
onready var open_chart_popup_dialog = get_node("Popups/OpenChartPopupDialog")
onready var rhythm_game_playtest_popup = preload("res://tools/editor/EditorRhythmGamePopup.tscn").instance()
onready var play_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/PlayButton")
onready var pause_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/PauseButton")
onready var editor_help_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/EditorHelpButton")
onready var game_playback = EditorPlayback.new(rhythm_game)
onready var message_shower = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/MessageShower")
onready var first_time_message_dialog := get_node("Popups/FirstTimeMessageDialog")
onready var info_label = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/HBoxContainer/InfoLabel")
onready var waveform_button = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/WaveformButton")
onready var timeline_snap_button = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/TimelineGridSnapButton")
onready var show_bg_button = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/ShowBGButton")
onready var show_video_button = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/ShowVideoButton")
onready var grid_snap_button = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/GridSnapButton")
onready var show_grid_button = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/ShowGridbutton")
onready var grid_x_spinbox = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/SpinBox")
onready var grid_y_spinbox = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/SpinBox2")
onready var sex_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/SexButton")
onready var toolbox_tab_container = get_node("VBoxContainer/VSplitContainer/HSplitContainer/Control/TabContainer2")
onready var playback_speed_label = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/PlaybackSpeedLabel")
onready var playback_speed_slider = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/PlaybackSpeedSlider")
onready var settings_editor = get_node("%EditorGlobalSettings")
onready var song_settings_editor = get_node("%EditorGlobalSettings").song_settings_tab
onready var botton_panel_vbox_container = get_node("VBoxContainer/VSplitContainer")
onready var left_panel_vbox_container = get_node("VBoxContainer/VSplitContainer/HSplitContainer")
onready var right_panel_vbox_container = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer")
onready var right_panel = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Control2/TabContainer")
onready var contextual_menu = get_node("%ContextualMenu")
onready var save_confirmation_dialog = get_node("%SaveConfirmationDialog")
onready var no_timing_map_dialog = get_node("%NoTimingMapDialog")

const LOG_NAME = "HBEditor"

var playhead_position := 0
var scale = 1.5 # Seconds per 500 pixels
var selected: Array = []
var copied_points: Array = []

var current_song: HBSong
var current_difficulty: String
var snap_to_grid_enabled = true

var timeline_snap_enabled = true
	
var undo_redo = UndoRedo.new()

var song_editor_settings: HBPerSongEditorSettings = HBPerSongEditorSettings.new()
	
var plugins := []

onready var fine_position_timer = Timer.new()

var current_notes := []

var _removed_items := [] # So we can queue_free removed nodes when freeing the editor

var playtesting := false

var _playhead_traveling := false

var hold_ends := []

var timing_point_creation_queue := []

var ui_module_locations = {
	"left_panel": "VBoxContainer/VSplitContainer/HSplitContainer/Control/TabContainer2",
	"right_panel": "VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Control2/TabContainer",
}

var modules := []
var sync_module

var timing_changes := []
var timing_map := []
var normalized_timing_map := []
var signature_map := []
var metronome_map := []

var seek_debounce_timer = Timer.new()

var hidden: bool = false

var modified: bool = false

func _sort_current_items_impl(a, b):
	return a.data.time < b.data.time

func sort_current_items():
	current_notes.sort_custom(self, "_sort_current_items_impl")

func _insert_note_at_time_bsearch(item: EditorTimelineItem, time: int):
	return item.data.time < time

func insert_note_at_time(item: EditorTimelineItem):
	var pos = current_notes.bsearch_custom(item.data.time, self, "_insert_note_at_time_bsearch")
	current_notes.insert(pos, item)

func load_plugins():
	var dir := Directory.new()
	var file = File.new()
	if dir.open(EDITOR_PLUGINS_DIR) == OK:
		dir.list_dir_begin()
		var dir_name = dir.get_next()
		while dir_name != "":
			if dir.current_is_dir() and not dir_name.begins_with("."):
				var plugin_script_path = EDITOR_PLUGINS_DIR + "/%s/%s.gd" % [dir_name, dir_name]
				if not dir.file_exists(plugin_script_path):
					plugin_script_path = EDITOR_PLUGINS_DIR + "/%s/%s.gdc" % [dir_name, dir_name]
				if file.file_exists(plugin_script_path):
					var plugin = load(plugin_script_path).new(self)
					plugins.append(plugin)
					add_child(plugin)
				else:
					Log.log(self, "Error loading editor plugin %s: File not found" % [dir_name])
			dir_name = dir.get_next()

func _sort_modules(a, b):
	return a.priority < b.priority

func load_modules():
	var dir := Directory.new()
	if dir.open(EDITOR_MODULES_DIR) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and not file_name.begins_with(".") and file_name.ends_with(".tscn"):
				var module = load(EDITOR_MODULES_DIR + "/" + file_name).instance()
				modules.append(module)
			
			file_name = dir.get_next()
	
	modules.sort_custom(self, "_sort_modules")
	for module in modules:
		module.set_editor(self)

func update_modules():
	for module in modules:
		module.update_shortcuts()

func update_shortcuts():
	for button in get_tree().get_nodes_in_group("update_shortcuts"):
		button.update_shortcuts()

func _ready():
	UserSettings.enable_menu_fps_limits = false
	add_child(game_playback)
	game_playback.connect("playback_speed_changed", self, "_on_playback_speed_changed")
	game_playback.connect("time_changed", self, "_on_game_playback_time_changed")
	Input.set_use_accumulated_input(true)
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	OS.window_borderless = false
	OS.window_fullscreen = false
	OS.window_maximized = true
	timeline.editor = self
	timeline.set_layers_offset(0)
	add_child(fine_position_timer)
	fine_position_timer.wait_time = 0.5
	fine_position_timer.connect("timeout", self, "apply_fine_position")
	rhythm_game.set_process_unhandled_input(false)
	rhythm_game.game_mode = HBRhythmGameBase.GAME_MODE.EDITOR_SEEK
	
	inspector.connect("properties_changed", self, "_change_selected_properties")
	inspector.connect("property_change_committed", self, "_commit_selected_property_change")
	inspector.connect("reset_pos", self, "reset_note_position")
	
	load_plugins()
	
	# You HAVE to open a chart, this ensures that if no chart is selected we return
	# to the main menu
	open_chart_popup_dialog.get_cancel().connect("pressed", self, "exit")
	open_chart_popup_dialog.get_close_button().connect("pressed", self, "exit")
	open_chart_popup_dialog.connect("chart_selected", self, "load_song")
	
	rhythm_game_playtest_popup.connect("quit", self, "_on_playtest_quit")
	editor_help_button.get_popup().connect("index_pressed", self, "_on_editor_help_button_pressed")
	
	inspector.connect("notes_pasted", self, "paste_note_data")
	
	MouseTrap.disable_mouse_trap()
	
	if not UserSettings.user_settings.editor_first_time_message_acknowledged:
		first_time_message_dialog.popup_centered()
	else:
		_show_open_chart_dialog()
	first_time_message_dialog.get_ok().text = "Got it!"
	first_time_message_dialog.get_ok().connect("pressed", self, "_on_acknowledge_first_time_message")
	
	connect("timing_points_changed", self, "_cache_hold_ends")
	
	settings_editor.song_settings_tab.set_editor(self)
	settings_editor.general_settings_tab.set_editor(self)
	settings_editor.shortcuts_tab.set_editor(self)
	
	UserSettings.user_settings.connect("editor_grid_resolution_changed", self, "_update_grid_resolution")
	
	connect("scale_changed", timeline, "_on_editor_scale_changed")
	
	game_preview.connect("preview_size_changed", self, "_on_preview_size_changed")
	
	load_modules()
	
	botton_panel_vbox_container.split_offset = UserSettings.user_settings.editor_bottom_panel_offset
	left_panel_vbox_container.split_offset = UserSettings.user_settings.editor_left_panel_offset
	right_panel_vbox_container.split_offset = UserSettings.user_settings.editor_right_panel_offset
	
	add_child(seek_debounce_timer)
	seek_debounce_timer.wait_time = UserSettings.user_settings.editor_scroll_timeout
	seek_debounce_timer.one_shot = true
	seek_debounce_timer.connect("timeout", self, "_seek")
	
	update_user_settings()
	
	Diagnostics.fps_label.get_font("font").size = 11
	
	undo_redo.connect("version_changed", self, "_on_version_changed")
	
	save_confirmation_dialog.get_ok().text = "Yes"
	save_confirmation_dialog.get_cancel().text = "Go back"

const HELP_URLS = [
	"https://steamcommunity.com/sharedfiles/filedetails/?id=2048893718",
	"https://steamcommunity.com/sharedfiles/filedetails/?id=2465841098"
]
	
func _on_acknowledge_first_time_message():
	UserSettings.user_settings.editor_first_time_message_acknowledged = true
	UserSettings.save_user_settings()
	_show_open_chart_dialog()
	
func _on_editor_help_button_pressed(button_idx: int):
	OS.shell_open(HELP_URLS[button_idx])


func get_items_at_time_or_selected(time: int):
	if selected.size() > 0:
		return selected
	else:
		return get_items_at_time(time)

# transform_values is a dict mapping between note_type and transform properties
func _show_transform_on_current_notes(transformation):
	var notes = get_items_at_time_or_selected(playhead_position)
	if notes.size() == 0:
		return
	
	var base_transform_notes = []
	for timeline_item in notes:
		if timeline_item is EditorTimelineItemNote:
			var note = timeline_item.data
			base_transform_notes.append(note)
	
	game_preview.transform_preview.transformation = transformation
	game_preview.transform_preview.notes_to_transform = base_transform_notes
	game_preview.transform_preview.update()
	game_preview.transform_preview.show()

func _apply_transform_on_current_notes(transformation: EditorTransformation):
	var current_items = get_items_at_time_or_selected(playhead_position)
	var base_transform_notes = []
	for timeline_item in current_items:
		if timeline_item is EditorTimelineItemNote:
			var note = timeline_item.data
			base_transform_notes.append(note)
	
	var transformation_result = transformation.transform_notes(base_transform_notes)
	
	var notes_to_apply_found = false

	for item in current_notes:
		if item is EditorTimelineItemNote:
			if item.data in transformation_result:
				notes_to_apply_found = true
				break
	
	if notes_to_apply_found:
		undo_redo.create_action("Apply transformation")
		
		# Some transforms might change the note type and thus the layer
		var type_to_layer_name_map = {}
		for type_name in HBNoteData.NOTE_TYPE:
			type_to_layer_name_map[HBNoteData.NOTE_TYPE[type_name]] = type_name
		type_to_layer_name_map[HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT] = "SLIDE_LEFT"
		type_to_layer_name_map[HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT] = "SLIDE_RIGHT"
		
		for item in current_notes:
			var note = item.data
			if note in transformation_result:
				for property_name in transformation_result[note]:
					if property_name in item.data:
						undo_redo.add_do_property(item.data, property_name, transformation_result[item.data][property_name])
						undo_redo.add_do_method(item.data, "emit_signal", "parameter_changed", property_name)
						undo_redo.add_undo_property(item.data, property_name, item.data.get(property_name))
						undo_redo.add_undo_method(item.data, "emit_signal", "parameter_changed", property_name)
						if property_name == "note_type":
							# When note type is changed we also change the layer
							var new_note_type = transformation_result[note].note_type
							if type_to_layer_name_map[new_note_type] != item._layer.layer_name and \
									type_to_layer_name_map[new_note_type] + "2" != item._layer.layer_name:
								var source_layer = item._layer
								var target_layer_name = type_to_layer_name_map[new_note_type]
								if source_layer.layer_name.ends_with("2"):
									target_layer_name += "2"
								
								note.set_meta("second_layer", target_layer_name.ends_with("2"))
								
								var target_layer = timeline.find_layer_by_name(target_layer_name)
								undo_redo.add_do_method(self, "remove_item_from_layer", source_layer, item)
								undo_redo.add_do_method(self, "add_item_to_layer", target_layer, item)
								
								undo_redo.add_undo_method(self, "remove_item_from_layer", target_layer, item)
								undo_redo.add_undo_method(self, "add_item_to_layer", source_layer, item)
						if property_name == "position":
							undo_redo.add_do_property(item.data, "pos_modified", true)
							undo_redo.add_undo_property(item.data, "pos_modified", item.data.pos_modified)

		undo_redo.add_do_method(self, "force_game_process")
		undo_redo.add_undo_method(self, "force_game_process")
			
			undo_redo.add_do_method(item, "update_widget_data")
			undo_redo.add_undo_method(item, "update_widget_data")
		
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_method(self, "_on_timing_points_changed")

		undo_redo.commit_action()

func _show_open_chart_dialog():
	open_chart_popup_dialog.popup_centered_minsize(Vector2(600, 250))
	
func change_scale(new_scale):
	if new_scale < scale and scale < 1.0:
		return
	var prev_scale = scale
	scale = new_scale
	scale = max(new_scale, 0.1)
	emit_signal("scale_changed", prev_scale, new_scale)

func get_items_at_time(time: int):
	var items = []
	for item in current_notes:
		if item.data.time == time:
			items.append(item)
		elif item.data.time > time:
			break
	return items

# From cppreference
func _upper_bound(array: Array, value: int) -> int:
	var count = array.size() - 1
	var idx = 0
	
	while count > 0:
		var step = count / 2
		
		if value >= array[idx + step]:
			idx += step + 1
			count -= step + 1
		else:
			count = step
	
	return idx

func _closest_bound(array: Array, value: int) -> int:
	var idx := array.bsearch(value)
	
	if idx == 0 or idx == array.size() or abs(array[idx] - value) < abs(array[idx - 1] - value):
		return idx
	else:
		return idx - 1

func _linear_bound(array: Array, value: int) -> float:
	var idx := array.bsearch(value)
	
	if idx + 1 == array.size() or array[idx] == value or array[idx] == array[idx + 1]:
		return float(idx)
	
	var decimal = float(value - array[idx]) / float(array[idx + 1] - array[idx])
	return idx + decimal

var konami_sequence = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]
var konami_index = 0

func _unhandled_input(event: InputEvent):
	if rhythm_game_playtest_popup in get_children():
		return
	
	if shortcuts_blocked():
		return
	
	if event is InputEventKey and event.pressed and not sex_button.visible:
		if event.scancode == konami_sequence[konami_index]:
			konami_index += 1
			
			if konami_index == konami_sequence.size():
				sex_button.show()
		else:
			konami_index = 0
	
	if event.is_action("editor_fine_position_left", true) or \
		event.is_action("editor_fine_position_right", true) or \
		event.is_action("editor_fine_position_up", true) or \
		event.is_action("editor_fine_position_down", true):
		if event.pressed:
			var diff_x = event.get_action_strength("editor_fine_position_right") - event.get_action_strength("editor_fine_position_left")
			var diff_y = event.get_action_strength("editor_fine_position_down") - event.get_action_strength("editor_fine_position_up")
			var off = Vector2(int(diff_x), int(diff_y))
			fine_position_selected(off)
			get_tree().set_input_as_handled()
	
	if event.is_action("editor_move_left", true) or \
		event.is_action("editor_move_right", true) or \
		event.is_action("editor_move_up", true) or \
		event.is_action("editor_move_down", true):
		if event.pressed and not event.echo:
			var diff_x = event.get_action_strength("editor_move_right") - event.get_action_strength("editor_move_left")
			var diff_y = event.get_action_strength("editor_move_down") - event.get_action_strength("editor_move_up")
			
			var grid_size = grid_renderer.get_grid_size()
			var off = Vector2(int(diff_x * grid_size.y), int(diff_y * grid_size.x))
			
			fine_position_selected(off)
			get_tree().set_input_as_handled()
	
	if event.is_action("editor_toggle_hold", true) and event.pressed and not event.echo:
		undo_redo.create_action("Toggle hold")
		
		for note in selected:
			if note.data is HBNoteData:
				undo_redo.add_do_property(note.data, "hold", not note.data.hold)
				undo_redo.add_undo_property(note.data, "hold", note.data.hold)
		
		undo_redo.add_do_method(inspector, "sync_visible_values_with_data")
		undo_redo.add_undo_method(inspector, "sync_visible_values_with_data")
		
		undo_redo.add_do_method(self, "_cache_hold_ends")
		undo_redo.add_undo_method(self, "_cache_hold_ends")
		
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_method(self, "_on_timing_points_changed")
		
		undo_redo.commit_action()
	
	if event.is_action("gui_undo", true) and event.pressed:
		get_tree().set_input_as_handled()
		apply_fine_position()
		if undo_redo.has_undo():
			if undo_redo.get_current_action_name() == "MERGE":
				# A merge action should always have an extra action before it
				undo_redo.undo()
			
			message_shower._show_notification("Undo " + undo_redo.get_current_action_name().to_lower())
			undo_redo.undo()
	
	if event.is_action("gui_redo", true) and event.pressed:
		get_tree().set_input_as_handled()
		apply_fine_position()
		if undo_redo.has_redo():
			undo_redo.redo()
			message_shower._show_notification("Redo " + undo_redo.get_current_action_name().to_lower())
			
			if undo_redo.has_redo():
				undo_redo.redo()
				if undo_redo.get_current_action_name() != "MERGE":
					# Next action was not a merge action
					# HACK: This seems wasteful, but since different actions can have the same version, I couldnt find a better way to do this
					undo_redo.undo()
	
	if event.is_action("editor_delete", true) and event.pressed and not event.echo:
		if selected.size() != 0:
			get_tree().set_input_as_handled()
			delete_selected()
	if event.is_action("editor_paste", true) and event.pressed and not event.echo:
		var time = timeline.get_time_being_hovered()
		paste(time)
	if event.is_action("editor_copy", true) and event.pressed and not event.echo:
		copy_selected()
	if event.is_action("editor_cut", true) and event.pressed and not event.echo:
		copy_selected()
		delete_selected()
	
	if event.is_action("editor_select_all", true) and event.pressed and not event.echo:
		select_all()
	if event.is_action("editor_deselect", true) and event.pressed and not event.echo:
		deselect_all()
	
	if not game_playback.is_playing():
		var old_pos = playhead_position
		
		if event.is_action("editor_move_playhead_left", true) and event.pressed and timing_map:
			var idx = max(get_timing_map().bsearch(playhead_position) - 1, 0)
			playhead_position = get_timing_map()[idx]
		elif event.is_action("editor_move_playhead_right", true) and event.pressed and timing_map:
			var idx = _upper_bound(get_timing_map(), playhead_position)
			playhead_position = get_timing_map()[idx]
		
		if old_pos != playhead_position:
			emit_signal("playhead_position_changed")
			timeline.ensure_playhead_is_visible()
			seek(playhead_position)
	
	if event is InputEventKey and not event.is_action_pressed("editor_play"):
		for type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
			var found_note = false
			for action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[type]:
				if (event.is_action(action, true) and event.pressed and not event.echo) or (type in [HBBaseNote.NOTE_TYPE.SLIDE_LEFT, HBBaseNote.NOTE_TYPE.SLIDE_RIGHT] and event.is_action_pressed(action)):
					var layer = null
					for layer_c in timeline.get_visible_layers():
						if layer_c.layer_name == HBUtils.find_key(HBBaseNote.NOTE_TYPE, type) + ("2" if event.shift else ""):
							layer = layer_c
							break
					
					if not layer:
						continue
					
					if selected and not game_playback.is_playing():
						undo_redo.create_action("Change selected notes button to " + HBGame.NOTE_TYPE_TO_STRING_MAP[type])
						
						for item in selected:
							var data = item.data as HBBaseNote
							if not data:
								continue
							var new_data_ser = data.serialize()
							
							new_data_ser["note_type"] = type
							
							# Fallbacks when converting illegal note types
							if type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT or type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
								new_data_ser["type"] = "Note"
							
							var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
							
							new_data.set_meta("second_layer", layer.layer_name.ends_with("2"))
							
							var new_item = new_data.get_timeline_item()
							
							undo_redo.add_do_method(self, "add_item_to_layer", layer, new_item)
							undo_redo.add_do_method(item, "deselect")
							undo_redo.add_undo_method(self, "remove_item_from_layer", layer, new_item)
							
							undo_redo.add_do_method(self, "remove_item_from_layer", item._layer, item)
							undo_redo.add_undo_method(new_item, "deselect")
							undo_redo.add_undo_method(self, "add_item_to_layer", item._layer, item)
						
						undo_redo.add_undo_method(self, "deselect_all")
						undo_redo.add_do_method(self, "deselect_all")
						undo_redo.commit_action()
					else:
						var item_erased = false
						for item in get_items_at_time(snap_time_to_timeline(playhead_position)):
							if item is EditorTimelineItemNote:
								if item.data.note_type == type and item._layer == layer:
									item_erased = true
									
									undo_redo.create_action("Remove note")
									
									undo_redo.add_do_method(self, "remove_item_from_layer", item._layer, item)
									undo_redo.add_undo_method(self, "add_item_to_layer", item._layer, item)
									
									undo_redo.add_do_method(self, "_on_timing_points_changed")
									undo_redo.add_undo_method(self, "_on_timing_points_changed")
									
									undo_redo.commit_action()
									
									check_for_multi_changes([snap_time_to_timeline(playhead_position)])
						if not item_erased:
							var timing_point := HBNoteData.new()
							timing_point.time = snap_time_to_timeline(playhead_position)
							timing_point.note_type = type
							
							if not game_playback.is_playing():
								user_create_timing_point(layer, timing_point.get_timeline_item())
							else:
								queue_timing_point_creation(layer, timing_point)
							
							game_playback.game.play_note_sfx()
					
					found_note = true
					break
			if found_note:
				get_tree().set_input_as_handled()
				break
	
	if event.is_action_pressed("editor_show_docs", false, true):
		pass # Reserve


func _note_comparison(a, b):
	return a.time > b.time

func get_timing_points() -> Array:
	var points = []
	
	var layers = timeline.get_layers()
	for layer in layers:
		points += layer.get_timing_points()
	
	points.sort_custom(self, "_note_comparison")
	return points

func get_timeline_items() -> Array:
	var items = []
	var layers = timeline.get_layers()
	for layer in layers:
		items += layer.get_editor_items()
	return items

func scale_msec(msec: int) -> float:
	return ((msec/1000.0)/scale)*500.0

# pixels to msec
func scale_pixels(pixels: float) -> float:
	return (pixels * scale / 500) * 1000.0

func notify_selected_changed():
	info_label.text = "Timing points %d/%d" % [selected.size(), current_notes.size()]

func select_item(item: EditorTimelineItem, inclusive: bool = false):
	if inclusive:
		if item in selected:
			return
		
		selected.append(item)
	else:
		for selected_item in selected:
			selected_item.deselect()
		
		selected = [item]
	
	release_owned_focus()
	item.select()
	
	var widget := item.get_editor_widget()
	if widget:
		var widget_instance = widget.instance() as HBEditorWidget
		widget_instance.editor = self
		game_preview.widget_area.add_child(widget_instance)
		item.connect_widget(widget_instance)
	
	selected.sort_custom(self, "_sort_current_items_impl")
	inspector.inspect(selected)
	notify_selected_changed()
	
	var current_module = right_panel.get_current_tab_control()
	if right_panel.current_tab != 0 and not current_module.blocks_switch_to_inspector:
		right_panel.current_tab = 0

func select_all():
	if selected.size() > 0:
		deselect_all()
	
	for item in current_notes:
		if not item is EditorTimingChangeTimelineItem:
			selected.append(item)
			item.select()
	
	selected.sort_custom(self, "_sort_current_items_impl")
	right_panel.current_tab = 0
	inspector.inspect(selected)
	release_owned_focus()
	notify_selected_changed()

func add_item(layer_n: int, item: EditorTimelineItem):
	var layers = timeline.get_layers()
	var layer = layers[layer_n]
	add_item_to_layer(layer, item)

# property values for continuously updating undo_redo actions like angle changes
var old_property_values = {}

# Changes the selected property by an amount, but doesn't commit it to undo_redo, to
# prevent creating more undo_redo actions than necessary
func _change_selected_property_delta(property_name: String, new_value, making_change=null):
	for selected_item in selected:
		if property_name in selected_item.data:
			if not selected_item in old_property_values:
				old_property_values[selected_item] = {}
			
			if not property_name in old_property_values[selected_item]:
				old_property_values[selected_item][property_name] = selected_item.data.get(property_name)
			
			if property_name == "time":
				var new_time = min(selected_item.data.time + new_value, (get_song_length() * 1000.0-1))
				new_value = new_time - selected_item.data.time
			
			selected_item.data.set(property_name, selected_item.data.get(property_name) + new_value)
			selected_item.update_widget_data()
	_on_timing_points_params_changed()
	
var fine_position_originals = {}
	
func fine_position_selected(diff: Vector2):
	for selected_item in selected:
		if "position" in selected_item.data:
			if not selected_item in fine_position_originals:
				fine_position_originals[selected_item] = [selected_item.data.position, selected_item.data.pos_modified]
			selected_item.data.position += diff
			selected_item.update_widget_data()
	fine_position_timer.start()
	_on_timing_points_params_changed()
func apply_fine_position():
	fine_position_timer.stop()
	if fine_position_originals.size() > 0:
		undo_redo.create_action("Fine position notes")
		for item in fine_position_originals:
			undo_redo.add_undo_property(item.data, "position", fine_position_originals[item][0])
			undo_redo.add_undo_property(item.data, "pos_modified", fine_position_originals[item][1])
			undo_redo.add_undo_method(item, "update_widget_data")
			undo_redo.add_undo_method(item, "sync_value", "position")
			undo_redo.add_do_property(item.data, "position", item.data.position)
			undo_redo.add_do_property(item.data, "pos_modified", true)
			undo_redo.add_do_method(item, "update_widget_data")
			undo_redo.add_do_method(item, "sync_value", "position")
		fine_position_originals = {}
		
		undo_redo.commit_action()
		inspector.sync_value("position")
func show_contextual_menu():
	contextual_menu.popup()
	var popup_offset = get_global_mouse_position() + contextual_menu.rect_size - get_viewport_rect().size
	popup_offset.x = max(popup_offset.x, 0)
	popup_offset.y = max(popup_offset.y, 0)
	contextual_menu.set_global_position(get_global_mouse_position() - popup_offset)
	
# Changes the properties of the selected items, but doesn't commit it to undo_redo, to
# prevent creating more undo_redo actions than necessary, thus undoing constant 
# actions like changing a note angle requires a single control+z
func _change_selected_properties(property_name: String, new_values):
	for i in selected.size():
		_change_selected_property_single_item(selected[i], property_name, new_values[i])
	
	if property_name == "entry_angle":
		inspector.sync_visible_values_with_data()
	
	_on_timing_points_params_changed()

func _change_selected_property_single_item(item, property_name: String, new_value):
	if not item in old_property_values:
		old_property_values[item] = {}
	
	if not property_name in old_property_values[item]:
		old_property_values[item][property_name] = item.data.get(property_name)
	item.data.set(property_name, new_value)
	
	item.update_widget_data()
	item.sync_value(property_name)
	item.data.emit_signal("parameter_changed", property_name)


func _commit_selected_property_change(property_name: String, create_action: bool = true):
	var action_name = "Note " + property_name + " changed"
	
	if create_action:
		undo_redo.create_action(action_name)

	if property_name == "time":
		for selected_item in selected:
			undo_redo.add_do_method(rhythm_game, "editor_remove_timing_point", selected_item.data)
			undo_redo.add_undo_method(rhythm_game, "editor_remove_timing_point", selected_item.data)
	
	var tp_cache = get_timing_points()
	var times_cache = {}
	
	var sync_timing := false
	var multi_check_times := []
	for selected_item in selected:
		if old_property_values.has(selected_item):
			if property_name in selected_item.data and property_name in old_property_values[selected_item]:
				if property_name == "time":
					if selected_item.data is HBSustainNote:
						undo_redo.add_do_property(selected_item.data, "end_time", selected_item.data.end_time)
						undo_redo.add_undo_property(selected_item.data, "end_time", old_property_values[selected_item].end_time)
					
					if selected_item.data is HBTimingChange:
						sync_timing = true
					
					if selected_item.data is HBBaseNote and UserSettings.user_settings.editor_auto_place and not selected_item.data.pos_modified:
						var new_data = autoplace(selected_item.data, false, tp_cache, times_cache)
						
						undo_redo.add_do_property(selected_item.data, "position", new_data.position)
						undo_redo.add_undo_property(selected_item.data, "position", selected_item.data.position)
					
					if not multi_check_times.has(selected_item.data.time):
						multi_check_times.append(selected_item.data.time)
					
					if not multi_check_times.has(old_property_values[selected_item].time):
						multi_check_times.append(old_property_values[selected_item].time)
				
				if property_name == "position":
					undo_redo.add_do_property(selected_item.data, "pos_modified", true)
					undo_redo.add_undo_property(selected_item.data, "pos_modified", selected_item.data.pos_modified)
				
				undo_redo.add_do_property(selected_item.data, property_name, selected_item.data.get(property_name))
				undo_redo.add_do_method(selected_item.data, "emit_signal", "parameter_changed", property_name)
				undo_redo.add_do_method(selected_item._layer, "place_child", selected_item)
				
				undo_redo.add_undo_property(selected_item.data, property_name, old_property_values[selected_item][property_name])
				undo_redo.add_undo_method(selected_item.data, "emit_signal", "parameter_changed", property_name)
				undo_redo.add_undo_method(selected_item._layer, "place_child", selected_item)
				
				undo_redo.add_do_method(selected_item, "update_widget_data")
				undo_redo.add_do_method(selected_item, "sync_value", property_name)
				
				undo_redo.add_undo_method(selected_item, "update_widget_data")
				undo_redo.add_undo_method(selected_item, "sync_value", property_name)
			
			old_property_values[selected_item].erase(property_name)

	undo_redo.add_do_method(inspector, "sync_visible_values_with_data")
	undo_redo.add_undo_method(inspector, "sync_visible_values_with_data")
	undo_redo.add_do_method(self, "sync_lyrics")
	undo_redo.add_undo_method(self, "sync_lyrics")
	
	if property_name == "time":
		undo_redo.add_do_method(self, "sort_current_items")
		
		for selected_item in selected:
			undo_redo.add_do_method(rhythm_game, "editor_add_timing_point", selected_item.data)
			undo_redo.add_undo_method(rhythm_game, "editor_add_timing_point", selected_item.data)
		
		undo_redo.add_do_method(self, "_cache_hold_ends")
		undo_redo.add_undo_method(self, "_cache_hold_ends")
	elif property_name == "hold":
		undo_redo.add_do_method(self, "_cache_hold_ends")
		undo_redo.add_undo_method(self, "_cache_hold_ends")
	
	undo_redo.add_do_method(self, "force_game_process")
	undo_redo.add_undo_method(self, "force_game_process")
	
	if property_name == "bpm" or property_name == "time_signature" or sync_timing:
		undo_redo.add_do_method(self, "_on_timing_information_changed")
		undo_redo.add_undo_method(self, "_on_timing_information_changed")
	
	if create_action:
		undo_redo.commit_action()
		
		check_for_multi_changes(multi_check_times, times_cache)
	
	old_property_values.clear()
	inspector.sync_value(property_name)
	release_owned_focus()

# Handles when a user changes a timing point's property, this is used for properties
# that won't constantly change
func _on_timing_point_property_changed(property_name: String, old_value, new_value, child: EditorTimelineItem, affects_timing_points = false):
	var action_name = "Note " + property_name + " changed"
	undo_redo.create_action(action_name)
	
	undo_redo.add_do_property(child.data, property_name, new_value)
	undo_redo.add_do_method(child._layer, "place_child", child)
	
	undo_redo.add_undo_property(child.data, property_name, old_value)
	undo_redo.add_undo_method(child._layer, "place_child", child)
	
	if property_name == "position":
		undo_redo.add_do_method(child, "update_widget_data")
		undo_redo.add_undo_method(child, "update_widget_data")
	
	if  property_name == "bpm" or property_name == "time_signature" or \
		(property_name == "time" and child.data is HBTimingChange):
		undo_redo.add_do_method(self, "_on_timing_information_changed")
		undo_redo.add_undo_method(self, "_on_timing_information_changed")
	
	undo_redo.commit_action()
	inspector.sync_visible_values_with_data()
	
	var note = child.data
	
	if property_name == "note_type":
		var layer = child._layer
		var note_type_string = HBUtils.find_key(HBNoteData.NOTE_TYPE, note.note_type)
		# We move the note to the proper layer if we find it's not in the correct one
		if not note_type_string == layer.layer_name:
			for l in timeline.get_layers():
				if l.layer_name == note_type_string:
					l.drop_data(null, selected)
					break

func add_item_to_layer(layer: EditorLayer, item: EditorTimelineItem):
	if item.update_affects_timing_points:
		if not item.is_connected("property_changed", self, "_on_timing_point_property_changed"):
			item.connect("property_changed", self, "_on_timing_point_property_changed", [item, true])
	else:
		if not item.is_connected("property_changed", self, "_on_timing_point_property_changed"):
			item.connect("property_changed", self, "_on_timing_point_property_changed", [item])
	
	insert_note_at_time(item)
	layer.add_item(item)
	if item in _removed_items:
		_removed_items.erase(item)
	
	_on_timing_points_changed()
	rhythm_game.editor_add_timing_point(item.data)
	force_game_process()
	
func add_event_timing_point(timing_point_class: GDScript):
	var timing_point := timing_point_class.new() as HBTimingPoint
	timing_point.time = playhead_position
	# Event layer is the last one
	var ev_layer = null
	for layer in timeline.get_layers():
		if layer.layer_name == "Events":
			ev_layer = layer
			break
		
	user_create_timing_point(ev_layer, timing_point.get_timeline_item())
	
	return timing_point

func _on_game_playback_time_changed(time: float):
	var prev_time = playhead_position
	playhead_position = max(time * 1000.0, 0.0)
	timeline.update()
	if game_playback.is_playing():
		timeline.ensure_playhead_is_visible()
		var playback_offset_with_ln = (timeline.rect_size.x / 2.0)
		var current_playhead_offset = playback_offset_with_ln - timeline.calculate_playhead_position().x
		var target_offset = timeline._offset - current_playhead_offset
		emit_signal("playhead_position_changed")
		if _playhead_traveling:
			var prev_diff = timeline._offset-target_offset
			if timeline._offset < target_offset:
				var new_offset = move_toward(timeline._offset, target_offset, scale_msec(playhead_position - prev_time)*6.0)
				timeline.set_layers_offset(new_offset)
				if is_equal_approx(target_offset, new_offset) or sign(prev_diff) != sign(timeline._offset-target_offset):
					_playhead_traveling = false
		if not _playhead_traveling:
			timeline.set_layers_offset(target_offset)
		

func seek(value: int, force = false):
	if not UserSettings.user_settings.editor_smooth_scroll:
		value = snap_time_to_timeline(value)
	
	game_playback.seek(value)
	if (not game_playback.is_playing()) and (not force) and UserSettings.user_settings.editor_smooth_scroll:
		_seek_value = value
		seek_debounce_timer.wait_time = UserSettings.user_settings.editor_scroll_timeout
		seek_debounce_timer.start(0)
	elif not game_playback.is_playing():
		game_preview.set_time(_seek_value / 1000.0)
	else:
		game_preview.play_at_pos(value / 1000.0)

var _seek_value: int
func _seek():
	game_preview.set_time(_seek_value / 1000.0)

func copy_selected():
	if selected.size() > 0:
		copied_points = []
		for item in selected:
			var timing_point_timeline_item = item as EditorTimelineItem
			var cloned_item = timing_point_timeline_item.data.clone().get_timeline_item()
			cloned_item._layer = timing_point_timeline_item._layer
			copied_points.append({"item": cloned_item, "layer_name": cloned_item._layer.layer_name})

func paste(time: int):
	if copied_points.size() > 0:
		undo_redo.create_action("Paste timing points")
		message_shower._show_notification("Paste notes")
		
		var min_point = copied_points[0].item.data as HBTimingPoint
		for copy in copied_points:
			var timing_point := copy.item.data as HBTimingPoint
			if timing_point.time < min_point.time:
				min_point = timing_point
		
		var sync_timing := false
		var multi_check_times := []
		for copy in copied_points:
			for l in timeline.get_layers():
				if l.layer_name == copy.layer_name:
					copy.item._layer = l
					break
			
			var timeline_item := copy.item as EditorTimelineItem
			var timing_point := copy.item.data.clone() as HBTimingPoint
			
			timing_point.time = time + timing_point.time - min_point.time
			if timing_point is HBSustainNote:
				timing_point.end_time = timing_point.time + copy.item.data.get_duration()
			
			if timing_point is HBBaseNote and UserSettings.user_settings.editor_auto_place:
				timing_point = autoplace(timing_point)
			
			var new_item = timing_point.get_timeline_item() as EditorTimelineItem
			
			undo_redo.add_do_method(self, "add_item_to_layer", timeline_item._layer, new_item)
			undo_redo.add_undo_method(self, "remove_item_from_layer", timeline_item._layer, new_item)
			
			if copy.item is EditorSectionTimelineItem:
				sync_timing = true
			
			if not multi_check_times.has(time):
				multi_check_times.append(time)
		
		if sync_timing:
			undo_redo.add_do_method(timeline, "update")
			undo_redo.add_undo_method(timeline, "update")
		
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_method(self, "_on_timing_points_changed")
		undo_redo.add_do_method(self, "sync_lyrics")
		undo_redo.add_undo_method(self, "sync_lyrics")
		
		undo_redo.commit_action()
		check_for_multi_changes(multi_check_times)

func delete_selected():
	if selected.size() > 0:
		for item in selected:
			if item in inspector.inspecting_items:
				inspector.stop_inspecting()
				break
		
		undo_redo.create_action("Delete notes")
		
		message_shower._show_notification("Delete notes")
		
		var sync_timing := false
		var deleted_times := []
		for selected_item in selected:
			selected_item.deselect()
			
			undo_redo.add_do_method(self, "remove_item_from_layer", selected_item._layer, selected_item)
			undo_redo.add_undo_method(self, "add_item_to_layer", selected_item._layer, selected_item)
			
			if selected_item is EditorSectionTimelineItem:
				undo_redo.add_do_method(timeline, "update")
				undo_redo.add_undo_method(timeline, "update")
			
			if selected_item.data is HBTimingChange:
				sync_timing = true
			
			if not deleted_times.has(selected_item.data.time):
				deleted_times.append(selected_item.data.time)
		
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_method(self, "_on_timing_points_changed")
		
		undo_redo.add_do_method(self, "sync_lyrics")
		undo_redo.add_undo_method(self, "sync_lyrics")
		
		if sync_timing:
			undo_redo.add_do_method(self, "_on_timing_information_changed")
			undo_redo.add_undo_method(self, "_on_timing_information_changed")
		
		selected = []
		undo_redo.commit_action()
		
		check_for_multi_changes(deleted_times)

func is_slide_chain(note: HBTimingPoint):
	if note is HBNoteData and note.is_slide_note():
		for item in current_notes:
			if  item.data is HBNoteData and \
				item.data.time > note.time and \
				item.data.note_type == note.get_chain_type() and \
				item.data.get_meta("second_layer") == note.get_meta("second_layer"):
					return true
			
			if  item.data is HBNoteData and \
				item.data.time > note.time and \
				item.data.note_type == note.note_type and \
				item.data.get_meta("second_layer") == note.get_meta("second_layer"):
					return false
	
	return false

func check_for_multi_changes(times: Array, times_cache: Dictionary = {}):
	if UserSettings.user_settings.editor_auto_multi:
		# Merge action with the previous one
		undo_redo.create_action("MERGE")
		
		var tp_cache := get_timing_points()
		
		for time in times:
			var _notes_at_time := []
			if time in times_cache:
				_notes_at_time = times_cache[time]
			else:
				_notes_at_time = get_notes_at_time(time, tp_cache)
				times_cache[time] = _notes_at_time
			
			var notes_at_time := []
			for note in _notes_at_time:
				if note is HBBaseNote:
					notes_at_time.append(note)
			
			for note in notes_at_time:
				_set_multi_pos(note)
				
				# Check multi status
				if notes_at_time.size() > 1:
					# There is a multi at the given time, manage it
					if not note.is_multi_allowed() or is_slide_chain(note):
						_set_multi_params_clearing_angles(note)
					else:
						_set_multi_params(note)
				else:
					# There isnt any multi, so clear all multi-related properties
					_clear_multi_params(note)
				
				undo_redo.add_do_method(note.get_timeline_item(), "update_widget_data")
				undo_redo.add_undo_method(note.get_timeline_item(), "update_widget_data")
			
			# Set correct multi angles
			_set_multi_angles(notes_at_time)
		
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_method(self, "_on_timing_points_changed")
		
		undo_redo.commit_action()

func _set_multi_pos(note: HBBaseNote):
	var multi_pos = 3 - note.note_type
	if note.note_type in [HBBaseNote.NOTE_TYPE.SLIDE_LEFT, HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT]:
		multi_pos = 3 if note.get_meta("second_layer") else 1
	if note.note_type in [HBBaseNote.NOTE_TYPE.SLIDE_RIGHT, HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT]:
		multi_pos = 2 if note.get_meta("second_layer") else 0
	if note.note_type == HBBaseNote.NOTE_TYPE.HEART:
		multi_pos = 4
	
	note.set_meta("multi_pos", multi_pos)

func _set_multi_params(note):
	undo_redo.add_do_property(note, "oscillation_amplitude", 0)
	undo_redo.add_do_property(note, "distance", 880)
	
	undo_redo.add_undo_property(note, "oscillation_amplitude", note.oscillation_amplitude)
	undo_redo.add_undo_property(note, "distance", note.distance)
	
	if UserSettings.user_settings.editor_auto_place and not note.pos_modified:
		var multi_pos = note.get_meta("multi_pos")
		
		undo_redo.add_do_property(note, "position", Vector2(note.position.x, 918 - multi_pos * 96))
		undo_redo.add_undo_property(note, "position", note.position)

func _clear_multi_params(note):
	undo_redo.add_do_property(note, "oscillation_amplitude", 500)
	undo_redo.add_do_property(note, "distance", 1200)
	
	undo_redo.add_undo_property(note, "oscillation_amplitude", note.oscillation_amplitude)
	undo_redo.add_undo_property(note, "distance", note.distance)
	
	if UserSettings.user_settings.editor_auto_place and not note.pos_modified:
		undo_redo.add_do_property(note, "position", Vector2(note.position.x, 918))
		undo_redo.add_undo_property(note, "position", note.position)

func _set_multi_params_clearing_angles(note):
	undo_redo.add_do_property(note, "oscillation_amplitude", 500)
	undo_redo.add_do_property(note, "oscillation_frequency", -2)
	undo_redo.add_do_property(note, "distance", 1200)
	
	undo_redo.add_undo_property(note, "oscillation_amplitude", note.oscillation_amplitude)
	undo_redo.add_undo_property(note, "oscillation_frequency", note.oscillation_frequency)
	undo_redo.add_undo_property(note, "distance", note.distance)
	
	if UserSettings.user_settings.editor_auto_place and not note.pos_modified:
		var multi_pos = note.get_meta("multi_pos")
		
		undo_redo.add_do_property(note, "position", Vector2(note.position.x, 918 - multi_pos * 96))
		undo_redo.add_undo_property(note, "position", note.position)

func _sort_by_multi_pos(a, b):
	var multi_pos_a = a.get_meta("multi_pos")
	var multi_pos_b = b.get_meta("multi_pos")
	return multi_pos_a > multi_pos_b

func _set_multi_angles(notes: Array):
	notes.sort_custom(self, "_sort_by_multi_pos")
	
	for i in notes.size():
		var note = notes[i]
		
		if UserSettings.user_settings.editor_auto_place and not note.pos_modified:
			var angle = -90
			
			if note.is_multi_allowed() and not is_slide_chain(note):
				if notes.size() == 2:
					angle = -45.0 if i == 0 else 45.0
				elif notes.size() > 2:
					angle = -45.0 if note.get_meta("multi_pos") > 1 else 45.0
		
			undo_redo.add_do_property(note, "entry_angle", angle)
			undo_redo.add_undo_property(note, "entry_angle", note.entry_angle)


func deselect_all():
	for item in selected:
		item.deselect()
	selected = []
	
	inspector.stop_inspecting()
	notify_selected_changed()

func deselect_item(item: EditorTimelineItem):
	if item in selected:
		selected.erase(item)
		item.deselect()
		if selected.size() > 0:
			inspector.inspect(selected)
		else:
			inspector.stop_inspecting()
	
	notify_selected_changed()

func toggle_selection(item):
	if item in selected:
		deselect_item(item)
	else:
		select_item(item, true)

func get_notes_at_time(time: int, tp_cache: Array = []) -> Array:
	var notes := []
	
	if tp_cache == []:
		tp_cache = get_timing_points()
	
	for note in tp_cache:
		if note is HBTimingPoint:
			if note.time == time:
				notes.append(note)
	
	return notes

func user_create_timing_point(layer: EditorLayer, item: EditorTimelineItem, force: bool = false):
	if not timing_map and not force:
		no_timing_map_dialog.popup_centered()
		return
	
	undo_redo.create_action("Add new timing point")
	
	if item.data is HBBaseNote and UserSettings.user_settings.editor_auto_place:
		item.data = autoplace(item.data)
	
	item.data.set_meta("second_layer", layer.layer_name.ends_with("2"))
	
	undo_redo.add_do_method(self, "add_item_to_layer", layer, item)
	undo_redo.add_undo_method(self, "remove_item_from_layer", layer, item)
	undo_redo.add_undo_method(item, "deselect")
	
	undo_redo.add_do_method(self, "_on_timing_points_changed")
	undo_redo.add_undo_method(self, "_on_timing_points_changed")
	
	if item is EditorSectionTimelineItem:
		undo_redo.add_do_method(timeline, "update")
		undo_redo.add_undo_method(timeline, "update")
	
	if item.data is HBTimingChange:
		undo_redo.add_do_method(self, "_on_timing_information_changed")
		undo_redo.add_undo_method(self, "_on_timing_information_changed")
	
	undo_redo.commit_action()
	
	check_for_multi_changes([item.data.time])

func remove_item_from_layer(layer: EditorLayer, item: EditorTimelineItem):
	layer.remove_item(item)
	current_notes.erase(item)
	_removed_items.append(item)

	rhythm_game.editor_remove_timing_point(item.data)
	_on_timing_points_changed()
	force_game_process()
	
	
func _create_bpm_change():
	add_event_timing_point(HBBPMChange)

func pause():
	game_playback.pause()
	game_preview.set_visualizer_processing_enabled(false)
	game_preview.widget_area.show()
	playhead_position = snap_time_to_timeline(playhead_position)
	game_preview.pause()
	emit_signal("playhead_position_changed")
	playback_speed_slider.editable = true
	reveal_ui(false)
func _on_PauseButton_pressed(auto = false):
	pause()
	seek(playhead_position)
	play_button.show()
	pause_button.hide()
	emit_signal("paused")
	
	if not auto:
		create_queued_timing_points()

func _on_PlayButton_pressed():
	if UserSettings.user_settings.editor_autosave_enabled and modified:
		_on_SaveButton_pressed()
	_playhead_traveling = true
	game_preview.play_at_pos(playhead_position/1000.0)
	game_playback.start()
	play_button.hide()
	pause_button.show()
	game_preview.set_visualizer_processing_enabled(true)
	game_preview.widget_area.hide()
	playback_speed_slider.editable = false
	obscure_ui(false)
	
# Fired when any timing point is tells the game to rethink its existence
func _on_timing_points_changed():
	game_playback.chart = get_chart()
	_on_PauseButton_pressed(true)
	emit_signal("timing_points_changed")

func _on_timing_points_params_changed():
	game_playback._on_timing_params_changed()
	game_playback.seek(playhead_position)

func get_song_length():
	if game_playback.game.audio_playback:
		return game_playback.game.audio_playback.get_length_msec() / 1000.0
	else:
		return 0.0
		
func get_chart():
	var chart = HBChart.new()
	var layer_items = timeline.get_layers()
	chart.editor_settings = song_editor_settings
	var layers = []
	for layer in layer_items:
		if layer.layer_name in ["Lyrics", "Sections", "Tempo Map"]:
			continue
		layers.append({
			"name": layer.layer_name,
			"timing_points": layer.get_timing_points()
		})
	chart.layers = layers
	return chart
func serialize_chart():
	return get_chart().serialize()

func load_settings(settings: HBPerSongEditorSettings, skip_settings_menu=false):
	song_editor_settings.disconnect("property_changed", self, "emit_signal")
	song_editor_settings = settings
	for layer in timeline.get_layers():
		var layer_visible = not layer.layer_name in settings.hidden_layers
		timeline.change_layer_visibility(layer_visible, layer.layer_name)
	
	timeline_snap_button.pressed = settings.timeline_snap
	
	game_preview.settings = settings
	show_bg_button.pressed = settings.show_bg
	show_video_button.pressed = settings.show_video
	
	emit_signal("timing_information_changed")
	song_editor_settings.connect("property_changed", self, "emit_signal", ["song_editor_settings_changed"])
	
	song_settings_editor.load_settings(settings)
	
	if not skip_settings_menu:
		emit_signal("song_editor_settings_changed")
	
	emit_signal("modules_update_settings", settings)

func update_user_settings():
	waveform_button.pressed = UserSettings.user_settings.editor_show_waveform
	
	grid_snap_button.pressed = UserSettings.user_settings.editor_grid_snap
	show_grid_button.pressed = UserSettings.user_settings.editor_show_grid
	grid_x_spinbox.value = UserSettings.user_settings.editor_grid_resolution.x
	grid_y_spinbox.value = UserSettings.user_settings.editor_grid_resolution.y
	
	emit_signal("modules_update_user_settings")

func from_chart(chart: HBChart, ignore_settings=false, importing=false):
	rhythm_game.editor_clear_notes()
	timeline.clear_layers()
	
	if not importing:
		undo_redo.clear_history()
	
	selected = []
	song_settings_editor.clear_layers()
	current_notes = []
	timeline.send_time_cull_changed_signal()
	for layer in chart.layers:
		var layer_scene = EDITOR_LAYER_SCENE.instance()
		layer_scene.layer_name = layer.name
		timeline.add_layer(layer_scene)
		var layer_n = timeline.get_layers().size()-1
		for item_d in layer.timing_points:
			var item = item_d.get_timeline_item()
			item.data = item_d
			add_item(layer_n, item)
			if item_d is HBSustainNote:
				item.sync_value("end_time")
		
		var layer_visible = not layer.name in song_editor_settings.hidden_layers
		if not ignore_settings:
			layer_visible = not layer.name in chart.editor_settings.hidden_layers
		
		song_settings_editor.add_layer(layer.name, layer_visible)
		timeline.change_layer_visibility(layer_visible, layer.name)
	
	# Lyrics layer
	var lyrics_layer_scene = EDITOR_LAYER_SCENE.instance()
	lyrics_layer_scene.layer_name = "Lyrics"
	var lyrics_layer_visible = not "Lyrics" in song_editor_settings.hidden_layers
	if not ignore_settings:
		lyrics_layer_visible = not "Lyrics" in chart.editor_settings.hidden_layers
	
	timeline.add_layer(lyrics_layer_scene)
	timeline.change_layer_visibility(lyrics_layer_visible, lyrics_layer_scene.layer_name)
	song_settings_editor.add_layer("Lyrics", lyrics_layer_visible)
	
	# Sections layer
	var sections_layer_scene = EDITOR_LAYER_SCENE.instance()
	sections_layer_scene.layer_name = "Sections"
	var sections_layer_visible = not "Sections" in song_editor_settings.hidden_layers
	if not ignore_settings:
		sections_layer_visible = not "Sections" in chart.editor_settings.hidden_layers
	
	timeline.add_layer(sections_layer_scene)
	timeline.change_layer_visibility(sections_layer_visible, sections_layer_scene.layer_name)
	song_settings_editor.add_layer("Sections", sections_layer_visible)
	
	# Timing changes layer
	var tempo_layer_scene = EDITOR_LAYER_SCENE.instance()
	tempo_layer_scene.layer_name = "Tempo Map"
	var tempo_layer_visible = true
	
	timeline.add_layer(tempo_layer_scene)
	timeline.change_layer_visibility(tempo_layer_visible, tempo_layer_scene.layer_name)
	song_settings_editor.add_layer(tempo_layer_scene.layer_name, tempo_layer_visible)
	
	var lyrics_layer_n = timeline.get_layers().size() - 3
	var sections_layer_n = timeline.get_layers().size() - 2
	var tempo_layer_n = timeline.get_layers().size() - 1
	
	for phrase in current_song.lyrics:
		if phrase is HBLyricsPhrase:
			var start_item = HBLyricsPhraseStart.new()
			start_item.time = phrase.time
			add_item(lyrics_layer_n, start_item.get_timeline_item())
			
			for lyric in phrase.lyrics:
				if lyric is HBLyricsLyric:
					add_item(lyrics_layer_n, lyric.get_timeline_item())
			
			var end_item = HBLyricsPhraseEnd.new()
			end_item.time = phrase.end_time
			add_item(lyrics_layer_n, end_item.get_timeline_item())
	
	for section in current_song.sections:
		if section is HBChartSection:
			add_item(sections_layer_n, section.get_timeline_item())
	
	for timing_change in current_song.timing_changes:
		if timing_change is HBTimingChange:
			add_item(tempo_layer_n, timing_change.get_timeline_item())
	
	if not ignore_settings:
		load_settings(chart.editor_settings)
	
	_on_timing_points_changed()
	
	# Disconnect the cancel action in the chart open dialog, because we already have at least
	# a chart loaded
	if open_chart_popup_dialog.get_cancel().is_connected("pressed", self, "exit"):
		open_chart_popup_dialog.get_cancel().disconnect("pressed", self, "exit")
		open_chart_popup_dialog.get_close_button().disconnect("pressed", self, "exit")
	
	deselect_all()
	sync_lyrics()
	force_game_process()

func paste_note_data(notes: Array):
	undo_redo.create_action("Paste note data")
	
	for i in selected.size():
		var selected_item = selected[i]
		
		if selected_item.data is HBBaseNote:
			var new_data = notes[i % notes.size()].clone()
			new_data.note_type = selected_item.data.note_type
			new_data.time = selected_item.data.time
			
			for property in new_data.get_inspector_properties():
				if selected_item.data.get(property) != null:  # HACK: There is no Object.has() method :/
					undo_redo.add_do_property(selected_item.data, property, new_data.get(property))
					undo_redo.add_undo_property(selected_item.data, property, selected_item.data.get(property))
			
			undo_redo.add_do_method(selected_item, "update_widget_data")
			undo_redo.add_undo_method(selected_item, "update_widget_data")
	
	undo_redo.add_do_method(self, "_on_timing_points_changed")
	undo_redo.add_undo_method(self, "_on_timing_points_changed")
	
	undo_redo.add_do_method(inspector, "sync_visible_values_with_data")
	undo_redo.add_undo_method(inspector, "sync_visible_values_with_data")
	
	undo_redo.commit_action()

	force_game_process()

func _on_SaveSongSelector_chart_selected(song_id, difficulty):
	var song = SongLoader.songs[song_id]
	var chart_path = song.get_chart_path(difficulty)
	var file = File.new()
	file.open(chart_path, File.WRITE)
	file.store_string(JSON.print(serialize_chart(), "  "))

func load_song(song: HBSong, difficulty: String, p_hidden: bool):
	deselect_all()
	
	hidden = p_hidden
	
	var chart_path = song.get_chart_path(difficulty)
	var file = File.new()
	var dir = Directory.new()
	var chart = HBChart.new()
	chart.editor_settings.bpm = song.bpm
	if dir.file_exists(chart_path):
		file.open(chart_path, File.READ)
		
		var chart_json = JSON.parse(file.get_as_text())
		if chart_json.error == OK:
			var result = chart_json.result
			chart = HBChart.new()
			chart.deserialize(result, song)
	current_song = song
	
	HBGame.rich_presence.update_activity({
		"state": "In editor",
		"details": current_song.title,
		"start_timestamp": OS.get_unix_time()
	})
	add_child(rhythm_game_playtest_popup)
	rhythm_game_playtest_popup.rhythm_game.audio_playback = null
	rhythm_game_playtest_popup.rhythm_game.voice_audio_playback = null
	remove_child(rhythm_game_playtest_popup)
	update_media()
	seek(0, true)
	timeline.set_layers_offset(0)
	playback_speed_slider.value = 1.0
	
	OS.set_window_title("Project Heartbeat - " + song.get_visible_title() + " - " + difficulty.capitalize())
	current_title_button.text = "%s (%s)" % [song.get_visible_title(), difficulty.capitalize()]
	from_chart(chart)
	current_difficulty = difficulty
	current_difficulty = difficulty
	
	save_button.disabled = hidden
	save_as_button.disabled = false
	
	modified = false

func update_media():
	game_preview.set_song(current_song, song_editor_settings.selected_variant)
	game_playback.set_song(current_song, song_editor_settings.selected_variant)
	timeline.set_audio_stream(game_playback.godot_audio_stream)
	seek(playhead_position)
	timeline.send_time_cull_changed_signal()

func obscure_ui(extended: bool = true):
	for control in get_tree().get_nodes_in_group("disabled_ui"):
		if control is BaseButton:
			control.disabled = true
		if control is LineEdit or control is Range:
			control.editable = false
		if control is SpinBox:
			control.get_line_edit().editable = false
	
	if not extended:
		return
	
	for control in get_tree().get_nodes_in_group("extended_disabled_ui"):
		if control is BaseButton:
			control.disabled = true
		if control is LineEdit or control is Range:
			control.editable = false
		if control is SpinBox:
			control.get_line_edit().editable = false

func reveal_ui(extended: bool = true):
	for control in get_tree().get_nodes_in_group("disabled_ui"):
		if control is BaseButton:
			control.disabled = false
		if control is LineEdit or control is Range:
			control.editable = true
		if control is SpinBox:
			control.get_line_edit().editable = true
	
	save_button.disabled = hidden
	
	if not extended:
		return
	
	for control in get_tree().get_nodes_in_group("extended_disabled_ui"):
		if control is BaseButton:
			control.disabled = false
		if control is LineEdit or control is Range:
			control.editable = true
		if control is SpinBox:
			control.get_line_edit().editable = true

func exit():
	get_tree().change_scene_to(load("res://menus/MainMenu3D.tscn"))
	
	OS.window_maximized = false
	UserSettings.apply_display_mode()
	
	Diagnostics.fps_label.get_font("font").size = 23

func try_exit():
	if modified:
		_confirm_action = "exit"
		save_confirmation_dialog.popup_centered()
	else:
		exit()

func open():
	open_chart_popup_dialog.popup_centered()

func try_open():
	if modified:
		_confirm_action = "open"
		save_confirmation_dialog.popup_centered()
	else:
		open()

func release_owned_focus():
	$FocusTrap.grab_focus()

func get_note_resolution() -> float:
	return 1 / sync_module.get_resolution() if sync_module else 1/16.0

func get_timing_changes() -> Array:
	return timing_changes

func get_timing_map() -> Array:
	return timing_map

func get_normalized_timing_map() -> Array:
	return normalized_timing_map

func get_signature_map() -> Array:
	return signature_map

func get_metronome_map() -> Array:
	return metronome_map

# We need to go the long way round to prevent weird rounding issues
func map_intervals(obj: Array, start: int, end: int, interval: float):
	var diff = end - start
	for i in range(diff / interval + 1, 0, -1):
		obj.append(int(start + (i - 1) * interval))

# Music theory fucking sucks.
# 
# A grid beat is determined by the specific subdivision, which might or might not be the same
# as the subdivisions marked by our time signature. This means that the yellow bars (bars) *might*
# not line up with the gray ones (beats), and so we only care about the beats. The charter is the
# one responsible for setting an appropiate subdivision, allthough most common ones should line up
# nicely.
#
# Also, the "beats" in beats-per-minute are actually the same "beats" in beats-per-bar, so the denominator
# part of the time signature *will* affect when the beat plays. We will make the assumption that bpms are
# labeled according to a time signature of 4/4, and charters *will* follow it, because Im a dictator with
# wet dreams about power. And also because this is stupid and I cant anymore.
# 
# *sigh* Im sorry, future me -.- (Lino 9/10/22)
func _on_timing_information_changed(f=null):
	timing_changes.clear()
	timing_map.clear()
	normalized_timing_map.clear()
	signature_map.clear()
	metronome_map.clear()
	
	var _timing_changes = []
	for item in get_timeline_items():
		if item.data is HBTimingChange:
			timing_changes.append(item)
			_timing_changes.append(item.data)
	
	game_playback.game.timing_changes = _timing_changes
	
	timing_changes.sort_custom(self, "_sort_current_items_impl")
	timing_changes.invert()
	
	var end_t = get_song_length() * 1000
	for item in timing_changes:
		var timing_change = item.data as HBTimingChange
		
		var ms_per_beat: float = (60.0 / timing_change.bpm) * 1000.0 * 4 * get_note_resolution()
		map_intervals(timing_map, timing_change.time, end_t, ms_per_beat)
		
		var ms_per_eight: float = (60.0 / timing_change.bpm) * 1000.0 * 4 / 8.0
		map_intervals(normalized_timing_map, timing_change.time, end_t, ms_per_eight)
		
		var ms_per_bar: float = (60.0 / timing_change.bpm) * 1000.0 * \
			4 * (float(timing_change.time_signature.numerator) / float(timing_change.time_signature.denominator))
		map_intervals(signature_map, timing_change.time, end_t, ms_per_bar)
		
		var ms_per_metronome_beat: float = (60.0 / timing_change.bpm) * 1000.0 * \
			4 * (1 / float(timing_change.time_signature.denominator))
		map_intervals(metronome_map, timing_change.time, end_t, ms_per_metronome_beat)
		
		end_t = timing_change.time
	
	timing_map.invert()
	normalized_timing_map.invert()
	signature_map.invert()
	
	release_owned_focus()
	timeline.update()
	emit_signal("timing_information_changed")
	emit_signal("_on_timing_points_changed")


func _on_SaveButton_pressed():
	if hidden:
		return
	
	var chart_path = current_song.get_chart_path(current_difficulty)
	var file = File.new()
	file.open(chart_path, File.WRITE)
	var chart = get_chart()
	file.store_string(JSON.print(chart.serialize(), "  "))
	file.close()
	
	current_song.timing_changes = []
	for item in get_timing_changes():
		current_song.timing_changes.append(item.data)
	
	current_song.lyrics = get_lyrics()
	current_song.sections = get_sections()
	current_song.charts[current_difficulty]["note_usage"] = chart.get_note_usage()
	current_song.has_audio_loudness = true
	current_song.audio_loudness = SongDataCache.audio_normalization_cache[current_song.id].loudness
	
	for difficulty in current_song.charts:
		current_song.charts[difficulty]["hash"] = current_song.generate_chart_hash(difficulty)
		var curr_chart = current_song.get_chart_for_difficulty(difficulty) as HBChart
		current_song.charts[difficulty]["max_score"] = curr_chart.get_max_score()
	
	current_song.save_song()
	message_shower._show_notification("Chart saved")
	
	modified = false

func _on_ShowGridbutton_toggled(button_pressed):
	grid_renderer.visible = button_pressed
	UserSettings.user_settings.editor_show_grid = button_pressed
	UserSettings.save_user_settings()

func _on_GridSnapButton_toggled(button_pressed):
	snap_to_grid_enabled = button_pressed
	UserSettings.user_settings.editor_grid_snap = button_pressed
	UserSettings.save_user_settings()

func snap_position_to_grid(new_pos: Vector2, prev_pos: Vector2, one_direction: bool):
	var final_position = new_pos
	
	if snap_to_grid_enabled:
		var grid_size = grid_renderer.get_grid_size()
		
		final_position.x = floor(new_pos.x / grid_size.y) * grid_size.y
		final_position.y = floor(new_pos.y / grid_size.x) * grid_size.x
		final_position += grid_renderer.get_grid_offset()
		
	
	var diff = new_pos - prev_pos
	var direction = 1 if max(abs(diff.x), abs(diff.y)) == abs(diff.x) else 0
	
	# (Yandevs ghost)
	if one_direction:
		if direction:
			# X snap
			final_position.y = prev_pos.y
		else:
			# Y snap
			final_position.x = prev_pos.x
	
	return final_position


func _on_TimelineGridSnapButton_toggled(button_pressed):
	timeline_snap_enabled = button_pressed
	song_editor_settings.set("timeline_snap", button_pressed)

func snap_time_to_timeline(time: int) -> int:
	var map = get_timing_map()
	if timeline_snap_enabled and map:
		return map[_closest_bound(map, time)]
	else:
		return time

func _on_layer_visibility_changed(visibility: bool, layer_name: String):
	song_editor_settings.set_layer_visibility(visibility, layer_name)
	if layer_name == "Sections":
		timeline.update()

func show_error(error: String):
	$Popups/PluginErrorDialog.rect_size = Vector2.ZERO
	$Popups/PluginErrorDialog.dialog_text = error
	$Popups/PluginErrorDialog.popup_centered_minsize(Vector2(0, 0))

# PLAYTEST SHIT
func _on_PlaytestButton_pressed(at_time):
	if UserSettings.user_settings.editor_autosave_enabled and modified:
		_on_SaveButton_pressed()
	
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920, 1080))
	_on_PauseButton_pressed()
	rhythm_game.set_process_input(false)
	playtesting = true
	add_child(rhythm_game_playtest_popup)
	$VBoxContainer.hide()
	var play_time = 0.0
	if at_time:
		play_time = playhead_position
	rhythm_game_playtest_popup.set_audio(current_song, game_playback.audio_source, game_playback.voice_source, song_editor_settings.selected_variant)
	rhythm_game_playtest_popup.play_song_from_position(current_song, get_chart(), play_time / 1000.0)

func _on_playtest_quit():
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	playtesting = false
	$VBoxContainer.show()
	remove_child(rhythm_game_playtest_popup)
	game_playback._on_timing_params_changed()
	rhythm_game.set_process_input(true)


func _chronological_compare(a, b):
	return a.time < b.time

func get_lyrics():
	var phrases = []
	for layer in timeline.get_layers():
		if layer.layer_name == "Lyrics":
			var is_inside_phrase = false
			var curr_phrase: HBLyricsPhrase
			var points = layer.get_timing_points()
			points.sort_custom(self, "_chronological_compare")
			for i in range(points.size()):
				if i < points.size()-1:
					var p1 = points[i]
					var p2 = points[i+1]
					if p1.time == p2.time:
						if p1 is HBLyricsLyric and p2 is HBLyricsPhraseStart or \
								p1 is HBLyricsPhraseStart and p2 is HBLyricsPhraseEnd:
							points[i] = p2
							points[i+1] = p1
				var point = points[i]
				
				if point is HBLyricsPhraseStart:
					is_inside_phrase = true
					curr_phrase = HBLyricsPhrase.new()
					curr_phrase.time = point.time
				elif point is HBLyricsPhraseEnd:
					if curr_phrase:
						curr_phrase.end_time = point.time
						phrases.append(curr_phrase)
					curr_phrase = null
					is_inside_phrase = false
				elif is_inside_phrase:
					if point is HBLyricsLyric:
						curr_phrase.lyrics.append(point)
			break
	return phrases
func sync_lyrics():
	game_playback.set_lyrics(get_lyrics())

func get_sections():
	var sections = []
	
	for layer in timeline.get_layers():
		if layer.layer_name == "Sections":
			var points = layer.get_timing_points()
			points.sort_custom(self, "_chronological_compare")
			
			for point in points:
				if point is HBChartSection:
					sections.append(point)
	
	return sections

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		for item in _removed_items:
			item.queue_free()
		if not playtesting:
			if not rhythm_game_playtest_popup.is_queued_for_deletion() and not rhythm_game_playtest_popup.is_inside_tree():
				rhythm_game_playtest_popup.queue_free()


func get_hold_size(data):
	if not data is HBNoteData or not data.hold or not UserSettings.user_settings.editor_show_hold_calculator:
		return 0
	
	var size = HBRhythmGame.MAX_HOLD
	
	for hold in hold_ends:
		var dt = hold.end - data.time
		
		if dt > 0 and dt < size:
			if hold.start < data.time:
				if hold.end - hold.start < size:
					size = dt
			elif hold.start > data.time:
				size = dt
			else:
				size = hold.end - hold.start
	
	return size


func _cache_hold_ends():
	if not UserSettings.user_settings.editor_show_hold_calculator:
		return
	
	var points = get_timing_points()
	points.invert()
	hold_ends = []
	
	for point in points:
		if point is HBNoteData and point.hold:
			var end = {"start": point.time, "end": point.time + HBRhythmGame.MAX_HOLD}
			
			for note in points:
				if note is HBBaseNote and note.note_type == point.note_type:
					if note.time - point.time > 0 and note.time - point.time < HBRhythmGame.MAX_HOLD:
						end = {"start": point.time, "end": note.time}
						break
			
			hold_ends.append(end)
	
	for item in get_timeline_items():
		if item.data is HBNoteData and item.data.hold:
			item.update()


func autoplace(data: HBBaseNote, force = false, tp_cache: Array = [], times_cache: Dictionary = {}):
	if not data.position.y in [630, 726, 822, 918] and data.position != Vector2(960, 540) and not force:
		# Safeguard against modifying old charts
		data.pos_modified = true
		return data.clone()
	
	if not data is HBBaseNote:
		return
	var new_data = data.clone() as HBBaseNote
	
	var time_as_eight = _linear_bound(get_normalized_timing_map(), data.time)
	time_as_eight = fmod(time_as_eight, 15.0)
	if time_as_eight < 0:
		time_as_eight = fmod(15.0 - abs(time_as_eight), 15.0)
	
	var notes_at_time := []
	if data.time in times_cache:
		notes_at_time = times_cache[data.time]
	else:
		notes_at_time = get_notes_at_time(data.time, tp_cache)
		times_cache[data.time] = notes_at_time
	
	var selected_data = []
	for item in selected:
		selected_data.append(item.data)
	
	var place_at_note = null
	for note in notes_at_time:
		if note is HBBaseNote and note.pos_modified and (not note in selected_data) and (not force):
			place_at_note = note
			break
	
	if not place_at_note:
		new_data.position.x = 242 + 96 * time_as_eight
		new_data.position.y = 918
		
		new_data.oscillation_frequency = -2
		new_data.entry_angle = -90
	else:
		new_data.position = place_at_note.position
		new_data.entry_angle = place_at_note.entry_angle
		new_data.pos_modified = true
	
	return new_data


func open_link(link: String):
	OS.shell_open(link)

func _on_WaveformButton_toggled(button_pressed):
	timeline.set_waveform(button_pressed)
	UserSettings.user_settings.editor_show_waveform = button_pressed
	UserSettings.save_user_settings()


func _on_SexButton_pressed():
	$Popups/SexDialog.popup_centered()


func hold_calculator_toggled():
	for item in get_timeline_items():
		if item.data is HBNoteData and item.data.hold:
			item.update()


func _on_left_HSplitContainer_dragged(offset: int):
	if offset < 20:
		toolbox_tab_container.visible = false
	else:
		toolbox_tab_container.visible = true
	
	UserSettings.user_settings.editor_left_panel_offset = offset
	UserSettings.save_user_settings()

func _on_right_HSplitContainer_dragged(offset: int):
	UserSettings.user_settings.editor_right_panel_offset = offset
	UserSettings.save_user_settings()

func _on_VSplitContainer_dragged(offset: int):
	UserSettings.user_settings.editor_bottom_panel_offset = offset
	UserSettings.save_user_settings()


func _on_PlaybackSpeedSlider_value_changed(value):
	playback_speed_label.text = "x %.2f" % [value]
	game_playback.set_speed(value, true)

func _on_playback_speed_changed(speed: float):
	if not speed == 1.0:
		if show_video_button.pressed:
			game_preview.show_video(false)
	else:
		if show_video_button.pressed:
			game_preview.video_player.stream_position = playhead_position / 1000.0
			game_preview.show_video(true)


func queue_timing_point_creation(layer, timing_point):
	if not timing_map:
		_on_PauseButton_pressed(true)
		no_timing_map_dialog.popup_centered()
		return
	
	for entry in timing_point_creation_queue:
		if entry.timing_point == timing_point:
			return
	
	var item = timing_point.get_timeline_item()
	timing_point_creation_queue.append({"layer": layer, "timing_point": timing_point, "item": item})
	add_item_to_layer(layer, item)

func create_queued_timing_points():
	for entry in timing_point_creation_queue:
		remove_item_from_layer(entry.layer, entry.item)
		user_create_timing_point(entry.layer, entry.item)
	
	timing_point_creation_queue.clear()


func reset_note_position():
	undo_redo.create_action("Reset note position")
	
	var check_multi_times := []
	for item in selected:
		if not item.data is HBBaseNote:
			continue
		
		var new_pos := Vector2(960, 540)
		var new_angle := 0
		var new_freq := 2.0
		
		if UserSettings.user_settings.editor_auto_place:
			var new_data = autoplace(item.data, true)
			new_pos = new_data.position
			new_angle = new_data.entry_angle
			new_freq = new_data.oscillation_frequency
		
		undo_redo.add_do_property(item.data, "position", new_pos)
		undo_redo.add_do_property(item.data, "entry_angle", new_angle)
		undo_redo.add_do_property(item.data, "oscillation_frequency", new_freq)
		undo_redo.add_do_property(item.data, "pos_modified", false)
		undo_redo.add_undo_property(item.data, "position", item.data.position)
		undo_redo.add_undo_property(item.data, "entry_angle", item.data.entry_angle)
		undo_redo.add_undo_property(item.data, "oscillation_frequency", item.data.oscillation_frequency)
		undo_redo.add_undo_property(item.data, "pos_modified", item.data.pos_modified)
		
		undo_redo.add_do_method(item, "update_widget_data")
		undo_redo.add_undo_method(item, "update_widget_data")
		
		if not check_multi_times.has(item.data.time):
			check_multi_times.append(item.data.time)
	
	undo_redo.add_do_method(inspector, "sync_visible_values_with_data")
	undo_redo.add_undo_method(inspector, "sync_visible_values_with_data")
	
	undo_redo.commit_action()
	
	check_for_multi_changes(check_multi_times)


func _update_grid_resolution():
	grid_x_spinbox.value = UserSettings.user_settings.editor_grid_resolution.x
	grid_y_spinbox.value = UserSettings.user_settings.editor_grid_resolution.y

func _on_preview_size_changed():
	for item in selected:
		item.update_widget_data()
		if item.widget:
			item.widget.arrange_gizmo()

var force_game_process_queued := false

func _force_game_process_impl():
	force_game_process_queued = false
	rhythm_game.seek_new(playhead_position, true)
	rhythm_game._process(0)

func force_game_process():
	if not force_game_process_queued:
		force_game_process_queued = true
		call_deferred("_force_game_process_impl")

func _on_Sfx_toggled(button_pressed: bool):
	rhythm_game.sfx_enabled = button_pressed

func _toggle_settings_popup():
	if settings_editor.visible:
		settings_editor.hide()
	else:
		settings_editor.popup_centered()

func shortcuts_blocked() -> bool:
	for control in get_tree().get_nodes_in_group("block_shortcuts"):
		if control.is_visible_in_tree():
			return true
	
	return false

func _on_version_changed():
	modified = true

var _confirm_action = "exit"
func _on_SaveConfirmationDialog_confirmed():
	call(_confirm_action)

func guide_user_to_timing_changes():
	var idx := 0
	for i in right_panel.get_child_count():
		if right_panel.get_child(i) == sync_module:
			idx = i
			break
	
	right_panel.current_tab = idx
	sync_module.create_timing_change_button.button.grab_focus()
