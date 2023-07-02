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
const EDITOR_MODULES_DIR = "res://tools/editor/editor_modules"

@onready var save_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/SaveButton")
@onready var save_as_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/SaveAsButton")
@onready var timeline = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/EditorTimeline")
@onready var rhythm_game = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/RhythmGame")
@onready var game_preview = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview")
@onready var grid_renderer = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/GridRenderer")
@onready var inspector = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Control2/TabContainer/Inspector")
@onready var current_title_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/CurrentTitleButton")
@onready var open_chart_popup_dialog = get_node("Popups/OpenChartPopupDialog")
@onready var rhythm_game_playtest_popup = preload("res://tools/editor/EditorRhythmGamePopup.tscn").instantiate()
@onready var play_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/PlayButton")
@onready var pause_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/PauseButton")
@onready var editor_help_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/EditorHelpButton")
@onready var game_playback = EditorPlayback.new(rhythm_game)
@onready var message_shower = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/MessageShower")
@onready var first_time_message_dialog := get_node("Popups/FirstTimeMessageDialog")
@onready var info_label = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/HBoxContainer/InfoLabel")
@onready var waveform_button = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/WaveformButton")
@onready var timeline_snap_button = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/TimelineGridSnapButton")
@onready var show_bg_button = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/ShowBGButton")
@onready var show_video_button = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/ShowVideoButton")
@onready var grid_snap_button = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/GridSnapButton")
@onready var show_grid_button = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/ShowGridbutton")
@onready var grid_x_spinbox = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/SpinBox")
@onready var grid_y_spinbox = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/SpinBox2")
@onready var sex_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/SexButton")
@onready var toolbox_tab_container = get_node("VBoxContainer/VSplitContainer/HSplitContainer/Control/TabContainer2")
@onready var playback_speed_label = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/PlaybackSpeedLabel")
@onready var playback_speed_slider = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/PlaybackSpeedSlider")
@onready var settings_editor = get_node("%EditorGlobalSettings")
@onready var song_settings_editor = get_node("%EditorGlobalSettings").song_settings_tab
@onready var botton_panel_vbox_container = get_node("VBoxContainer/VSplitContainer")
@onready var left_panel_vbox_container = get_node("VBoxContainer/VSplitContainer/HSplitContainer")
@onready var right_panel_vbox_container = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer")
@onready var right_panel = get_node("VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Control2/TabContainer")
@onready var contextual_menu = get_node("%ContextualMenu")
@onready var save_confirmation_dialog = get_node("%SaveConfirmationDialog")
@onready var no_timing_map_dialog = get_node("%NoTimingMapDialog")
@onready var settings_editor_button = get_node("%EditorSettingsPopupButton")

const LOG_NAME = "HBEditor"

var playhead_position := 0
var editor_scale = 1.5 # Seconds per 500 pixels
var selected: Array = []
var copied_points: Array = []

var current_song: HBSong
var current_difficulty: String
var snap_to_grid_enabled = true

var timeline_snap_enabled = true

var undo_redo = UndoRedo.new()

var song_editor_settings: HBPerSongEditorSettings = HBPerSongEditorSettings.new()

@onready var fine_position_timer = Timer.new()

var current_notes := []

var _removed_items := [] # So we can queue_free removed nodes when freeing the editor

var playtesting := false

var _playhead_traveling := false

var hold_sizes := {}

var timing_point_creation_queue := []

var ui_module_locations = {
	"left_panel": "VBoxContainer/VSplitContainer/HSplitContainer/Control/TabContainer2",
	"right_panel": "VBoxContainer/VSplitContainer/HSplitContainer/HSplitContainer/Control2/TabContainer",
}

var modules := []
var sync_module

var timing_changes := []
var timing_map := []
var eight_map := {"times": [], "eights": []}
var signature_map := []
var metronome_map := []

var editor_hidden: bool = false

var modified: bool = false

func _sort_current_items_impl(a, b):
	return a.data.time < b.data.time

func sort_current_items():
	current_notes.sort_custom(Callable(self, "_sort_current_items_impl"))

func _insert_note_at_time_bsearch(item: EditorTimelineItem, time: int):
	return item.data.time < time

func insert_note_at_time(item: EditorTimelineItem):
	var pos = current_notes.bsearch_custom(item.data.time, self._insert_note_at_time_bsearch)
	current_notes.insert(pos, item)

func _sort_modules(a, b):
	return a.priority < b.priority

func load_modules():
	var dir := DirAccess.open(EDITOR_MODULES_DIR)
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and not file_name.begins_with("."):
				if file_name.ends_with(".tscn"):
					var module = ResourceLoader.load(EDITOR_MODULES_DIR + "/" + file_name).instantiate()
					modules.append(module)
				elif file_name.ends_with(".tscn.converted.res"):
					var module = ResourceLoader.load(EDITOR_MODULES_DIR + "/" + file_name).instantiate()
					modules.append(module)
				elif file_name.ends_with(".gd"):
					if not dir.file_exists(file_name.trim_suffix(".gd") + ".tscn") and "Module" in file_name:
						var module = ResourceLoader.load(EDITOR_MODULES_DIR + "/" + file_name).new()
						modules.append(module)
				elif file_name.ends_with(".gdc"):
					if not dir.file_exists(file_name.trim_suffix(".gdc") + ".tscn.converted.res") and "Module" in file_name:
						var module = ResourceLoader.load(EDITOR_MODULES_DIR + "/" + file_name).new()
						modules.append(module)
			
			file_name = dir.get_next()
	
	modules.sort_custom(Callable(self, "_sort_modules"))
	for module in modules:
		module.set_editor(self)

func update_shortcuts():
	for button in get_tree().get_nodes_in_group("update_shortcuts"):
		button.update_shortcuts()
	
	for module in modules:
		module.update_shortcuts()

