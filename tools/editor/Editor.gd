extends Control

class_name HBEditor

signal scale_changed(prev_scale, scale)
signal playhead_position_changed
signal load_song(song)
signal timing_information_changed
signal timing_points_changed
const EDITOR_LAYER_SCENE = preload("res://tools/editor/EditorLayer.tscn")
const EDITOR_TIMELINE_ITEM_SCENE = preload("res://tools/editor/timeline_items/EditorTimelineItemSingleNote.tscn")
const EDITOR_PLUGINS_DIR = "res://tools/editor/editor_plugins"
onready var save_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/SaveButton")
onready var save_as_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/SaveAsButton")
onready var timeline = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/EditorTimeline")
onready var rhythm_game = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/RhythmGame")
onready var game_preview = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview")
onready var metre_option_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/MetreOptionButton")
onready var BPM_spinbox = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/BPMSpinBox")
onready var grid_renderer = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/Node2D/GridRenderer")
onready var inspector = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control2/TabContainer/Inspector")
onready var angle_arrange_spinbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Arrange/MarginContainer/VBoxContainer/VBoxContainer/AngleArrangeSpinbox")
onready var time_arrange_separation_spinbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Arrange/MarginContainer/VBoxContainer/TimeArrangeSeparationSpinbox")
onready var time_arrange_diagonal_angle_spinbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Arrange/MarginContainer/VBoxContainer/TimeArrangeDiagonalAngleSpinbox")
onready var layer_manager = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Layers/LayerManager")
onready var current_title_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/CurrentTitleButton")
onready var open_chart_popup_dialog = get_node("Popups/OpenChartPopupDialog")
onready var note_resolution_box = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/NoteResolution")
onready var offset_box = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Offset")
onready var auto_multi_checkbox = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/AutoMulticheckbox")
onready var rhythm_game_playtest_popup = preload("res://tools/editor/EditorRhythmGamePopup.tscn").instance()
onready var play_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/PlayButton")
onready var pause_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/PauseButton")
onready var editor_help_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/EditorHelpButton")
onready var game_playback = EditorPlayback.new(rhythm_game)
onready var sync_presets_tool = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Presets/SyncPresetsTool")
onready var transforms_tools = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Transforms/TransformsTool")
onready var message_shower = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/MessageShower")
onready var quick_lyric_dialog := get_node("QuickLyricDialog")
onready var quick_lyric_dialog_line_edit := get_node("QuickLyricDialog/MarginContainer/LineEdit")
onready var first_time_message_dialog := get_node("Popups/FirstTimeMessageDialog")
onready var info_label = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/VBoxContainer/Panel/MarginContainer/HBoxContainer/HBoxContainer/InfoLabel")
onready var waveform_button = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/WaveformButton")
onready var timeline_snap_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/TimelineGridSnapButton")
onready var show_bg_button = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/ShowBGButton")
onready var show_video_button = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/ShowVideoButton")
onready var grid_snap_button = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/GridSnapButton")
onready var show_grid_button = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/ShowGridbutton")
onready var grid_x_spinbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/SpinBox")
onready var grid_y_spinbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/Node2D/WidgetArea/Panel/HBoxContainer/SpinBox2")
onready var autoslide_checkbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Arrange/MarginContainer/VBoxContainer/AutoSlideCheckBox")
onready var sex_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/SexButton")
onready var hold_calculator_checkbox = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/HoldCalculatorCheckBox")
onready var arrange_menu = get_node("ArrangeMenu")
onready var time_arrange_snaps_spinbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Arrange/MarginContainer/VBoxContainer/TimeArrangeSnapsSpinbox")
onready var autoplace_checkbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Arrange/MarginContainer/VBoxContainer/AutoPlaceCheckBox")

const LOG_NAME = "HBEditor"

var playhead_position := 0
var scale = 1.5 # Seconds per 500 pixels
var selected: Array = []
var copied_points: Array = []

var bpm = 150 setget set_bpm, get_bpm
var current_song: HBSong
var current_difficulty: String
var snap_to_grid_enabled = true

var timeline_snap_enabled = true
	
var undo_redo = UndoRedo.new()

var song_editor_settings: HBPerSongEditorSettings = HBPerSongEditorSettings.new()
	
var plugins = []

var contextual_menu = HBEditorContextualMenuControl.new()
onready var fine_position_timer = Timer.new()

var current_notes = []

var _removed_items = [] # So we can queue_free removed nodes when freeing the editor

var playtesting := false

var _playhead_traveling := false

var autoarrange_angle_shortcuts = [
	["editor_arrange_l", PI],
	["editor_arrange_r", 0],
	["editor_arrange_u", -PI/2],
	["editor_arrange_d", PI/2],
	["editor_arrange_ul", -3*PI/4],
	["editor_arrange_ur", -PI/4],
	["editor_arrange_dl", 3*PI/4],
	["editor_arrange_dr", PI/4],
	["editor_arrange_center", null]
]

var hold_ends = []

# Fades that obscure some UI elements while playing

onready var ui_fades = [
	get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/UIFade"),
	get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control2/UIFade"),
	get_node("VBoxContainer/Panel2/UIFade")
]

func set_bpm(value):
	BPM_spinbox.value = value
	song_editor_settings.bpm = value
func get_bpm():
	return BPM_spinbox.value
	
func _sort_current_items_impl(a, b):
	return a.data.time > b.data.time
	
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
	
func _ready():
	DebugSystemInfo.disable_label()
	add_child(game_playback)
	add_child(contextual_menu)
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
#	seek(0)
	inspector.connect("property_changed", self, "_change_selected_property")
	inspector.connect("property_change_committed", self, "_commit_selected_property_change")
	
	layer_manager.connect("layer_visibility_changed", timeline, "change_layer_visibility")
	layer_manager.connect("layer_visibility_changed", self, "_on_layer_visibility_changed")
#	load_song(SongLoader.songs["sands_of_time"], "easy")
	load_plugins()
	# You HAVE to open a chart, this ensures that if no chart is selected we return
	# to the main menu
	open_chart_popup_dialog.get_cancel().connect("pressed", self, "_on_ExitDialog_confirmed")
	open_chart_popup_dialog.get_close_button().connect("pressed", self, "_on_ExitDialog_confirmed")
	open_chart_popup_dialog.connect("chart_selected", self, "load_song")
	
	rhythm_game_playtest_popup.connect("quit", self, "_on_playtest_quit")
	editor_help_button.get_popup().connect("index_pressed", self, "_on_editor_help_button_pressed")
	
	inspector.connect("note_pasted", self, "paste_note_data")
	
	MouseTrap.disable_mouse_trap()
	
	sync_presets_tool.connect("show_transform", self, "_show_transform_on_current_notes")
	sync_presets_tool.connect("hide_transform", game_preview.transform_preview, "hide")
	sync_presets_tool.connect("apply_transform", self, "_apply_transform_on_current_notes")
	
	sync_presets_tool.set_editor(self)
	
	transforms_tools.connect("show_transform", self, "_show_transform_on_current_notes")
	transforms_tools.connect("hide_transform", game_preview.transform_preview, "hide")
	transforms_tools.connect("apply_transform", self, "_apply_transform_on_current_notes")
	VisualServer.canvas_item_set_z_index(contextual_menu.get_canvas_item(), 2000)
	
	quick_lyric_dialog_line_edit.connect("text_entered", self, "_on_create_quick_lyric")
	
	if not UserSettings.user_settings.editor_first_time_message_acknowledged:
		first_time_message_dialog.popup_centered()
	else:
		_show_open_chart_dialog()
	first_time_message_dialog.get_ok().text = "Got it!"
	first_time_message_dialog.get_ok().connect("pressed", self, "_on_acknowledge_first_time_message")
	
	transforms_tools.editor = self
	
	connect("timing_points_changed", self, "_cache_hold_ends")
	
	arrange_menu.connect("angle_changed", self, "arrange_selected_notes_by_time", [true])
	
	var button_ids = ["3", "", "7", "9"]
	for i in range(4):
		var node = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Arrange/MarginContainer/VBoxContainer/CenterContainer/GridContainer/Button" + button_ids[i])
		node.connect("pressed", self, "_on_arrange_diagonals_pressed", [i])
	
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
	