func _ready():
	UserSettings.enable_menu_fps_limits = false
	add_child(game_playback)
	game_playback.connect("playback_speed_changed", Callable(self, "_on_playback_speed_changed"))
	game_playback.connect("time_changed", Callable(self, "_on_game_playback_time_changed"))
	Input.set_use_accumulated_input(true)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	#get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	get_window().borderless = false
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (false) else Window.MODE_WINDOWED
	get_window().mode = Window.MODE_MAXIMIZED if (true) else Window.MODE_WINDOWED
	timeline.editor = self
	timeline.set_layers_offset(0)
	add_child(fine_position_timer)
	fine_position_timer.wait_time = 0.5
	fine_position_timer.connect("timeout", Callable(self, "apply_fine_position"))
	rhythm_game.set_process_unhandled_input(false)
	rhythm_game.game_mode = HBRhythmGameBase.GAME_MODE.EDITOR_SEEK
	
	inspector.connect("properties_changed", Callable(self, "_change_selected_properties"))
	inspector.connect("property_change_committed", Callable(self, "_commit_selected_property_change"))
	inspector.connect("reset_pos", Callable(self, "reset_note_position"))
	
	# You HAVE to open a chart, this ensures that if no chart is selected we return
	# to the main menu
	open_chart_popup_dialog.get_cancel_button().connect("pressed", Callable(self, "exit"))
	open_chart_popup_dialog.close_requested.connect(self.exit)
	open_chart_popup_dialog.connect("chart_selected", Callable(self, "load_song"))
	open_chart_popup_dialog.close_requested.connect(self.reveal_ui)
	open_chart_popup_dialog.confirmed.connect(self.reveal_ui)
	rhythm_game_playtest_popup.connect("quit", Callable(self, "_on_playtest_quit"))
	editor_help_button.get_popup().connect("index_pressed", Callable(self, "_on_editor_help_button_pressed"))
	
	inspector.connect("notes_pasted", Callable(self, "paste_note_data"))
	
	MouseTrap.disable_mouse_trap()
	
	if not UserSettings.user_settings.editor_first_time_message_acknowledged:
		first_time_message_dialog.popup_centered()
	else:
		_show_open_chart_dialog()
	first_time_message_dialog.get_ok_button().text = "Got it!"
	first_time_message_dialog.get_ok_button().connect("pressed", Callable(self, "_on_acknowledge_first_time_message"))
	
	connect("timing_points_changed", Callable(self, "_cache_hold_sizes"))
	
	settings_editor.song_settings_tab.set_editor(self)
	settings_editor.general_settings_tab.set_editor(self)
	settings_editor.shortcuts_tab.set_editor(self)
	
	UserSettings.user_settings.connect("editor_grid_resolution_changed", Callable(self, "_update_grid_resolution"))
	
	connect("scale_changed", Callable(timeline, "_on_editor_scale_changed"))
	
	game_preview.connect("preview_size_changed", Callable(self, "_on_preview_size_changed"))
	
	load_modules()
	
	botton_panel_vbox_container.split_offset = UserSettings.user_settings.editor_bottom_panel_offset
	left_panel_vbox_container.split_offset = UserSettings.user_settings.editor_left_panel_offset
	right_panel_vbox_container.split_offset = UserSettings.user_settings.editor_right_panel_offset
	
	update_user_settings()
	
	Diagnostics.fps_label.add_theme_font_size_override("font_size", 11)
	Diagnostics.editor_undo_redo = undo_redo
	
	undo_redo.connect("version_changed", Callable(self, "_on_version_changed"))
	
	save_confirmation_dialog.get_ok_button().text = "Yes"
	save_confirmation_dialog.get_cancel_button().text = "Go back"
	
	settings_editor_button.connect("pressed", Callable(self, "keep_settings_button_enabled"))
	
	connect("timing_information_changed", Callable(rhythm_game, "update_bpm_map"))

const HELP_URLS = [
	"https://ph-editor.eirteam.moe/",
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
	game_preview.transform_preview.queue_redraw()
	game_preview.transform_preview.hide_timer.stop()
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
						undo_redo.add_do_method(item.data.emit_signal.bind("parameter_changed", property_name))
						undo_redo.add_do_method(item.sync_value.bind(property_name))
						
						undo_redo.add_undo_property(item.data, property_name, item.data.get(property_name))
						undo_redo.add_undo_method(item.data.emit_signal.bind("parameter_changed", property_name))
						undo_redo.add_undo_method(item.sync_value.bind(property_name))
						
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
								undo_redo.add_do_method(self.remove_item_from_layer.bind(source_layer, item))
								undo_redo.add_do_method(self.add_item_to_layer.bind(target_layer, item))
								
								undo_redo.add_undo_method(self.remove_item_from_layer.bind(target_layer, item))
								undo_redo.add_undo_method(self.add_item_to_layer.bind(source_layer, item))
						if property_name == "position":
							undo_redo.add_do_property(item.data, "pos_modified", true)
							undo_redo.add_undo_property(item.data, "pos_modified", item.data.pos_modified)
			
			undo_redo.add_do_method(item.update_widget_data)
			undo_redo.add_undo_method(item.update_widget_data)
		
		undo_redo.add_do_method(self.force_game_process)
		undo_redo.add_undo_method(self.force_game_process)
		
		undo_redo.add_do_method(self._on_timing_points_changed)
		undo_redo.add_undo_method(self._on_timing_points_changed)
		
		undo_redo.add_do_method(inspector.sync_visible_values_with_data)
		undo_redo.add_undo_method(inspector.sync_visible_values_with_data)
		
		undo_redo.commit_action()

func _show_open_chart_dialog():
	open_chart_popup_dialog.popup_centered_clamped(Vector2(600, 250))
	
func change_scale(new_scale):
	if new_scale < editor_scale and editor_scale < 1.0:
		return
	var prev_scale = editor_scale
	editor_scale = new_scale
	editor_scale = max(new_scale, 0.1)
	emit_signal("scale_changed", prev_scale, new_scale)

func get_items_at_time(time: int):
	var items = []
	for item in current_notes:
		if item.data.time == time:
			items.append(item)
		elif item.data.time > time:
			break
	return items

var konami_sequence = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]
var konami_index = 0

func _unhandled_input(event: InputEvent):
	if shortcuts_blocked():
		return
	
	if event is InputEventKey and event.pressed and not sex_button.visible:
		if event.keycode == konami_sequence[konami_index]:
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
			get_viewport().set_input_as_handled()
	
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
			get_viewport().set_input_as_handled()
	
	if event.is_action("gui_undo", true) and event.pressed:
		get_viewport().set_input_as_handled()
		apply_fine_position()
		if undo_redo.has_undo():
			if undo_redo.get_current_action_name() == "MERGE":
				# A merge action should always have an extra action before it
				undo_redo.undo()
			
			message_shower._show_notification("Undo " + undo_redo.get_current_action_name().to_lower())
			undo_redo.undo()
	
	if event.is_action("gui_redo", true) and event.pressed:
		get_viewport().set_input_as_handled()
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
	
	if not game_playback.is_playing():
		var old_pos = playhead_position
		var _timing_map = get_timing_map()
		
		if event.is_action("editor_move_playhead_left", true) and event.pressed and timing_map:
			var idx = max(_timing_map.bsearch(playhead_position) - 1, 0)
			playhead_position = _timing_map[idx]
		elif event.is_action("editor_move_playhead_right", true) and event.pressed and timing_map:
			var idx = HBUtils.bsearch_upper(_timing_map, playhead_position)
			playhead_position = _timing_map[idx]
		
		if old_pos != playhead_position:
			emit_signal("playhead_position_changed")
			timeline.ensure_playhead_is_visible()
			seek(playhead_position)
	
	if event is InputEventKey and not event.is_action_pressed("editor_play"):
		for type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
			var found_note = false
			for action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[type]:
				if event.is_action_pressed(action, false, true) or (type in [HBBaseNote.NOTE_TYPE.SLIDE_LEFT, HBBaseNote.NOTE_TYPE.SLIDE_RIGHT] and event.is_action_pressed(action)):
					var layer = null
					for layer_c in timeline.get_visible_layers():
						if layer_c.layer_name == HBUtils.find_key(HBBaseNote.NOTE_TYPE, type) + ("2" if event.shift_pressed else ""):
							layer = layer_c
							break
					
					if not layer:
						continue
					
					if selected and not game_playback.is_playing():
						undo_redo.create_action("Change selected note's type to " + HBGame.NOTE_TYPE_TO_STRING_MAP[type])
						
						for item in selected:
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
							
							new_data.set_meta("second_layer", layer.layer_name.ends_with("2"))
							
							var new_item = new_data.get_timeline_item()
							
							undo_redo.add_do_method(self.add_item_to_layer.bind(layer, new_item))
							undo_redo.add_undo_method(self.remove_item_from_layer.bind(layer, new_item))
							
							undo_redo.add_do_method(self.remove_item_from_layer.bind(item._layer, item))
							undo_redo.add_undo_method(self.add_item_to_layer.bind(item._layer, item))
						
						undo_redo.add_do_method(self.deselect_all)
						undo_redo.add_undo_method(self.deselect_all)
						
						undo_redo.add_do_method(self._on_timing_points_changed)
						undo_redo.add_undo_method(self._on_timing_points_changed)
						
						undo_redo.commit_action()
					else:
						var item_erased = false
						for item in get_items_at_time(snap_time_to_timeline(playhead_position)):
							if item is EditorTimelineItemNote and not game_playback.is_playing():
								if item.data.note_type == type and item._layer == layer:
									item_erased = true
									
									undo_redo.create_action("Remove note")
									
									undo_redo.add_do_method(self.remove_item_from_layer.bind(item._layer, item))
									undo_redo.add_undo_method(self.add_item_to_layer.bind(item._layer, item))
									
									undo_redo.add_do_method(self._on_timing_points_changed)
									undo_redo.add_undo_method(self._on_timing_points_changed)
									
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
				get_viewport().set_input_as_handled()
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
	
	points.sort_custom(Callable(self, "_note_comparison"))
	return points