func _on_create_quick_lyric(lyric_text: String):
	var lyric := HBLyricsLyric.new()
	lyric.value = lyric_text
	lyric.time = playhead_position
	create_lyrics_event(lyric)
	quick_lyric_dialog_line_edit.release_focus()
	quick_lyric_dialog.hide()
	
	
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

	for item in current_items:
		if item is EditorTimelineItemNote:
			if item.data in transformation_result:
				notes_to_apply_found = true
				break
	if notes_to_apply_found:
		deselect_all()
		undo_redo.create_action("Apply transformation")
		
		# Some transforms might change the note type and thus the layer
		var type_to_layer_name_map = {}
		for type_name in HBNoteData.NOTE_TYPE:
			type_to_layer_name_map[HBNoteData.NOTE_TYPE[type_name]] = type_name
		type_to_layer_name_map[HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT] = "SLIDE_LEFT"
		type_to_layer_name_map[HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT] = "SLIDE_RIGHT"
		
		for item in current_items:
			var note = item.data
			if note in transformation_result:
				for property_name in transformation_result[note]:
					if property_name in item.data:
						undo_redo.add_do_property(item.data, property_name, transformation_result[item.data][property_name])
						undo_redo.add_undo_property(item.data, property_name, item.data.get(property_name))
						if property_name == "note_type":
							# When note type is changed we also change the layer
							var new_note_type = transformation_result[note].note_type
							if type_to_layer_name_map[new_note_type] != item._layer.layer_name and \
									type_to_layer_name_map[new_note_type] + "2" != item._layer.layer_name:
								var source_layer = item._layer
								var target_layer_name = type_to_layer_name_map[new_note_type]
								if source_layer.layer_name.ends_with("2"):
									target_layer_name += "2"
								var target_layer = timeline.find_layer_by_name(target_layer_name)
								undo_redo.add_do_method(self, "remove_item_from_layer", source_layer, item)
								undo_redo.add_do_method(self, "add_item_to_layer", target_layer, item)
								undo_redo.add_undo_method(self, "remove_item_from_layer", target_layer, item)
								undo_redo.add_undo_method(self, "add_item_to_layer", source_layer, item)
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


var konami_sequence = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]
var konami_index = 0

var arranging = false

func _unhandled_input(event: InputEvent):
	if rhythm_game_playtest_popup in get_children():
		return
	
	if event.is_action_pressed("editor_show_arrange_menu"):
		if selected and game_preview.get_global_rect().has_point(get_global_mouse_position()):
			arrange_menu.backup_selected(selected)
			
			for item in selected:
				remove_item_from_layer(item._layer, item)
			deselect_all()
			
			for item in arrange_menu.get_selected_backup():
				var data = item.data as HBBaseNote
				if not data:
					continue
				
				var new_data_ser = data.serialize()
				var new_data = HBSerializable.deserialize(new_data_ser) as HBBaseNote
				var new_item = new_data.get_timeline_item()
				
				add_item_to_layer(item._layer, new_item)
				select_item(new_item, true)
			
			arranging = true
			arrange_menu.popup()
			arrange_menu.set_global_position(get_global_mouse_position())
	elif event.is_action_released("editor_show_arrange_menu") and arranging:
		arranging = false
		arrange_menu.hide()
		
		for item in selected:
			remove_item_from_layer(item._layer, item)
		deselect_all()
		
		for item in arrange_menu.get_selected_backup():
			add_item_to_layer(item._layer, item)
			select_item(item, true)
		
		arrange_selected_notes_by_time(arrange_menu.get_angle())
	
	if event is InputEventKey and event.pressed and not sex_button.visible:
		if event.scancode == konami_sequence[konami_index]:
			konami_index += 1
			
			if konami_index == konami_sequence.size():
				sex_button.show()
		else:
			konami_index = 0
	
	if event.is_action("editor_playtest") or \
		event.is_action("editor_playtest_at_time"):
		if not event.shift and not event.control and event.is_pressed():
			var at_time = false
		
			if event.is_action("editor_playtest_at_time"):
				at_time = true
		
			_on_PlaytestButton_pressed(at_time)
	
	if event.is_action("gui_left") or \
		event.is_action("gui_right") or \
		event.is_action("gui_up") or \
		event.is_action("gui_down"):
		if event is InputEventKey:
			if event.shift:
				var diff_x = event.get_action_strength("gui_right") - event.get_action_strength("gui_left")
				var diff_y = event.get_action_strength("gui_down") - event.get_action_strength("gui_up")
				var off = Vector2(int(diff_x), int(diff_y))
				fine_position_selected(off)
				get_tree().set_input_as_handled()
			if event.control and not event.echo:
				var diff_x = event.get_action_strength("gui_right") - event.get_action_strength("gui_left")
				var diff_y = event.get_action_strength("gui_down") - event.get_action_strength("gui_up")
				
				var spacing_x = 1920 / grid_renderer.vertical
				var spacing_y = 1080 / grid_renderer.horizontal
				var off = Vector2(int(diff_x * spacing_x), int(diff_y * spacing_y))
				
				fine_position_selected(off)
				get_tree().set_input_as_handled()
	
	if event is InputEventKey:
		for action in autoarrange_angle_shortcuts:
			if event.is_action_pressed(action[0]) and not event.echo and not event.shift:
				if not event.control:
					arrange_selected_notes_by_time(action[1])
				else:
					if not action[1]:
						return
					
					undo_redo.create_action("Change note angle to " + str(rad2deg(action[1])))
			
					for note in selected:
						if note.data is HBBaseNote:
							undo_redo.add_do_property(note.data, "entry_angle", rad2deg(action[1]))
							undo_redo.add_do_method(self, "_on_timing_points_params_changed")
							
							undo_redo.add_undo_property(note.data, "entry_angle", note.data.entry_angle)
							undo_redo.add_undo_method(self, "_on_timing_points_params_changed")
							
							undo_redo.add_do_method(note, "update_widget_data")
							undo_redo.add_do_method(note, "sync_value", "entry_angle")
							undo_redo.add_undo_method(note, "update_widget_data")
							undo_redo.add_undo_method(note, "sync_value", "entry_angle")
							
							undo_redo.add_do_method(inspector, "sync_visible_values_with_data")
							undo_redo.add_undo_method(inspector, "sync_visible_values_with_data")
					
					undo_redo.commit_action()
				
				get_tree().set_input_as_handled()
				break
	
	if event.is_action_pressed("editor_quick_lyric"):
		quick_lyric_dialog.popup_centered()
		quick_lyric_dialog_line_edit.grab_focus()
		quick_lyric_dialog_line_edit.text = ""
	if event.is_action_pressed("editor_quick_phrase_start"):
		var ev := HBLyricsPhraseStart.new()
		ev.time = playhead_position
		create_lyrics_event(ev)
	if event.is_action_pressed("editor_quick_phrase_end"):
		var ev := HBLyricsPhraseEnd.new()
		ev.time = playhead_position
		create_lyrics_event(ev)
	
	if event.is_action_pressed("editor_flip_angle"):
		if not event.control and not event.shift and not event.echo:
			undo_redo.create_action("Flip angle")
			
			for note in selected:
				if note.data is HBBaseNote:
					undo_redo.add_do_property(note.data, "entry_angle", fmod(note.data.entry_angle + 180.0, 360.0))
					undo_redo.add_do_method(self, "_on_timing_points_params_changed")
					
					undo_redo.add_undo_property(note.data, "entry_angle", note.data.entry_angle)
					undo_redo.add_undo_method(self, "_on_timing_points_params_changed")
					
					undo_redo.add_do_property(note.data, "oscillation_amplitude", -note.data.oscillation_amplitude)
					undo_redo.add_do_method(self, "_on_timing_points_params_changed")
					
					undo_redo.add_undo_property(note.data, "oscillation_amplitude", note.data.oscillation_amplitude)
					undo_redo.add_undo_method(self, "_on_timing_points_params_changed")
					
					undo_redo.add_do_method(note, "update_widget_data")
					undo_redo.add_do_method(note, "sync_value", "entry_angle")
					undo_redo.add_undo_method(note, "update_widget_data")
					undo_redo.add_undo_method(note, "sync_value", "entry_angle")
			
			undo_redo.add_do_method(inspector, "sync_visible_values_with_data")
			undo_redo.add_undo_method(inspector, "sync_visible_values_with_data")
			
			undo_redo.commit_action()
	if event.is_action_pressed("editor_flip_oscillation"):
		if not event.control and not event.shift and not event.echo:
			undo_redo.create_action("Flip oscillation")
			
			for note in selected:
				if note.data is HBBaseNote:
					undo_redo.add_do_property(note.data, "oscillation_amplitude", -note.data.oscillation_amplitude)
					undo_redo.add_do_method(self, "_on_timing_points_params_changed")
					
					undo_redo.add_undo_property(note.data, "oscillation_amplitude", note.data.oscillation_amplitude)
					undo_redo.add_undo_method(self, "_on_timing_points_params_changed")
					
					undo_redo.add_do_method(note, "update_widget_data")
					undo_redo.add_do_method(note, "sync_value", "oscillation_amplitude")
					undo_redo.add_undo_method(note, "update_widget_data")
					undo_redo.add_undo_method(note, "sync_value", "oscillation_amplitude")
					
			undo_redo.add_do_method(inspector, "sync_visible_values_with_data")
			undo_redo.add_undo_method(inspector, "sync_visible_values_with_data")
			
			undo_redo.commit_action()
	
	if event.is_action_pressed("editor_toggle_hold"):
		if not event.control and not event.shift and not event.echo:
			undo_redo.create_action("Toggle hold")
			
			for note in selected:
				if note.data is HBNoteData:
					undo_redo.add_do_property(note.data, "hold", not note.data.hold)
					undo_redo.add_undo_property(note.data, "hold", note.data.hold)
			
			undo_redo.add_do_method(inspector, "sync_visible_values_with_data")
			undo_redo.add_undo_method(inspector, "sync_visible_values_with_data")
			undo_redo.add_do_method(self, "_on_timing_points_changed")
			undo_redo.add_undo_method(self, "_on_timing_points_changed")
			
			undo_redo.commit_action()
	
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.scancode >= KEY_1 and event.scancode <= KEY_5:
				var tab = event.scancode - KEY_1
				$VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2.set_current_tab(tab)
				return
	if event.is_action_pressed("editor_play"):
		if not game_playback.is_playing():
			_on_PlayButton_pressed()
		else:
			_on_PauseButton_pressed()
	elif event.is_action_pressed("gui_undo"):
		get_tree().set_input_as_handled()
		apply_fine_position()
		if undo_redo.has_undo():
			message_shower._show_notification("Undo " + undo_redo.get_current_action_name().to_lower())
			undo_redo.undo()
	elif event.is_action_pressed("gui_redo"):
		get_tree().set_input_as_handled()
		apply_fine_position()
		if undo_redo.has_redo():
			undo_redo.redo()
			message_shower._show_notification("Redo " + undo_redo.get_current_action_name().to_lower())
	elif event.is_action_pressed("editor_delete"):
		if selected.size() != 0:
			get_tree().set_input_as_handled()
			delete_selected()
	elif event.is_action_pressed("editor_paste"):
		var time = timeline.get_time_being_hovered()
		paste(time)
	elif event.is_action_pressed("editor_copy"):
		copy_selected()
	elif event.is_action_pressed("editor_cut"):
		copy_selected()
		delete_selected()
	elif event.is_action_pressed("editor_select_all"):
		select_all()
	elif not game_playback.is_playing():
		if event is InputEventKey:
			if not event.shift and not event.control:
				var old_pos = playhead_position
				if event.is_action_pressed("gui_left", true):
					playhead_position -= get_timing_interval()
					playhead_position = snap_time_to_timeline(playhead_position)
					emit_signal("playhead_position_changed")
					timeline.ensure_playhead_is_visible()
				elif event.is_action_pressed("gui_right", true):
					playhead_position += get_timing_interval()
					playhead_position = snap_time_to_timeline(playhead_position)
					emit_signal("playhead_position_changed")
					timeline.ensure_playhead_is_visible()
					
				if old_pos != playhead_position:
					seek(playhead_position)
	if event is InputEventKey:
		if not event.shift and not event.control and not event.is_action_pressed("editor_play"):
			if selected:
				var changed_buttons = []
				
				for type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
					for action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[type]:
						if event.is_action_pressed(action):
							undo_redo.create_action("Change selected notes button to " + HBGame.NOTE_TYPE_TO_STRING_MAP[type])
							
							var layer_name = HBUtils.find_key(HBBaseNote.NOTE_TYPE, type)
							
							var new_layer = timeline.find_layer_by_name(layer_name)
							
							for item in selected:
								var data = item.data as HBBaseNote
								if not data:
									continue
								var new_data_ser = data.serialize()
								
								new_data_ser["note_type"] = type
								
								# Fallbacks when converting illegal note types
								if type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT or type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
									new_data_ser["type"] = "Note"
								
								if type == HBBaseNote.NOTE_TYPE.HEART:
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
							
							undo_redo.add_do_method(self, "_on_timing_points_changed")
							undo_redo.add_undo_method(self, "_on_timing_points_changed")
							undo_redo.add_undo_method(self, "deselect_all")
							undo_redo.add_do_method(self, "deselect_all")
							undo_redo.commit_action()
							
							return
			
			for type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
				var found_note = false
				for action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[type]:
					var layer = null
					for layer_c in timeline.get_visible_layers():
						if layer_c.layer_name == HBUtils.find_key(HBBaseNote.NOTE_TYPE, type):
							layer = layer_c
							break
					if not layer:
						continue
					if event.is_action_pressed(action):
						var items_at_time = get_items_at_time(playhead_position)
						
						var item_erased = false
						for item in items_at_time:
							if item is EditorTimelineItemNote:
								if item.data.note_type == type:
									item_erased = true
									
									deselect_all()
									
									undo_redo.create_action("Remove note")
									
									undo_redo.add_do_method(self, "remove_item_from_layer", item._layer, item)
									undo_redo.add_undo_method(self, "add_item_to_layer", item._layer, item)
										
									undo_redo.add_do_method(self, "_on_timing_points_changed")
									undo_redo.add_undo_method(self, "_on_timing_points_changed")
									undo_redo.commit_action()
						if not item_erased:
							var timing_point := HBNoteData.new()
							timing_point.time = snap_time_to_timeline(playhead_position)
							# Event layer is the last one
								
							timing_point.note_type = type
								
							user_create_timing_point(layer, timing_point.get_timeline_item())
						found_note = true
						break
				if found_note:
					break
							
							