func get_timeline_items() -> Array:
	var items = []
	var layers = timeline.get_layers()
	for layer in layers:
		items += layer.get_editor_items()
	return items

func scale_msec(msec: int) -> float:
	return ((msec/1000.0)/editor_scale)*500.0

# pixels to msec
func scale_pixels(pixels: float) -> float:
	return (pixels * editor_scale / 500) * 1000.0

var selected_changed := false
func notify_selected_changed():
	if not selected_changed:
		call_deferred("_notify_selected_changed_impl")
		
		selected_changed = true

func _notify_selected_changed_impl():
	info_label.text = "Timing points %d/%d" % [selected.size(), current_notes.size()]
	timeline.update_selected()
	
	for module in modules:
		module.update_selected()
	
	selected_changed = false

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
		var widget_instance = widget.instantiate() as HBEditorWidget
		widget_instance.editor = self
		game_preview.widget_area.add_child(widget_instance)
		item.connect_widget(widget_instance)
	
	selected.sort_custom(Callable(self, "_sort_current_items_impl"))
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
	
	if selected.size() == 0:
		for item in current_notes:
			selected.append(item)
			item.select()
	
	selected.sort_custom(Callable(self, "_sort_current_items_impl"))
	right_panel.current_tab = 0
	inspector.inspect(selected)
	release_owned_focus()
	notify_selected_changed()

func add_item(layer_n: int, item: EditorTimelineItem, sort_groups: bool = true):
	var layers = timeline.get_layers()
	var layer = layers[layer_n]
	
	add_item_to_layer(layer, item, sort_groups)

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
			if selected_item.data is HBBaseNote:
				selected_item.data.emit_signal("parameter_changed", property_name)
	
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
			undo_redo.add_undo_method(item.update_widget_data)
			undo_redo.add_undo_method(item.sync_value.bind("position"))
			undo_redo.add_do_property(item.data, "position", item.data.position)
			undo_redo.add_do_property(item.data, "pos_modified", true)
			undo_redo.add_do_method(item.update_widget_data)
			undo_redo.add_do_method(item.sync_value.bind("position"))
		
		fine_position_originals = {}
		
		undo_redo.add_do_method(self._on_timing_points_changed)
		undo_redo.add_undo_method(self._on_timing_points_changed)
		
		undo_redo.add_do_method(inspector.sync_visible_values_with_data)
		undo_redo.add_undo_method(inspector.sync_visible_values_with_data)
		
		undo_redo.commit_action()

func show_contextual_menu():
	contextual_menu.popup()
	var popup_offset = get_global_mouse_position() + contextual_menu.size - get_viewport_rect().size
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
			undo_redo.add_do_method(rhythm_game.editor_remove_timing_point.bind(selected_item.data))
			undo_redo.add_undo_method(rhythm_game.editor_remove_timing_point.bind(selected_item.data))
	
	var note_cache = cache_notes_at_time()
	
	var selected_cache := []
	for item in selected:
		selected_cache.append(item.data)
	
	var sync_timing := false
	var multi_check_times := []
	for selected_item in selected:
		if old_property_values.has(selected_item):
			if property_name in selected_item.data and property_name in old_property_values[selected_item]:
				if selected_item.data is HBTimingChange or selected_item.data is HBBPMChange:
					sync_timing = true
				
				if property_name == "time":
					if selected_item.data is HBSustainNote:
						if old_property_values[selected_item].has("end_time"):
							undo_redo.add_do_property(selected_item.data, "end_time", selected_item.data.end_time)
							undo_redo.add_undo_property(selected_item.data, "end_time", old_property_values[selected_item].end_time)
						else:
							var dt = selected_item.data.time - old_property_values[selected_item].time
							
							undo_redo.add_do_property(selected_item.data, "end_time", selected_item.data.end_time + dt)
							undo_redo.add_undo_property(selected_item.data, "end_time", selected_item.data.end_time)
					
					if selected_item.data is HBBaseNote and UserSettings.user_settings.editor_auto_place and not selected_item.data.pos_modified:
						var new_data = autoplace(selected_item.data, false, selected_cache, note_cache)
						
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
				undo_redo.add_do_method(selected_item.data.emit_signal.bind("parameter_changed", property_name))
				undo_redo.add_do_method(selected_item._layer.place_child(selected_item))
				
				undo_redo.add_undo_property(selected_item.data, property_name, old_property_values[selected_item][property_name])
				undo_redo.add_undo_method(selected_item.data.emit_signal.bind("parameter_changed", property_name))
				undo_redo.add_undo_method(selected_item._layer.place_child.bind(selected_item))
				
				undo_redo.add_do_method(selected_item.update_widget_data)
				undo_redo.add_do_method(selected_item.sync_value.bind(property_name))
				
				undo_redo.add_undo_method(selected_item.update_widget_data)
				undo_redo.add_undo_method(selected_item.sync_value.bin(property_name))
			
			old_property_values[selected_item].erase(property_name)

	undo_redo.add_do_method(inspector.sync_visible_values_with_data)
	undo_redo.add_undo_method(inspector.sync_visible_values_with_data)
	undo_redo.add_do_method(self.sync_lyrics)
	undo_redo.add_undo_method(self.sync_lyrics)
	
	if property_name == "time":
		undo_redo.add_do_method(self.sort_current_items)
		
		for selected_item in selected:
			undo_redo.add_do_method(rhythm_game.editor_add_timing_point.bind(selected_item.data))
			undo_redo.add_undo_method(rhythm_game.editor_add_timing_point.bind(selected_item.data))
		
		undo_redo.add_do_method(self._cache_hold_sizes)
		undo_redo.add_undo_method(self._cache_hold_sizes)
	elif property_name == "hold":
		undo_redo.add_do_method(self._cache_hold_sizes)
		undo_redo.add_undo_method(self._cache_hold_sizes)
	
	undo_redo.add_do_method(self.force_game_process)
	undo_redo.add_undo_method(self.force_game_process)
	
	if sync_timing:
		undo_redo.add_do_method(self._on_timing_information_changed)
		undo_redo.add_undo_method(self._on_timing_information_changed)
		
		undo_redo.add_do_method(self._on_timing_points_changed)
		undo_redo.add_undo_method(self._on_timing_points_changed)
	
	if create_action:
		undo_redo.commit_action()
		
		var item_cache = cache_items_at_time()
		check_for_multi_changes(multi_check_times, item_cache)
	
	release_owned_focus()