func _note_comparison(a, b):
	return a.time > b.time

func get_timing_points():
	var points = []
	var layers = timeline.get_layers()
	for layer in layers:
		points += layer.get_timing_points()
	points.sort_custom(self, "_note_comparison")
	return points

func get_timeline_items():
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

func select_item(item: EditorTimelineItem, add = false):
	if selected.size() > 0 and not add:
		for selected_item in selected:
			selected_item.deselect()
	inspector.stop_inspecting()
	if add:
		selected.append(item)
	else:
		selected = [item]
	release_owned_focus()
	item.select()
	var widget := item.get_editor_widget()
	if widget:
		var widget_instance = widget.instance() as HBEditorWidget
		widget_instance.editor = self
		game_preview.widget_area.add_child(widget_instance)
		item.connect_widget(widget_instance)
	inspector.inspect(item)
	selected.sort_custom(self, "_sort_current_items_impl")
	notify_selected_changed()
func select_all():
	if selected.size() > 0:
		deselect_all()
	selected = current_notes.duplicate()
	inspector.stop_inspecting()
	if selected.size() > 0:
		for item in selected:
			item.select()
		inspector.inspect(selected[0])
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
			selected_item.data.set(property_name, selected_item.data.get(property_name) + new_value)
			selected_item.update_widget_data()
	_on_timing_points_params_changed()
	
var fine_position_originals = {}
	
func fine_position_selected(diff: Vector2):
	for selected_item in selected:
		if "position" in selected_item.data:
			if not selected_item in fine_position_originals:
				fine_position_originals[selected_item] = selected_item.data.position
			selected_item.data.position += diff
			selected_item.update_widget_data()
	fine_position_timer.start()
	_on_timing_points_params_changed()
func apply_fine_position():
	fine_position_timer.stop()
	if fine_position_originals.size() > 0:
		undo_redo.create_action("Fine position notes")
		for item in fine_position_originals:
			undo_redo.add_undo_property(item.data, "position", fine_position_originals[item])
			undo_redo.add_undo_method(item, "update_widget_data")
			undo_redo.add_undo_method(item, "sync_value", "position")
			undo_redo.add_do_property(item.data, "position", item.data.position)
			undo_redo.add_do_method(item, "update_widget_data")
			undo_redo.add_do_method(item, "sync_value", "position")
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_method(self, "_on_timing_points_changed")
		fine_position_originals = {}
		
		undo_redo.commit_action()
		inspector.sync_value("position")
func show_contextual_menu():
	contextual_menu.popup()
	var popup_offset = get_global_mouse_position() + contextual_menu.rect_size - get_viewport_rect().size
	popup_offset.x = max(popup_offset.x, 0)
	popup_offset.y = max(popup_offset.y, 0)
	contextual_menu.set_global_position(get_global_mouse_position() - popup_offset)
	
# Changes the property of the selected item, but doesn't commit it to undo_redo, to
# prevent creating more undo_redo actions than necessary, thus undoing constant 
# actions like changing a note angle requires a single control+z
func _change_selected_property(property_name: String, new_value):
	for selected_item in selected:
		if not selected_item in old_property_values:
			old_property_values[selected_item] = {}
		
		if not property_name in old_property_values[selected_item]:
			old_property_values[selected_item][property_name] = selected_item.data.get(property_name)
		selected_item.data.set(property_name, new_value)

		selected_item.update_widget_data()
		selected_item.sync_value(property_name)
	_on_timing_points_params_changed()
	
func _commit_selected_property_change(property_name: String):
	var action_name = "Note " + property_name + " changed"
	
	print(action_name)
	undo_redo.create_action(action_name)
	for selected_item in selected:
		if old_property_values.has(selected_item):
			if property_name in selected_item.data:
				if property_name == "time":
					if selected_item.data is HBSustainNote:
						undo_redo.add_do_property(selected_item.data, "end_time", selected_item.data.end_time)
						undo_redo.add_undo_property(selected_item.data, "end_time", old_property_values[selected_item].end_time)
					
					check_for_multi_changes(selected_item.data, old_property_values[selected_item][property_name])
				
				undo_redo.add_do_property(selected_item.data, property_name, selected_item.data.get(property_name))
				undo_redo.add_do_method(selected_item._layer, "place_child", selected_item)
				undo_redo.add_do_method(selected_item, "update_widget_data")
				undo_redo.add_do_method(selected_item, "sync_value", property_name)

				undo_redo.add_undo_property(selected_item.data, property_name, old_property_values[selected_item][property_name])
				undo_redo.add_undo_method(selected_item._layer, "place_child", selected_item)
				undo_redo.add_undo_method(selected_item, "update_widget_data")
				undo_redo.add_undo_method(selected_item, "sync_value", property_name)
				

	undo_redo.add_do_method(inspector, "sync_visible_values_with_data")
	undo_redo.add_undo_method(inspector, "sync_visible_values_with_data")
	undo_redo.add_do_method(self, "_on_timing_points_changed")
	undo_redo.add_undo_method(self, "_on_timing_points_changed")
	undo_redo.add_do_method(self, "sync_lyrics")
	undo_redo.add_undo_method(self, "sync_lyrics")
	
	if property_name == "time":
		undo_redo.add_do_method(self, "sort_current_items")
	
	undo_redo.commit_action()
	inspector.sync_value(property_name)
	release_owned_focus()
	old_property_values = {}
# Handles when a user changes a timing point's property, this is used for properties
# that won't constantly change
func _on_timing_point_property_changed(property_name: String, old_value, new_value, child: EditorTimelineItem, affects_timing_points = false):
	var action_name = "Note " + property_name + " changed"
	undo_redo.create_action(action_name)
	
	undo_redo.add_do_property(child.data, property_name, new_value)
	undo_redo.add_do_method(self, "_on_timing_points_changed")
	undo_redo.add_do_method(child._layer, "place_child", child)
	
	undo_redo.add_undo_property(child.data, property_name, old_value)
	undo_redo.add_undo_method(self, "_on_timing_points_changed")
	undo_redo.add_undo_method(child._layer, "place_child", child)
	
	if property_name == "position" or property_name:
		undo_redo.add_do_method(child, "update_widget_data")
		undo_redo.add_undo_method(child, "update_widget_data")
	
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
func add_item_to_layer(layer, item: EditorTimelineItem):
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
		

func seek(value: int, snapped = false):
	if snapped:
		value = snap_time_to_timeline(value)
	game_playback.seek(value)
	if game_playback.audio_stream_player.stream_paused:
		game_preview.set_time(value / 1000.0)
	else:
		game_preview.play_at_pos(value / 1000.0)
	
func copy_selected():
	if selected.size() > 0:
		copied_points = []
		for item in selected:
			var timing_point_timeline_item = item as EditorTimelineItem
			var cloned_item = timing_point_timeline_item.data.clone().get_timeline_item()
			cloned_item._layer = timing_point_timeline_item._layer
			copied_points.append(cloned_item)
			
	
func paste(time: int):
	if copied_points.size() > 0:
		undo_redo.create_action("Paste timing points")
		message_shower._show_notification("Paste notes")
		var min_point = copied_points[0].data as HBTimingPoint
		for item in copied_points:
			var timing_point := item.data as HBTimingPoint
			if timing_point.time < min_point.time:
				min_point = timing_point
		for item in copied_points:
			var timeline_item := item as EditorTimelineItem
			var timing_point := item.data.clone() as HBTimingPoint
			
			timing_point.time = time + timing_point.time - min_point.time
			if timing_point is HBSustainNote:
				timing_point.end_time = timing_point.time + item.data.get_duration()
			var new_item = timing_point.get_timeline_item() as EditorTimelineItem
			
			undo_redo.add_do_method(self, "add_item_to_layer", timeline_item._layer, new_item)
			undo_redo.add_undo_method(self, "remove_item_from_layer", timeline_item._layer, new_item)
			
			check_for_multi_changes(timing_point, -1)
			
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_method(self, "_on_timing_points_changed")
		undo_redo.add_do_method(self, "sync_lyrics")
		undo_redo.add_undo_method(self, "sync_lyrics")
		undo_redo.commit_action()
func delete_selected():
	if selected.size() > 0:
		if inspector.inspecting_item in selected:
			inspector.stop_inspecting()
		undo_redo.create_action("Delete notes")
		
		message_shower._show_notification("Delete notes")
		
		for selected_item in selected:
			selected_item.deselect()
			
			undo_redo.add_do_method(self, "remove_item_from_layer", selected_item._layer, selected_item)
			undo_redo.add_undo_method(self, "add_item_to_layer", selected_item._layer, selected_item)
			
			check_for_multi_changes(selected_item.data, selected_item.data.time)
			
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_method(self, "_on_timing_points_changed")
		undo_redo.add_do_method(self, "sync_lyrics")
		undo_redo.add_undo_method(self, "sync_lyrics")
		selected = []
		undo_redo.commit_action()

func check_for_multi_changes(item: HBBaseNote, old_time: int):
	if song_editor_settings.auto_multi:
		if item is HBBaseNote:
			var notes = get_notes_at_time(item.time)
			
			if notes.size() > 0:
				var found_any_note = false
				
				for note in notes:
					if note == item:
						continue
					
					if note is HBBaseNote:
						found_any_note = true
					else:
						continue
					
					undo_redo.add_do_property(note, "oscillation_amplitude", 0)
					undo_redo.add_do_property(note, "distance", 880)
				
					undo_redo.add_undo_property(note, "oscillation_amplitude", note.oscillation_amplitude)
					undo_redo.add_undo_property(note, "distance", note.distance)
				
				if found_any_note:
					undo_redo.add_do_property(item, "oscillation_amplitude", 0)
					undo_redo.add_do_property(item, "distance", 880)
				
					undo_redo.add_undo_property(item, "oscillation_amplitude", item.oscillation_amplitude)
					undo_redo.add_undo_property(item, "distance", item.distance)
				elif item.oscillation_amplitude == 0 and item.distance == 880:
					undo_redo.add_do_property(item, "oscillation_amplitude", 500)
					undo_redo.add_do_property(item, "distance", 1200)
				
					undo_redo.add_undo_property(item, "oscillation_amplitude", item.oscillation_amplitude)
					undo_redo.add_undo_property(item, "distance", item.distance)
			
			if old_time != -1:
				var previous_notes = get_notes_at_time(old_time)
				var previous_note
				
				for note in previous_notes:
					if note == item:
						continue
					
					if note is HBBaseNote:
						if previous_note:
							previous_note = null
							break
						else:
							previous_note = note
				
				if previous_note:
					undo_redo.add_do_property(previous_note, "oscillation_amplitude", 500)
					undo_redo.add_do_property(previous_note, "distance", 1200)
					
					undo_redo.add_undo_property(previous_note, "oscillation_amplitude", previous_note.oscillation_amplitude)
					undo_redo.add_undo_property(previous_note, "distance", previous_note.distance)

func deselect_all():
	for item in selected:
		item.deselect()
	selected = []
	inspector.stop_inspecting()
	notify_selected_changed()
func deselect_item(item):
	if item in selected:
		selected.erase(item)
		item.deselect()
		if selected.size() > 0:
			inspector.inspect(selected[-1])
		else:
			inspector.stop_inspecting()
func get_notes_at_time(time: int):
	var notes = []
	for note in get_timing_points():
		if note is HBTimingPoint:
			if note.time == time:
				notes.append(note)
	return notes
func user_create_timing_point(layer, item: EditorTimelineItem):
	undo_redo.create_action("Add new timing point")
	
	if item.data is HBBaseNote and song_editor_settings.autoplace:
		var eights_per_minute = get_bpm() / 8
		var seconds_per_bar = 60.0 / eights_per_minute
		
		var beat_length = seconds_per_bar / float(get_beats_per_bar())
		var note_length = 1.0/4.0 # a quarter of a beat
		var interval = (get_note_resolution() / note_length) * beat_length * 1000
		
		var time_as_eight = stepify((item.data.time - offset_box.value * 1000) / interval, 0.01)
		time_as_eight = fmod(time_as_eight, 15.5)
		if time_as_eight < 0:
			time_as_eight = fmod(15.5 - abs(time_as_eight), 15.5)
		
		item.data.position.x = 242 + 96 * time_as_eight
		item.data.position.y = 918
		
		item.data.oscillation_frequency = -2
		item.data.entry_angle = -90
	
	undo_redo.add_do_method(self, "add_item_to_layer", layer, item)
	undo_redo.add_do_method(self, "_on_timing_points_changed")
	undo_redo.add_undo_method(self, "remove_item_from_layer", layer, item)
	undo_redo.add_undo_method(item, "deselect")
	undo_redo.add_undo_method(self, "_on_timing_points_changed")
	
	check_for_multi_changes(item.data, -1)
	
	undo_redo.commit_action()
			
func remove_item_from_layer(layer, item: EditorTimelineItem):
	layer.remove_item(item)
	current_notes.erase(item)
	_removed_items.append(item)
func _create_bpm_change():
	add_event_timing_point(HBBPMChange)