# Handles when a user changes a timing point's property, this is used for properties
# that won't constantly change
func _on_timing_point_property_changed(property_name: String, old_value, new_value, child: EditorTimelineItem, affects_timing_points = false):
	var action_name = "Note " + property_name + " changed"
	undo_redo.create_action(action_name)
	
	undo_redo.add_do_property(child.data, property_name, new_value)
	undo_redo.add_do_method(child._layer.place_child.bind(child))
	
	undo_redo.add_undo_property(child.data, property_name, old_value)
	undo_redo.add_undo_method(child._layer.place_child.bind(child))
	
	if property_name == "position":
		undo_redo.add_do_method(child.update_widget_data)
		undo_redo.add_undo_method(child.update_widget_data)
	
	if  property_name == "bpm" or property_name == "time_signature" or \
		(property_name == "time" and child.data is HBTimingChange):
		undo_redo.add_do_method(self._on_timing_information_changed)
		undo_redo.add_undo_method(self._on_timing_information_changed)
	
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
					l._drop_data(null, selected)
					break

func add_item_to_layer(layer: EditorLayer, item: EditorTimelineItem, sort_groups: bool = true):
	if item.update_affects_timing_points:
		if not item.is_connected("property_changed", Callable(self, "_on_timing_point_property_changed")):
			item.connect("property_changed", Callable(self, "_on_timing_point_property_changed").bind(item, true))
	else:
		if not item.is_connected("property_changed", Callable(self, "_on_timing_point_property_changed")):
			item.connect("property_changed", Callable(self, "_on_timing_point_property_changed").bind(item))
	
	insert_note_at_time(item)
	layer.add_item(item)
	if item in _removed_items:
		_removed_items.erase(item)
	
	rhythm_game.editor_add_timing_point(item.data, sort_groups)
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
	
	# HACK: Far along in a song, float innacuracies might start fucking us up, because
	# for some reason stuff gets converted to floats along the way. playhead_position is
	# always integer, so if they are similar just prefer the int variant as a truth source
	if abs(prev_time / 1000.0 - time) > 0.001:
		playhead_position = max(time * 1000.0, 0.0)
	
	timeline.queue_redraw()
	
	if game_playback.is_playing():
		timeline.ensure_playhead_is_visible()
		var playback_offset_with_ln = (timeline.size.x / 2.0)
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
		call_deferred("_seek", value / 1000.0)
	elif not game_playback.is_playing():
		game_preview.set_time(value / 1000.0)
	else:
		game_preview.play_at_pos(value / 1000.0)

func _seek(value: float):
	game_preview.set_time(value)
	
	pause()
	play_button.show()
	pause_button.hide()
	emit_signal("paused")

func copy_selected():
	if selected.size() > 0:
		copied_points = []
		for item in selected:
			var timing_point_timeline_item = item as EditorTimelineItem
			var cloned_item = timing_point_timeline_item.data.clone().get_timeline_item()
			cloned_item._layer = timing_point_timeline_item._layer
			copied_points.append({"item": cloned_item, "layer_name": cloned_item._layer.layer_name})
	
	notify_selected_changed()

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
			
			undo_redo.add_do_method(self.add_item_to_layer.bind(timeline_item._layer, new_item))
			undo_redo.add_undo_method(self.remove_item_from_layer.bind(timeline_item._layer, new_item))
			
			if copy.item is EditorSectionTimelineItem:
				sync_timing = true
			
			if not multi_check_times.has(timing_point.time):
				multi_check_times.append(timing_point.time)
		
		if sync_timing:
			undo_redo.add_do_method(timeline.queue_redraw)
			undo_redo.add_undo_method(timeline.queue_redraw)
		
		undo_redo.add_do_method(self._on_timing_points_changed)
		undo_redo.add_undo_method(self._on_timing_points_changed)
		undo_redo.add_do_method(self.sync_lyrics)
		undo_redo.add_undo_method(self.sync_lyrics)
		
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
		
		undo_redo.add_do_method(self.deselect_all)
		undo_redo.add_undo_method(self.deselect_all)
		
		var first := true
		var sync_timing := false
		var deleted_times := []
		for selected_item in selected:
			selected_item.deselect()
			
			undo_redo.add_do_method(self.remove_item_from_layer.bind(selected_item._layer, selected_item))
			undo_redo.add_undo_method(self.add_item_to_layer.bind(selected_item._layer, selected_item))
			
			if selected_item is EditorSectionTimelineItem:
				undo_redo.add_do_method(timeline.queue_redraw)
				undo_redo.add_undo_method(timeline.queue_redraw)
			
			if selected_item.data is HBTimingChange:
				sync_timing = true
			
			if not deleted_times.has(selected_item.data.time):
				deleted_times.append(selected_item.data.time)
			
			undo_redo.add_undo_method(self.select_item.bind(selected_item, not first))
			
			if first:
				first = false
		
		undo_redo.add_do_method(self._on_timing_points_changed)
		undo_redo.add_undo_method(self._on_timing_points_changed)
		
		undo_redo.add_do_method(self.sync_lyrics)
		undo_redo.add_undo_method(self.sync_lyrics)
		
		if sync_timing:
			undo_redo.add_do_method(self._on_timing_information_changed)
			undo_redo.add_undo_method(self._on_timing_information_changed)
		
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

func check_for_multi_changes(times: Array, item_cache: Array = []):
	if UserSettings.user_settings.editor_auto_multi:
		# Merge action with the previous one
		undo_redo.create_action("MERGE")
		
		for time in times:
			var items_at_time := []
			if item_cache:
				items_at_time = item_cache[time]
			else:
				items_at_time = get_items_at_time(time)
			
			var notes_at_time := []
			for item in items_at_time:
				if item.data is HBBaseNote:
					item.data.set_meta("timeline_item", item)
					notes_at_time.append(item.data)
			
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
				
				undo_redo.add_do_method(note.get_meta("timeline_item").update_widget_data)
				undo_redo.add_undo_method(note.get_meta("timeline_item").update_widget_data)
			
			# Set correct multi angles
			_set_multi_angles(notes_at_time)
			
			for note in notes_at_time:
				for property_name in ["position", "entry_angle", "oscillation_frequency", "oscillation_amplitude", "distance"]:
					undo_redo.add_do_method(note.emit_signal.bind("parameter_changed", property_name))
					undo_redo.add_undo_method(note.emit_signal.bind("parameter_changed", property_name))
		
		undo_redo.add_do_method(self._on_timing_points_changed)
		undo_redo.add_undo_method(self._on_timing_points_changed)
		
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
	if note.oscillation_amplitude == 0:
		undo_redo.add_do_property(note, "oscillation_amplitude", 500)
		undo_redo.add_undo_property(note, "oscillation_amplitude", note.oscillation_amplitude)
	
	if note.distance == 880:
		undo_redo.add_do_property(note, "distance", 1200)
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
	notes.sort_custom(Callable(self, "_sort_by_multi_pos"))
	
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