func pause():
	game_playback.pause()
	game_preview.set_visualizer_processing_enabled(false)
	game_preview.widget_area.show()
	playhead_position = snap_time_to_timeline(playhead_position)
	game_preview.pause()
	emit_signal("playhead_position_changed")
	reveal_ui()
func _on_PauseButton_pressed():
	pause()
	game_preview.set_time(playhead_position/1000.0)
	play_button.show()
	pause_button.hide()

func _on_PlayButton_pressed():
	_on_SaveButton_pressed()
	_playhead_traveling = true
	game_preview.play_at_pos(playhead_position/1000.0)
	game_playback.play_from_pos(playhead_position)
	play_button.hide()
	pause_button.show()
	game_preview.set_visualizer_processing_enabled(true)
	game_preview.widget_area.hide()
	obscure_ui()
	
# Fired when any timing point is changed, gives the game the new data
func _on_timing_points_changed():
	game_playback.chart = get_chart()
	emit_signal("timing_points_changed")

func _on_timing_points_params_changed():
	game_playback._on_timing_params_changed()
	game_playback.seek(playhead_position)

func get_song_length():
	if game_playback.audio_stream_player.stream:
		return game_playback.audio_stream_player.stream.get_length()
	else:
		return 0.0
		
func get_chart():
	var chart = HBChart.new()
	var layer_items = timeline.get_layers()
	chart.editor_settings = song_editor_settings
	var layers = []
	for layer in layer_items:
		if layer.layer_name == "Lyrics":
			continue
		layers.append({
			"name": layer.layer_name,
			"timing_points": layer.get_timing_points()
		})
	chart.layers = layers
	return chart
func serialize_chart():
	return get_chart().serialize()

func load_settings(settings: HBPerSongEditorSettings):
	offset_box.disconnect("value_changed", self, "_on_timing_information_changed")
	note_resolution_box.disconnect("value_changed", self, "_on_timing_information_changed")
	BPM_spinbox.disconnect("value_changed", self, "_on_timing_information_changed")
	metre_option_button.disconnect("item_selected", self, "_on_timing_information_changed")
	auto_multi_checkbox.disconnect("toggled", self, "_on_auto_multi_toggled")
	song_editor_settings = settings
	for layer in timeline.get_layers():
		var layer_visible = not layer.layer_name in settings.hidden_layers
		timeline.change_layer_visibility(layer_visible, layer.layer_name)
	
	set_bpm(settings.bpm)
	set_note_resolution(settings.note_resolution)
	set_note_snap_offset(settings.offset)
	set_beats_per_bar(settings.beats_per_bar)
	timeline_snap_button.pressed = settings.timeline_snap
	
	auto_multi_checkbox.pressed = settings.auto_multi
	hold_calculator_checkbox.pressed = settings.hold_calculator
	waveform_button.pressed = settings.waveform
	game_preview.settings = settings
	show_bg_button.pressed = settings.show_bg
	show_video_button.pressed = settings.show_video
	
	grid_renderer.settings = settings
	grid_snap_button.pressed = settings.grid_snap
	show_grid_button.pressed = settings.show_grid
	grid_x_spinbox.value = settings.grid_resolution.x
	grid_y_spinbox.value = settings.grid_resolution.y
	
	time_arrange_separation_spinbox.value = settings.separation
	time_arrange_diagonal_angle_spinbox.value = settings.diagonal_angle
	time_arrange_snaps_spinbox.value = settings.arranger_snaps
	
	transforms_tools.load_settings()
	
	autoslide_checkbox.pressed = settings.autoslide
	autoplace_checkbox.pressed = settings.autoplace
	
	emit_signal("timing_information_changed")
	offset_box.connect("value_changed", self, "_on_timing_information_changed")
	note_resolution_box.connect("value_changed", self, "_on_timing_information_changed")
	BPM_spinbox.connect("value_changed", self, "_on_timing_information_changed")
	metre_option_button.connect("item_selected", self, "_on_timing_information_changed")
	auto_multi_checkbox.connect("toggled", self, "_on_auto_multi_toggled")
func from_chart(chart: HBChart, ignore_settings=false):
	timeline.clear_layers()
	undo_redo.clear_history()
	selected = []
	layer_manager.clear_layers()
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
		var layer_visible = not layer.name in chart.editor_settings.hidden_layers
		
		layer_manager.add_layer(layer.name, layer_visible)
		
	# Lyrics layer
	var layer_scene = EDITOR_LAYER_SCENE.instance()
	layer_scene.layer_name = "Lyrics"
	timeline.add_layer(layer_scene)
	layer_manager.add_layer("Lyrics", false)
	
	var lyrics_layer_n = timeline.get_layers().size()-1
	
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
		
	if not ignore_settings:
		load_settings(chart.editor_settings)
	_on_timing_points_changed()
	# Disconnect the cancel action in the chart open dialog, because we already have at least
	# a chart loaded
	if open_chart_popup_dialog.get_cancel().is_connected("pressed", self, "_on_ExitDialog_confirmed"):
		open_chart_popup_dialog.get_cancel().disconnect("pressed", self, "_on_ExitDialog_confirmed")
		open_chart_popup_dialog.get_close_button().disconnect("pressed", self, "_on_ExitDialog_confirmed")
	deselect_all()
	sync_lyrics()
func paste_note_data(note_data: HBBaseNote):
	undo_redo.create_action("Paste note data")
	for selected_item in selected:
		if selected_item.data is HBBaseNote:
			var new_data = note_data.clone() as HBBaseNote
			new_data.note_type = selected_item.data.note_type
			new_data.time = selected_item.data.time
			undo_redo.add_do_property(selected_item, "data", new_data)
			undo_redo.add_do_method(self, "_on_timing_points_changed")
			undo_redo.add_undo_property(selected_item, "data", selected_item.data)
			undo_redo.add_undo_method(self, "_on_timing_points_changed")
	undo_redo.commit_action()
	inspector.stop_inspecting()
	inspector.inspect(selected[0])
	inspector.sync_visible_values_with_data()

func _on_SaveSongSelector_chart_selected(song_id, difficulty):
	var song = SongLoader.songs[song_id]
	var chart_path = song.get_chart_path(difficulty)
	var file = File.new()
	file.open(chart_path, File.WRITE)
	file.store_string(JSON.print(serialize_chart(), "  "))

func load_song(song: HBSong, difficulty: String):
	deselect_all()
	
	rhythm_game.base_bpm = song.bpm
	copied_points = []
	var chart_path = song.get_chart_path(difficulty)
	var file = File.new()
	var dir = Directory.new()
	var chart = HBChart.new()
	game_preview.set_song(song)
	chart.editor_settings.bpm = song.bpm
	if dir.file_exists(chart_path):
		file.open(chart_path, File.READ)
		
		var chart_json = JSON.parse(file.get_as_text())
		if chart_json.error == OK:
			var result = chart_json.result
			chart = HBChart.new()
			chart.deserialize(result)
	current_song = song
	
	HBGame.rich_presence.update_activity({
		"state": "In editor",
		"details": current_song.title,
		"start_timestamp": OS.get_unix_time()
	})
	
	game_playback.set_song(current_song)

	OS.set_window_title("Project Heartbeat - " + song.get_visible_title() + " - " + difficulty.capitalize())
	current_title_button.text = "%s (%s)" % [song.get_visible_title(), difficulty.capitalize()]
	BPM_spinbox.value = song.bpm
	from_chart(chart)
	current_difficulty = difficulty
	save_button.disabled = false
	save_as_button.disabled = false
	emit_signal("load_song", song)
	timeline.set_audio_stream(game_playback.audio_stream_player.stream)
	timeline.set_layers_offset(0)
	reveal_ui()
func obscure_ui():
	for fade in ui_fades:
		fade.obscure()
		
func reveal_ui():
	for fade in ui_fades:
		fade.reveal()
func _on_ExitDialog_confirmed():
	Input.set_use_accumulated_input(!UserSettings.user_settings.input_poll_more_than_once_per_frame)
	get_tree().change_scene_to(load("res://menus/MainMenu3D.tscn"))
#	MouseTrap.enable_mouse_trap()
	OS.window_maximized = false
	UserSettings.apply_display_mode()
	
const OPTION_TO_BEATS_PER_BAR = {
	0: 4,
	1: 3,
	2: 2,
	3: 1
}

func get_beats_per_bar():
	return OPTION_TO_BEATS_PER_BAR[metre_option_button.selected]

func set_beats_per_bar(bpb):
	var option = HBUtils.find_key(OPTION_TO_BEATS_PER_BAR, int(bpb))
	metre_option_button.select(option)

func get_note_resolution():
	return 1/note_resolution_box.value

func release_owned_focus():
	$FocusTrap.grab_focus()

func set_note_resolution(note_res):
	note_resolution_box.value = note_res
	
func get_note_snap_offset():
	return $VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Offset.value

func set_note_snap_offset(offset):
	print("SET OFFSET TO ", offset)
	$VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Offset.value = offset
	release_owned_focus()
func _on_timing_information_changed(f=null):
	song_editor_settings.offset = get_note_snap_offset()
	song_editor_settings.bpm = get_bpm()
	song_editor_settings.beats_per_bar = get_beats_per_bar()
	song_editor_settings.note_resolution = note_resolution_box.value
	release_owned_focus()
	emit_signal("timing_information_changed")


func _on_SaveButton_pressed():
	var chart_path = current_song.get_chart_path(current_difficulty)
	var file = File.new()
	file.open(chart_path, File.WRITE)
	var chart = get_chart()
	file.store_string(JSON.print(chart.serialize(), "  "))
	file.close()
	
	current_song.lyrics = get_lyrics()
	current_song.charts[current_difficulty]["note_usage"] = chart.get_note_usage()
	current_song.has_audio_loudness = true
	current_song.audio_loudness = SongDataCache.audio_normalization_cache[current_song.id].loudness
	for difficulty in current_song.charts:
		current_song.charts[difficulty]["hash"] = current_song.generate_chart_hash(difficulty)
		var curr_chart = current_song.get_chart_for_difficulty(difficulty) as HBChart
		current_song.charts[difficulty]["max_score"] = curr_chart.get_max_score()
	current_song.save_song()
	message_shower._show_notification("Chart saved")
	
func _on_ShowGridbutton_toggled(button_pressed):
	grid_renderer.visible = button_pressed
	song_editor_settings.show_grid = button_pressed

func _on_GridSnapButton_toggled(button_pressed):
	snap_to_grid_enabled = button_pressed
	song_editor_settings.grid_snap = button_pressed

func snap_position_to_grid(new_pos: Vector2, prev_pos: Vector2, one_direction: bool):
	new_pos /= rhythm_game.BASE_SIZE
	prev_pos /= rhythm_game.BASE_SIZE
	var final_position = new_pos
	
	if snap_to_grid_enabled:
		final_position.x = round(grid_renderer.vertical * new_pos.x) / float(grid_renderer.vertical)
		final_position.y = round(grid_renderer.horizontal * new_pos.y) / float(grid_renderer.horizontal)
	
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
	
	final_position *= rhythm_game.BASE_SIZE
	return final_position


func _on_TimelineGridSnapButton_toggled(button_pressed):
	timeline_snap_enabled = button_pressed
	song_editor_settings.timeline_snap = button_pressed

func get_timing_interval():
	var bars_per_minute = get_bpm() / float(get_beats_per_bar())
	var seconds_per_bar = 60.0/bars_per_minute
	
	var beat_length = seconds_per_bar / float(get_beats_per_bar())
	var note_length = 1.0/4.0 # a quarter of a beat
	var interval = (get_note_resolution() / note_length) * beat_length
	interval = interval * 1000.0
	
	return interval

func snap_time_to_timeline(time):

	if timeline_snap_enabled:
		var interval = get_timing_interval()
		time -= get_note_snap_offset()*1000.0
		var n = time / float(interval)
		n = round(n)
		return n*interval + get_note_snap_offset()*1000.0
	else:
		return time

func arrange_selected_by_angle(diff):
	var notes = []
	for item in selected:
		if item.data is HBBaseNote:
			notes.append(item.data)
	if notes.size() > 1:
		undo_redo.create_action("Arrange selected notes by angle")
		
		notes.sort_custom(self, "_note_comparison")
		
		var first_angle = notes[notes.size()-1].entry_angle
		var mult = 0
		for i in range(notes.size()-1, -1, -1):
			var note = notes[i] as HBBaseNote
			undo_redo.add_do_property(note, "entry_angle", int(fmod(first_angle + diff * mult, 360.0)))
			undo_redo.add_do_method(self, "_on_timing_points_changed")
			undo_redo.add_undo_property(note, "entry_angle", note.entry_angle)
			undo_redo.add_undo_method(self, "_on_timing_points_changed")
			mult += 1
		inspector.sync_visible_values_with_data()
		undo_redo.commit_action()
func _on_AngleArrangeButtonPlus_pressed():
	arrange_selected_by_angle(angle_arrange_spinbox.value)


func _on_AngleArrangeButtonMinus_pressed():
	arrange_selected_by_angle(-angle_arrange_spinbox.value)

func _order_items(a, b):
	return a.data.time < b.data.time