func get_notes_at_time(time: int) -> Array:
	var notes := []
	
	for note in get_timing_points():
		if note is HBTimingPoint:
			if note.time == time:
				notes.append(note)
	
	return notes

func cache_notes_at_time() -> Dictionary:
	var cache = {}
	
	for note in get_timing_points():
		if note is HBTimingPoint:
			if note.time in cache:
				cache[note.time].append(note)
			else:
				cache[note.time] = [note]
	
	return cache

func cache_items_at_time() -> Array:
	# Initialize our cache
	var cache := []
	cache.resize(int(get_song_length() * 1000.0))
	cache.fill([])
	
	for item in get_timeline_items():
		if item.data is HBTimingPoint and item.data.time <= int(get_song_length() * 1000.0):
			if not cache[item.data.time]:
				cache[item.data.time] = [item]
			else:
				cache[item.data.time].append(item)
	
	return cache

func user_create_timing_point(layer: EditorLayer, item: EditorTimelineItem, force: bool = false):
	if not timing_map and not force:
		no_timing_map_dialog.popup_centered()
		return
	
	undo_redo.create_action("Add new timing point")
	
	if item.data is HBBaseNote and UserSettings.user_settings.editor_auto_place:
		item.data = autoplace(item.data)
	
	item.data.set_meta("second_layer", layer.layer_name.ends_with("2"))
	
	undo_redo.add_do_method(self.add_item_to_layer.bind(layer, item))
	undo_redo.add_undo_method(self.remove_item_from_layer.bind(layer, item))
	undo_redo.add_undo_method(self.deselect_item.bind(item))
	
	undo_redo.add_do_method(self._on_timing_points_changed)
	undo_redo.add_undo_method(self._on_timing_points_changed)
	
	if item is EditorSectionTimelineItem:
		undo_redo.add_do_method(timeline.queue_redraw)
		undo_redo.add_undo_method(timeline.queue_redraw)
	
	if item.data is HBTimingChange:
		undo_redo.add_do_method(self._on_timing_information_changed)
		undo_redo.add_undo_method(self._on_timing_information_changed)
	
	undo_redo.commit_action()
	
	check_for_multi_changes([item.data.time])

func remove_item_from_layer(layer: EditorLayer, item: EditorTimelineItem):
	layer.remove_item(item)
	current_notes.erase(item)
	_removed_items.append(item)
	
	rhythm_game.editor_remove_timing_point(item.data)
	force_game_process()

func pause():
	game_playback.pause()
	game_preview.set_visualizer_processing_enabled(false)
	game_preview.widget_area.show()
	
	if not UserSettings.user_settings.editor_smooth_scroll:
		playhead_position = snap_time_to_timeline(playhead_position)
		seek(playhead_position)

	emit_signal("playhead_position_changed")
	playback_speed_slider.editable = true
	
	game_preview.pause()
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
	playback_speed_slider.editable = false
	obscure_ui(false)
	
	game_preview.set_visualizer_processing_enabled(true)
	game_preview.widget_area.hide()
	game_preview.widget_area.deselect_all()


# Fired when any timing point tells the game to rethink its existence
func _on_timing_points_changed():
	_on_PauseButton_pressed(true)
	timeline.send_time_cull_changed_signal()
	emit_signal("timing_points_changed")

func _on_timing_points_params_changed():
	game_playback._on_timing_params_changed()
	game_playback.seek(playhead_position)

func get_song_length():
	if game_playback.game.audio_playback:
		return game_playback.game.audio_playback.get_length_msec() / 1000.0
	else:
		return 60.0

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
	_on_PauseButton_pressed()
	
	if song_editor_settings.is_connected("property_changed", Callable(self, "emit_signal")):
		song_editor_settings.disconnect("property_changed", Callable(self, "emit_signal"))
	
	song_editor_settings = settings
	for layer in timeline.get_layers():
		var layer_visible = not layer.layer_name in settings.hidden_layers
		timeline.change_layer_visibility(layer_visible, layer.layer_name)
	
	emit_signal("timing_information_changed")
	song_editor_settings.connect("property_changed", Callable(self, "emit_signal").bind("song_editor_settings_changed"))
	
	song_settings_editor.load_settings(settings)
	update_media()
	
	timeline_snap_button.button_pressed = settings.timeline_snap
	
	game_preview.settings = settings
	show_bg_button.button_pressed = settings.show_bg
	show_video_button.button_pressed = settings.show_video
	
	_on_playback_speed_changed(playback_speed_slider.value)
	
	if not skip_settings_menu:
		emit_signal("song_editor_settings_changed")
	
	emit_signal("modules_update_settings", settings)

func update_user_settings():
	waveform_button.button_pressed = UserSettings.user_settings.editor_show_waveform
	
	grid_snap_button.button_pressed = UserSettings.user_settings.editor_grid_snap
	show_grid_button.button_pressed = UserSettings.user_settings.editor_show_grid
	grid_x_spinbox.value = UserSettings.user_settings.editor_grid_resolution.x
	grid_y_spinbox.value = UserSettings.user_settings.editor_grid_resolution.y
	
	game_playback.set_velocity(playback_speed_slider.value, UserSettings.user_settings.editor_pitch_compensation)
	
	emit_signal("modules_update_user_settings")