# Arranges the selected notes in the playarea by a certain distances
func arrange_selected_notes_by_time(angle, preview_only: bool = false):
	var separation : Vector2 = Vector2.ZERO
	var slide_separation : Vector2 = Vector2.ZERO
	var eight_separation = time_arrange_separation_spinbox.value
	
	var autoslide = autoslide_checkbox.pressed
	
	if angle != null:
		separation.x = eight_separation * cos(angle)
		separation.y = eight_separation * sin(angle)
		slide_separation.x = 32 * cos(angle)
		slide_separation.y = 32 * sin(angle)
	
	# Never remove these, it makes the mikuphile mad
	var direction = Vector2.ZERO
	if abs(direction.x) > 0 and abs(direction.y) > 0:
		pass
	
	var pos_compensation: Vector2
	var time_compensation := 0
	
	
	var bars_per_minute = get_bpm() / float(get_beats_per_bar())
	var seconds_per_bar = 60/bars_per_minute
	
	var beat_length = seconds_per_bar / float(get_beats_per_bar())
	var note_length = 1.0/4.0 # a quarter of a beat
	var interval = (get_note_resolution() / note_length) * beat_length * 2.0
	
	var slide_index := 0
	
	if not preview_only:
		print("ARRANGE", selected.size())
		undo_redo.create_action("Arrange selected notes by time")
	
	selected.sort_custom(self, "_order_items")
	
	
	for selected_item in selected:
		if selected_item.data is HBBaseNote:
			if not pos_compensation:
				pos_compensation = selected_item.data.position
				
				if selected_item.data is HBSustainNote:
					time_compensation = selected_item.data.end_time
				else: 
					time_compensation = selected_item.data.time
				
				if selected_item.data is HBNoteData and selected_item.data.is_slide_note() and autoslide:
					slide_index = 1
				
				continue
			
			if selected_item.data is HBNoteData and selected_item.data.is_slide_note() and autoslide:
				slide_index = 1
			elif selected_item.data is HBNoteData and slide_index and selected_item.data.is_slide_hold_piece():
				slide_index += 1
			elif slide_index:
				slide_index = 0
			
			# Real snapping hours
			var diff = max(selected_item.data.time - time_compensation, 0)
			var new_pos = pos_compensation + (separation * (float(diff) / float(interval * 1000.0)))
			
			if selected_item.data is HBNoteData and selected_item.data.is_slide_hold_piece() and slide_index and autoslide:
				if slide_index == 2:
					new_pos = pos_compensation + separation / 2
				else:
					new_pos = pos_compensation + slide_separation
			
			if not preview_only:
				undo_redo.add_do_property(selected_item.data, "position", new_pos)
				undo_redo.add_undo_property(selected_item.data, "position", selected_item.data.position)
			
				undo_redo.add_do_method(selected_item, "update_widget_data")
				undo_redo.add_undo_method(selected_item, "update_widget_data")
			else:
				selected_item.data.position = new_pos
				selected_item.update_widget_data()
			
			pos_compensation = new_pos
			if selected_item.data is HBSustainNote:
				time_compensation = selected_item.data.end_time
			elif diff > 0:
				time_compensation = selected_item.data.time
	
	if not preview_only:
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_method(self, "_on_timing_points_changed")
	
		undo_redo.commit_action()
#	inspector.update_value()

func add_button_to_tools_tab(button: BaseButton):
	$VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Tools/PluginButtons/ScrollContainer/PluginButtonsVBox.add_child(button)
func add_tool_to_tools_tab(tool_control: Control):
	$VBoxContainer/VSplitContainer/HBoxContainer/Control/TabContainer2/Tools/PluginButtons/ScrollContainer/PluginButtonsVBox.add_child(tool_control)
func _on_layer_visibility_changed(visibility: bool, layer_name: String):
	song_editor_settings.set_layer_visibility(visibility, layer_name)

func show_error(error: String):
	$Popups/PluginErrorDialog.rect_size = Vector2.ZERO
	$Popups/PluginErrorDialog.dialog_text = error
	$Popups/PluginErrorDialog.popup_centered_minsize(Vector2(0, 0))

func _on_auto_multi_toggled(button_pressed):
	song_editor_settings.auto_multi = button_pressed

# PLAYTEST SHIT
func _on_PlaytestButton_pressed(at_time):
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
	var voice_stream = null
	if current_song.voice:
		voice_stream = game_playback.voice_audio_stream_player.stream
	rhythm_game_playtest_popup.set_audio(game_playback.audio_stream_player.stream, voice_stream)
	rhythm_game_playtest_popup.play_song_from_position(current_song, get_chart(), play_time / 1000.0)

func _on_playtest_quit():
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	playtesting = false
	$VBoxContainer.show()
	remove_child(rhythm_game_playtest_popup)
	game_playback._on_timing_params_changed()
	rhythm_game.set_process_input(true)
	

func create_lyrics_event(event_obj: HBTimingPoint):
	var ev_layer = null
	for layer in timeline.get_layers():
		if layer.layer_name == "Lyrics":
			ev_layer = layer
			break
	var timeline_item = event_obj.get_timeline_item() as EditorLyricPhraseTimelineItem
	timeline_item.connect("phrases_changed", self, "sync_lyrics")
	user_create_timing_point(ev_layer, timeline_item)
	sync_lyrics()
func _create_lyrics_phrase():
	pass
#	print("LYRIC!")
#	var timing_point := HBLyricsPhrase.new()
#
#	var starter_lyric = HBLyricsLyric.new()
#	starter_lyric.time = playhead_position+1
#
#	timing_point.time = playhead_position
#	timing_point.end_time = playhead_position + 100
#	timing_point.lyrics = [starter_lyric]
#	var ev_layer = null
#	for layer in timeline.get_layers():
#		if layer.layer_name == "Lyrics":
#			ev_layer = layer
#			break
#	# Event layer is the last one
#	user_create_timing_point(ev_layer, timing_point.get_timeline_item())


func _create_lyrics_phrase_start():
	var obj = HBLyricsPhraseStart.new()
	obj.time = playhead_position
	create_lyrics_event(obj)

func _create_lyrics_phrase_end():
	var obj = HBLyricsPhraseEnd.new()
	obj.time = playhead_position
	create_lyrics_event(obj)

func _create_lyric():
	var obj = HBLyricsLyric.new()
	obj.time = playhead_position
	create_lyrics_event(obj)

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
	
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		for item in _removed_items:
			item.queue_free()
		if not playtesting:
			if not rhythm_game_playtest_popup.is_queued_for_deletion() and not rhythm_game_playtest_popup.is_inside_tree():
				rhythm_game_playtest_popup.queue_free()


func get_hold_size(data):
	if not data is HBNoteData or not data.hold or not song_editor_settings.hold_calculator:
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
	if not song_editor_settings.hold_calculator:
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


func _on_CreateIntroSkipMarkerButton_pressed():
	add_event_timing_point(HBIntroSkipMarker)


func open_link(link: String):
	OS.shell_open(link)

func _on_WaveformButton_toggled(button_pressed):
	song_editor_settings.waveform = button_pressed
	timeline.set_waveform(song_editor_settings.waveform)


func _on_TimeArrangeSeparationSpinbox_value_changed(value):
	song_editor_settings.separation = value


func _on_TimeArrangeDiagonalAngleSpinbox_value_changed(value):
	song_editor_settings.diagonal_angle = value


func _on_AutoSlideCheckBox_toggled(button_pressed):
	song_editor_settings.autoslide = button_pressed


func _on_SexButton_pressed():
	$SexDialog.popup_centered()


func _on_HoldCalculatorCheckBox_toggled(button_pressed):
	song_editor_settings.hold_calculator = button_pressed
	for item in get_timeline_items():
		if item.data is HBNoteData and item.data.hold:
			item.update()


func  _on_arrange_diagonals_pressed(quadrant):
	var angle_offset = 180 if quadrant in [1, 2] else 0
	var _sign = 1 if quadrant in [1, 3] else -1
	var angle = deg2rad(angle_offset + _sign * time_arrange_diagonal_angle_spinbox.value)
	
	arrange_selected_notes_by_time(angle)


func _on_TimeArrangeSnapsSpinbox_value_changed(value):
	song_editor_settings.arranger_snaps = value
	arrange_menu.rotation_snaps = value


func _on_AutoPlaceCheckBox_toggled(button_pressed):
	song_editor_settings.autoplace = button_pressed