func from_chart(chart: HBChart, ignore_settings = false, importing = false, in_place = false):
	if not in_place:
		timeline.clear_layers()
		song_settings_editor.clear_layers()
		rhythm_game.editor_clear_notes()
	
	if not importing:
		undo_redo.clear_history()
	
	selected = []
	current_notes = []
	timeline.send_time_cull_changed_signal()
	
	for layer in chart.layers:
		var layer_scene
		var layer_n
		if not in_place:
			layer_scene = EDITOR_LAYER_SCENE.instantiate()
			layer_scene.layer_name = layer.name
			
			timeline.add_layer(layer_scene)
			layer_n = timeline.get_layers().size()-1
		else:
			layer_scene = timeline.find_layer_by_name(layer.name)
			layer_n = timeline.get_layers().find(layer_scene)
		
		for item_d in layer.timing_points:
			var item = item_d.get_timeline_item()
			item.data = item_d
			
			add_item(layer_n, item, false)
			
			if item_d is HBSustainNote:
				item.sync_value("end_time")
			
			if in_place:
				selected.append(item)
				item.select()
		
		if not in_place:
			var layer_visible = not layer.name in song_editor_settings.hidden_layers
			if not ignore_settings:
				layer_visible = not layer.name in chart.editor_settings.hidden_layers
			
			song_settings_editor.add_layer(layer.name, layer_visible)
			timeline.change_layer_visibility(layer_visible, layer.name)
	
	if not in_place:
		# Lyrics layer
		var lyrics_layer_scene = EDITOR_LAYER_SCENE.instantiate()
		lyrics_layer_scene.layer_name = "Lyrics"
		var lyrics_layer_visible = not "Lyrics" in song_editor_settings.hidden_layers
		if not ignore_settings:
			lyrics_layer_visible = not "Lyrics" in chart.editor_settings.hidden_layers
		
		timeline.add_layer(lyrics_layer_scene)
		timeline.change_layer_visibility(lyrics_layer_visible, lyrics_layer_scene.layer_name)
		song_settings_editor.add_layer("Lyrics", lyrics_layer_visible)
		
		# Sections layer
		var sections_layer_scene = EDITOR_LAYER_SCENE.instantiate()
		sections_layer_scene.layer_name = "Sections"
		var sections_layer_visible = not "Sections" in song_editor_settings.hidden_layers
		if not ignore_settings:
			sections_layer_visible = not "Sections" in chart.editor_settings.hidden_layers
		
		timeline.add_layer(sections_layer_scene)
		timeline.change_layer_visibility(sections_layer_visible, sections_layer_scene.layer_name)
		song_settings_editor.add_layer("Sections", sections_layer_visible)
		
		# Timing changes layer
		var tempo_layer_scene = EDITOR_LAYER_SCENE.instantiate()
		tempo_layer_scene.layer_name = "Tempo Map"
		var tempo_layer_visible = not "Tempo Map" in song_editor_settings.hidden_layers
		if not ignore_settings:
			tempo_layer_visible = not "Tempo Map" in chart.editor_settings.hidden_layers
		
		timeline.add_layer(tempo_layer_scene)
		timeline.change_layer_visibility(tempo_layer_visible, tempo_layer_scene.layer_name)
		song_settings_editor.add_layer(tempo_layer_scene.layer_name, tempo_layer_visible)
	
		var layers = timeline.get_layers()
		var lyrics_layer_n = layers.size() - 3
		var sections_layer_n = layers.size() - 2
		var tempo_layer_n = layers.size() - 1
		
		for phrase in current_song.lyrics:
			if phrase is HBLyricsPhrase:
				var start_item = HBLyricsPhraseStart.new()
				start_item.time = phrase.time
				add_item(lyrics_layer_n, start_item.get_timeline_item(), false)
				
				for lyric in phrase.lyrics:
					if lyric is HBLyricsLyric:
						add_item(lyrics_layer_n, lyric.get_timeline_item(), false)
				
				var end_item = HBLyricsPhraseEnd.new()
				end_item.time = phrase.end_time
				add_item(lyrics_layer_n, end_item.get_timeline_item(), false)
		
		for section in current_song.sections:
			if section is HBChartSection:
				add_item(sections_layer_n, section.get_timeline_item(), false)
		
		for timing_change in current_song.timing_changes:
			if timing_change is HBTimingChange:
				add_item(tempo_layer_n, timing_change.get_timeline_item(), false)
	
	if not ignore_settings:
		load_settings(chart.editor_settings)
	
	_on_timing_points_changed()
	_on_timing_information_changed()
	
	# Disconnect the cancel action in the chart open dialog, because we already have at least
	# a chart loaded
	if open_chart_popup_dialog.get_cancel_button().is_connected("pressed", Callable(self, "exit")):
		open_chart_popup_dialog.get_cancel_button().disconnect("pressed", Callable(self, "exit"))
		open_chart_popup_dialog.disconnect("close_requested", Callable(self, "exit"))
	
	if not in_place:
		deselect_all()
	else:
		selected.sort_custom(Callable(self, "_sort_current_items_impl"))
		notify_selected_changed() 
	
	sync_lyrics()
	sort_groups()
	force_game_process()

func paste_note_data(notes: Array):
	undo_redo.create_action("Paste note data")
	
	for i in selected.size():
		var selected_item = selected[i]
		
		if selected_item.data is HBBaseNote:
			var new_data = notes[i % notes.size()].clone()
			new_data.note_type = selected_item.data.note_type
			new_data.time = selected_item.data.time
			
			if selected_item.data is HBSustainNote and new_data is HBSustainNote:
				new_data.end_time = selected_item.data.end_time
			
			for property in new_data.get_inspector_properties():
				if selected_item.data.get(property) != null:  # HACK: There is no Object.has() method :/
					undo_redo.add_do_property(selected_item.data, property, new_data.get(property))
					undo_redo.add_undo_property(selected_item.data, property, selected_item.data.get(property))
					
					undo_redo.add_do_method(selected_item.data.emit_signal.bind("parameter_changed", property))
					undo_redo.add_do_method(selected_item.sync_value.bind(property))
					
					undo_redo.add_undo_method(selected_item.data.emit_signal.bind("parameter_changed", property))
					undo_redo.add_undo_method(selected_item.sync_value.bind(property))
			
			undo_redo.add_do_method(selected_item.update_widget_data)
			undo_redo.add_undo_method(selected_item.update_widget_data)
	
	undo_redo.add_do_method(self._on_timing_points_changed)
	undo_redo.add_undo_method(self._on_timing_points_changed)
	
	undo_redo.add_do_method(self.force_game_process)
	undo_redo.add_undo_method(self.force_game_process)
	
	undo_redo.add_do_method(inspector.sync_visible_values_with_data)
	undo_redo.add_undo_method(inspector.sync_visible_values_with_data)
	
	undo_redo.commit_action()

	force_game_process()

func _on_SaveSongSelector_chart_selected(song_id, difficulty):
	if editor_hidden:
		return
	
	var song = SongLoader.songs[song_id]
	var chart_path = song.get_chart_path(difficulty)
	
	var data = serialize_chart()
	if not data:
		print("ERROR: Data was not serialized.")
		return
	
	var json = JSON.stringify(data, "  ")
	if not json:
		print("ERROR: Data could not be formatted as json.")
		return
	
	var file = FileAccess.open(chart_path, FileAccess.WRITE)
	file.store_string(json)

func load_song(song: HBSong, difficulty: String, p_hidden: bool):
	deselect_all()
	
	editor_hidden = p_hidden
	current_song = song
	
	var chart = current_song.get_chart_for_difficulty(difficulty)
	
	HBGame.rich_presence.update_activity({
		"state": "In editor",
		"details": current_song.title,
		"start_timestamp": Time.get_unix_time_from_system()
	})
	
	add_child(rhythm_game_playtest_popup)
	rhythm_game_playtest_popup.rhythm_game.audio_playback = null
	rhythm_game_playtest_popup.rhythm_game.voice_audio_playback = null
	remove_child(rhythm_game_playtest_popup)
	
	timeline.set_layers_offset(0)
	playback_speed_slider.value = 1.0
	
	get_window().set_title("Project Heartbeat - " + song.get_visible_title() + " - " + difficulty.capitalize())
	current_title_button.text = "%s (%s)" % [song.get_visible_title(), difficulty.capitalize()]
	from_chart(chart)
	current_difficulty = difficulty
	current_difficulty = difficulty
	
	save_button.disabled = editor_hidden
	save_as_button.disabled = editor_hidden
	
	modified = false
	
	change_scale(editor_scale)
	seek(0, true)
	if timing_changes:
		playhead_position = timing_changes[-1].data.time
		
		timeline.ensure_playhead_is_visible()
		seek(playhead_position)

func get_selected_variant() -> int:
	if !current_song.is_cached(song_editor_settings.selected_variant):
		return -1
	else:
		return song_editor_settings.selected_variant
func update_media():
	game_preview.set_song(current_song, get_selected_variant())
	game_playback.set_song(current_song, get_selected_variant())
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
	print("REVEAL UI", extended)
	print_stack()
	for control in get_tree().get_nodes_in_group("disabled_ui"):
		if control is BaseButton:
			control.disabled = false
		if control is LineEdit or control is Range:
			control.editable = true
		if control is SpinBox:
			control.get_line_edit().editable = true
	
	save_button.disabled = editor_hidden
	save_as_button.disabled = editor_hidden
	
	if not extended:
		notify_selected_changed()
		return
	
	for control in get_tree().get_nodes_in_group("extended_disabled_ui"):
		if control is BaseButton:
			control.disabled = false
		if control is LineEdit or control is Range:
			control.editable = true
		if control is SpinBox:
			control.get_line_edit().editable = true
	
	notify_selected_changed()

func exit():
	get_tree().change_scene_to_packed(load("res://menus/MainMenu3D.tscn"))
	
	get_window().mode = Window.MODE_MAXIMIZED if (false) else Window.MODE_WINDOWED
	UserSettings.apply_display_mode()
	
	Diagnostics.fps_label.add_theme_font_size_override("font_size", 23)
	Diagnostics.editor_undo_redo = null

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
	return eight_map.times

func get_signature_map() -> Array:
	return signature_map

func get_metronome_map() -> Array:
	return metronome_map

# We need to go the long way round to prevent weird rounding issues
func map_intervals(obj: Array, start: int, end: int, interval: float):
	if interval == 0:
		return
	
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
	signature_map.clear()
	metronome_map.clear()
	
	eight_map.times.clear()
	eight_map.eights.clear()
	
	for item in get_timeline_items():
		if item.data is HBTimingChange:
			timing_changes.append(item)
	
	timing_changes.sort_custom(Callable(self, "_sort_current_items_impl"))
	timing_changes.reverse()
	
	var end_t = get_song_length() * 1000
	for item in timing_changes:
		var timing_change = item.data as HBTimingChange
		
		var ms_per_beat: float = (60.0 / timing_change.bpm) * 1000.0 * 4 * get_note_resolution()
		map_intervals(timing_map, timing_change.time, end_t, ms_per_beat)
		
		if timing_change.time_signature.denominator != 0:
			var ms_per_bar: float = (60.0 / timing_change.bpm) * 1000.0 * \
				4 * (float(timing_change.time_signature.numerator) / float(timing_change.time_signature.denominator))
			map_intervals(signature_map, timing_change.time, end_t, ms_per_bar)
			
			var ms_per_metronome_beat: float = (60.0 / timing_change.bpm) * 1000.0 * \
				4 * (1 / float(timing_change.time_signature.denominator))
			map_intervals(metronome_map, timing_change.time, end_t, ms_per_metronome_beat)
		
		end_t = timing_change.time
	
	if timing_changes:
		var ms_per_beat: float = (60.0 / timing_changes[-1].data.bpm) * 1000.0 * 4 * get_note_resolution()
		
		var end = timing_changes[-1].data.time
		for i in range(0, end / ms_per_beat + 1):
			timing_map.append(int(end - (i - 1) * ms_per_beat))
	
	timing_map.reverse()
	signature_map.reverse()
	
	# The eight map consists of 2 arrays, one which holds a time and one which
	# holds its corresponding "eight index". This allows us to efficiently store
	# this info for arranging, and to deal with edge cases like the index of
	# tempo changes, which is crucial for correct arranging across tempo
	# boundaries.
	
	if timing_changes:
		eight_map.times.append(timing_changes[-1].data.time)
		eight_map.eights.append(0)
	
	var eight = 0
	for i in range(timing_changes.size() - 1, -1, -1):
		var timing_change = timing_changes[i]
		
		end_t = timing_changes[i - 1].data.time if i != 0 else get_song_length() * 1000.0
		var start_t = timing_change.data.time
		
		var ms_per_eight: float = (60.0 / timing_change.data.bpm) * 1000.0 * 4 / 8.0
		var eight_count: int = floor((end_t - start_t) / ms_per_eight)
		
		for j in range(1, eight_count):
			eight_map.times.append(start_t + j * ms_per_eight)
			eight_map.eights.append(eight + j)
		
		eight += eight_count
		
		var end_eight_t = timing_change.data.time + ms_per_eight * eight_count
		var next_eight_t = timing_change.data.time + ms_per_eight * (eight_count + 1)
		var w = inverse_lerp(end_eight_t, next_eight_t, end_t)
		
		eight += w
		eight_map.times.append(end_t)
		eight_map.eights.append(eight)
	
	release_owned_focus()
	timeline.queue_redraw()
	emit_signal("timing_information_changed")


func _on_SaveButton_pressed():
	if editor_hidden:
		return
	
	var chart_path = current_song.get_chart_path(current_difficulty)
	var chart = get_chart()
	
	var data = chart.serialize()
	if not data:
		print("ERROR: Data was not serialized.")
		return
	
	var json = JSON.stringify(data, "  ")
	if not json:
		print("ERROR: Data could not be formatted as json.")
		return
	
	var file = FileAccess.open(chart_path, FileAccess.WRITE)
	file.store_string(json)
	file.close()
	
	var new_timing_changes = []
	for item in get_timing_changes():
		new_timing_changes.append(item.data)
	
	current_song.timing_changes = new_timing_changes
	
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
		var idx = HBUtils.bsearch_closest(map, time)
		idx = min(idx, map.size() - 1)
		
		return map[idx]
	else:
		return time

func _on_layer_visibility_changed(visibility: bool, layer_name: String):
	song_editor_settings.set_layer_visibility(visibility, layer_name)
	if layer_name == "Sections":
		timeline.queue_redraw()

# PLAYTEST SHIT
func _on_PlaytestButton_pressed(at_time):
	if UserSettings.user_settings.editor_autosave_enabled and modified:
		_on_SaveButton_pressed()
	
	#TODOGD4
	#get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920, 1080))
	_on_PauseButton_pressed()
	rhythm_game.set_process_input(false)
	playtesting = true
	add_child(rhythm_game_playtest_popup)
	$VBoxContainer.hide()
	var play_time = 0.0
	if at_time:
		play_time = playhead_position
	rhythm_game_playtest_popup.set_audio(current_song, game_playback.audio_source, game_playback.voice_source, get_selected_variant())
	rhythm_game_playtest_popup.set_velocity(playback_speed_slider.value, UserSettings.user_settings.editor_pitch_compensation)
	
	rhythm_game_playtest_popup.play_song_from_position(current_song, get_chart(), current_difficulty, play_time / 1000.0, song_editor_settings.show_bg, song_editor_settings.show_video)
	
	Diagnostics.fps_label.add_theme_font_size_override("font_size", 23)

func _on_playtest_quit():
	#TODOGD4
	#get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	playtesting = false
	$VBoxContainer.show()
	remove_child(rhythm_game_playtest_popup)
	game_playback._on_timing_params_changed()
	rhythm_game.set_process_input(true)
	
	Diagnostics.fps_label.add_theme_font_size_override("font_size", 11)


func _chronological_compare(a, b):
	return a.time < b.time

func get_lyrics():
	var phrases = []
	
	for layer in timeline.get_layers():
		if layer.layer_name == "Lyrics":
			var is_inside_phrase = false
			var curr_phrase: HBLyricsPhrase
			
			var points = layer.get_timing_points()
			points.sort_custom(Callable(self, "_chronological_compare"))
			
			for i in range(points.size()):
				if i < points.size() - 1:
					var p1 = points[i]
					var p2 = points[i+1]
					
					# Mantain a reasonable order if 2 points have the same time
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
			points.sort_custom(Callable(self, "_chronological_compare"))
			
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
	
	if data in hold_sizes:
		return hold_sizes[data]
	
	return HBRhythmGame.MAX_HOLD

func _cache_hold_sizes():
	if not UserSettings.user_settings.editor_show_hold_calculator:
		return
	
	var points = get_timing_points()
	points.reverse()
	hold_sizes.clear()
	
	var held_notes := {}
	for type in HBBaseNote.NOTE_TYPE:
		held_notes[HBBaseNote.NOTE_TYPE[type]] = null
	
	for point in points:
		# Get last held note
		var last_note = null
		for held_note in held_notes.values():
			if held_note:
				if not last_note:
					last_note = held_note
					continue
				
				if held_note.time > last_note.time:
					last_note = held_note
		
		if last_note and (last_note.time + HBRhythmGame.MAX_HOLD) < point.time:
			# Max out holds
			var end_time = last_note.time + HBRhythmGame.MAX_HOLD
			
			for type in held_notes.keys():
				var held_note = held_notes[type]
				
				if held_note:
					hold_sizes[held_note] = end_time - held_note.time
					held_notes[type] = null
		
		if point is HBBaseNote:
			if point.note_type in held_notes and held_notes[point.note_type]:
				# Break holds
				for type in held_notes.keys():
					var held_note = held_notes[type]
					
					if held_note:
						var size = point.time - held_note.time
						
						hold_sizes[held_note] = size
						held_notes[type] = null
		
		if point is HBNoteData and point.hold:
			# Hold note down
			held_notes[point.note_type] = point
	
	# The last few notes might still be held
	
	# Get last held note
	var last_note = null
	for held_note in held_notes.values():
		if held_note:
			if not last_note:
				last_note = held_note
				continue
			
			if held_note.time > last_note.time:
				last_note = held_note
	
	if last_note:
		# Max out holds
		var end_time = min(last_note.time + HBRhythmGame.MAX_HOLD, get_song_length() * 1000.0)
		
		for type in held_notes.keys():
			var held_note = held_notes[type]
			
			if held_note:
				hold_sizes[held_note] = end_time - held_note.time
				held_notes[type] = null
	
	# Update items
	for item in get_timeline_items():
		if item.data is HBNoteData and item.data.hold:
			item.queue_redraw()


func autoplace(data: HBBaseNote, force: bool = false, selected_data: Array = [], times_cache: Dictionary = {}):
	if not data.position.y in [630, 726, 822, 918] and data.position != Vector2(960, 540) and not force:
		# Safeguard against modifying old charts
		data.pos_modified = true
		return data.clone()
	
	if not data is HBBaseNote:
		return
	var new_data = data.clone() as HBBaseNote
	
	var time_as_eight = get_time_as_eight(data.time)
	time_as_eight = fmod(time_as_eight, 15.0)
	if time_as_eight < 0:
		time_as_eight = fmod(15.0 - abs(time_as_eight), 15.0)
	
	var notes_at_time := []
	if data.time in times_cache:
		notes_at_time = times_cache[data.time]
	else:
		notes_at_time = get_notes_at_time(data.time)
		times_cache[data.time] = notes_at_time
	
	if not selected_data:
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
		
		new_data.oscillation_amplitude = abs(new_data.oscillation_amplitude)
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
			item.queue_redraw()


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
	
	game_playback.set_velocity(value, UserSettings.user_settings.editor_pitch_compensation)

func _on_playback_speed_changed(speed: float):
	if speed == 1.0:
		if song_editor_settings.show_video:
			game_preview.video_player.stream_position = playhead_position / 1000.0
			game_preview.update_bga()
	else:
		if song_editor_settings.show_video:
			game_preview.update_bga(true)


func queue_timing_point_creation(layer, timing_point):
	if not timing_map:
		_on_PauseButton_pressed(true)
		no_timing_map_dialog.popup_centered()
		return
	
	for entry in timing_point_creation_queue:
		if entry.timing_point.time == timing_point.time and \
		   entry.timing_point.note_type == timing_point.note_type:
			return
	
	var item = timing_point.get_timeline_item()
	timing_point_creation_queue.append({"layer": layer, "timing_point": timing_point, "item": item})
	
	insert_note_at_time(item)
	layer.add_item(item)
	if item in _removed_items:
		_removed_items.erase(item)

func create_queued_timing_points():
	for entry in timing_point_creation_queue:
		entry.layer.remove_item(entry.item)
		current_notes.erase(entry.item)
		_removed_items.append(entry.item)
		
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
		
		undo_redo.add_do_method(item.update_widget_data)
		undo_redo.add_undo_method(item.update_widget_data)
		
		if not check_multi_times.has(item.data.time):
			check_multi_times.append(item.data.time)
	
	undo_redo.add_do_method(inspector.sync_visible_values_with_data)
	undo_redo.add_undo_method(inspector.sync_visible_values_with_data)
	
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

func sort_groups():
	rhythm_game._editor_sort_groups()

func _on_Sfx_toggled(button_pressed: bool):
	rhythm_game.sfx_enabled = button_pressed

func _toggle_settings_popup():
	if settings_editor.visible:
		settings_editor.hide()
	else:
		settings_editor.popup_centered()

func shortcuts_blocked() -> bool:
	if rhythm_game_playtest_popup in get_children():
		return true
	
	for control in get_tree().get_nodes_in_group("block_shortcuts"):
		if control is Control and control.is_visible_in_tree():
			return true
		if control is Window and control.is_visible():
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

func keep_settings_button_enabled():
	settings_editor_button.disabled = false

func _toggle_layer_visibility_editor():
	_toggle_settings_popup()
	
	settings_editor.tab_container.current_tab = 1
	song_settings_editor.tree.scroll_to_item(song_settings_editor.layers_item)
	song_settings_editor.layers_item.select(0)

func set_resolution(index):
	sync_module.set_resolution(index)

func get_speed_changes() -> Array:
	var bpm_changes = game_preview.game.bpm_changes
	var tempo_changes = game_preview.game.timing_changes
	
	var speed_changes = bpm_changes.duplicate()
	speed_changes.append_array(tempo_changes)
	speed_changes.sort_custom(Callable(self, "_chronological_compare"))
	
	return speed_changes

func get_time_as_eight(time: int) -> float:
	if not eight_map.times:
		return 0.0
	
	var idx: int = eight_map.times.bsearch(time)
	
	if eight_map.times[idx] == time:
		return eight_map.eights[idx]
	
	var lower_bound = idx - 1
	var upper_bound = idx
	
	if idx == eight_map.times.size():
		lower_bound = idx - 2
		upper_bound = idx - 1
	elif idx == 0:
		lower_bound = idx
		upper_bound = idx + 1
	
	var w := inverse_lerp(eight_map.times[lower_bound], eight_map.times[upper_bound], time)
	var eight = lerp(eight_map.eights[lower_bound], eight_map.eights[upper_bound], w)
	
	return eight
