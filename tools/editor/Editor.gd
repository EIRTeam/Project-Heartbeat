extends Control

class_name HBEditor

signal scale_changed(prev_scale, scale)
signal playhead_position_changed
signal load_song(song)
signal timing_information_changed

const EDITOR_LAYER_SCENE = preload("res://tools/editor/EditorLayer.tscn")
const EDITOR_TIMELINE_ITEM_SCENE = preload("res://tools/editor/timeline_items/EditorTimelineItemSingleNote.tscn")
const EDITOR_PLUGINS_DIR = "res://tools/editor/editor_plugins"
onready var save_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/SaveButton")
onready var save_as_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/SaveAsButton")
onready var timeline = get_node("VBoxContainer/VSplitContainer/EditorTimelineContainer/EditorTimeline")
onready var rhythm_game = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/RythmGame")

onready var audio_stream_player = get_node("AudioStreamPlayer")
onready var audio_stream_player_voice = get_node("AudioStreamPlayerVoice")
onready var game_preview = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview")
onready var metre_option_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/MetreOptionButton")
onready var BPM_spinbox = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/BPMSpinBox")
onready var grid_renderer = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Preview/GamePreview/GridRenderer")
onready var inspector = get_node("VBoxContainer/VSplitContainer/HBoxContainer/TabContainer/Inspector")
onready var angle_arrange_spinbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/TabContainer2/Arrange/MarginContainer/VBoxContainer/VBoxContainer/AngleArrangeSpinbox")
onready var time_arrange_hv_spinbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/TabContainer2/Arrange/MarginContainer/VBoxContainer/TimeArrangeHVSeparationSpinbox")
onready var time_arrange_diagonal_separation_x_spinbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/TabContainer2/Arrange/MarginContainer/VBoxContainer/HBoxContainer/TimeArrangeDiagonalSeparationXSpinbox")
onready var time_arrange_diagonal_separation_y_spinbox = get_node("VBoxContainer/VSplitContainer/HBoxContainer/TabContainer2/Arrange/MarginContainer/VBoxContainer/HBoxContainer/TimeArrangeDiagonalSeparationYSpinbox")
onready var layer_manager = get_node("VBoxContainer/VSplitContainer/HBoxContainer/TabContainer2/Layers/LayerManager")
onready var current_title_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/CurrentTitleButton")
onready var open_chart_popup_dialog = get_node("OpenChartPopupDialog")
const LOG_NAME = "HBEditor"

var playhead_position := 0
var scale = 1.5 # Seconds per 500 pixels
var selected: Array
var time_begin
var time_delay
var _audio_play_offset
var bpm = 150 setget set_bpm, get_bpm
var current_song: HBSong
var current_difficulty: String
var snap_to_grid_enabled = true

var timeline_snap_enabled = true
	
var undo_redo = UndoRedo.new()

var song_editor_settings: HBPerSongEditorSettings = HBPerSongEditorSettings.new()
	
var plugins = []
	
func set_bpm(value):
	BPM_spinbox.value = value

func get_bpm():
	return BPM_spinbox.value
	
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
				else:
					Log.log(self, "Error loading editor plugin %s: File not found" % [dir_name])
			dir_name = dir.get_next()
	
func _ready():
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	get_viewport()
	timeline.editor = self
	
	rhythm_game.set_process_unhandled_input(false)
#	seek(0)
	inspector.connect("property_changed", self, "_change_selected_property")
	inspector.connect("property_change_committed", self, "_commit_selected_property_change")
	
	Diagnostics.hide_WIP_label()
	layer_manager.connect("layer_visibility_changed", timeline, "change_layer_visibility")
	layer_manager.connect("layer_visibility_changed", self, "_on_layer_visibility_changed")
#	load_song(SongLoader.songs["sands_of_time"], "easy")
	load_plugins()
	_show_open_chart_dialog()
	# You HAVE to open a chart, this ensures that if no chart is selected we return
	# to the main menu
	open_chart_popup_dialog.get_cancel().connect("pressed", self, "_on_ExitDialog_confirmed")
	open_chart_popup_dialog.connect("chart_selected", self, "load_song")
func _show_open_chart_dialog():
	open_chart_popup_dialog.popup_centered_minsize(Vector2(600, 250))
	
func _unhandled_input(event):
	if event.is_action_pressed("gui_undo"):
		get_tree().set_input_as_handled()
		undo_redo.undo()
	if event.is_action_pressed("gui_redo"):
		get_tree().set_input_as_handled()
		undo_redo.redo()
	var prev_scale = scale
	if timeline.get_global_rect().has_point(get_global_mouse_position()):
		if event.is_action_pressed("editor_scale_down"):
			get_tree().set_input_as_handled()
			scale += 0.5
			scale = max(scale, 0.1)
			emit_signal("scale_changed", prev_scale, scale)
		if event.is_action_pressed("editor_scale_up"):
			get_tree().set_input_as_handled()
			scale -= 0.5
			scale = max(scale, 0.1)
			emit_signal("scale_changed", prev_scale, scale)
	if event.is_action_pressed("editor_delete"):
		if selected:
			get_tree().set_input_as_handled()
			delete_selected()
	if event.is_action_pressed("editor_play"):
		if not audio_stream_player.playing:
			_on_PlayButton_pressed()
		else:
			_on_PauseButton_pressed()
func _note_comparison(a, b):
	return a.time > b.time

func get_timing_points():
	var points = []
	var layers = timeline.get_layers()
	for layer in layers:
		points += layer.get_timing_points()
	points.sort_custom(self, "_note_comparison")
	return points
	
func scale_msec(msec: int) -> float:
	return ((msec/1000.0)/scale)*500.0

# pixels to msec
func scale_pixels(pixels: float) -> float:
	return (pixels * scale / 500) * 1000.0

func select_item(item: EditorTimelineItem, add = false):
	if item in selected:
		return
	if selected.size() > 0 and not add:
		for selected_item in selected:
			selected_item.deselect()
	if add:
		selected.append(item)
	else:
		selected = [item]
	if get_focus_owner():
		get_focus_owner().release_focus()
	item.select()
	var widget := item.get_editor_widget()
	if widget:
		var widget_instance = widget.instance() as HBEditorWidget
		widget_instance.editor = self
		item.connect_widget(widget_instance)
		game_preview.widget_area.add_child(widget_instance)
	inspector.inspect(item)
func get_song_duration():
	return int(audio_stream_player.stream.get_length() * 1000.0)
func add_item(layer_n: int, item: EditorTimelineItem):

	var layers = timeline.get_layers()
	var layer = layers[layer_n]
	add_item_to_layer(layer, item)
	
# property values for continuously updating undo_redo actions like angle changes
var old_property_values = {}
	
# Changes the selected property by an amount, but doesn't commit it to undo_redo, to
# prevent creating more undo_redo actions than necessary
func _change_selected_property_delta(property_name: String, new_value):
	for selected_item in selected:
		if not selected_item in old_property_values:
			old_property_values[selected_item] = {}
		
		if not property_name in old_property_values[selected_item]:
			old_property_values[selected_item][property_name] = selected_item.data.get(property_name)
		selected_item.data.set(property_name, selected_item.data.get(property_name) + new_value)
		selected_item.update_widget_data()
	_on_timing_points_changed()
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
	_on_timing_points_changed()
	
func _commit_selected_property_change(property_name: String):
	var action_name = "Note " + property_name + " change commited"
	
	print(action_name)
	undo_redo.create_action(action_name)
	for selected_item in selected:
		if old_property_values.has(selected_item):
			if old_property_values[selected_item].has(property_name):
				
				undo_redo.add_do_property(selected_item.data, property_name, selected_item.data.get(property_name))
				undo_redo.add_do_method(self, "_on_timing_points_changed")
				undo_redo.add_do_method(selected_item._layer, "place_child", selected_item)
				undo_redo.add_do_method(selected_item, "update_widget_data")

				undo_redo.add_undo_property(selected_item.data, property_name, old_property_values[selected_item][property_name])
				undo_redo.add_undo_method(self, "_on_timing_points_changed")
				undo_redo.add_undo_method(selected_item._layer, "place_child", selected_item)
				undo_redo.add_undo_method(selected_item, "update_widget_data")
	undo_redo.commit_action()
	inspector.sync_value(property_name)
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
	inspector.update_values()
	
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
	layer.add_item(item)
	
func add_event_timing_point(timing_point_class: GDScript):
	var timing_point := timing_point_class.new() as HBTimingPoint
	timing_point.time = playhead_position
	# Event layer is the last one
	user_create_timing_point(timeline.get_layers()[-1], timing_point.get_timeline_item())
func play_from_pos(position: float):
	rhythm_game.previewing = true
	audio_stream_player.stream_paused = false
	audio_stream_player.volume_db = 0
	audio_stream_player.play()
	audio_stream_player.seek(position / 1000.0)
	audio_stream_player_voice.stream_paused = false
	if current_song.voice:
		audio_stream_player_voice.volume_db = 0
	audio_stream_player_voice.play()
	audio_stream_player_voice.seek(position / 1000.0)
	time_begin = OS.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	_audio_play_offset = position / 1000.0
	playhead_position = max(position, 0.0)
	emit_signal("playhead_position_changed")

func _process(delta):
	var time = 0.0
	if audio_stream_player.playing:
		time = (OS.get_ticks_usec() - time_begin) / 1000000.0
		# Compensate for latency.
		time -= time_delay
		# May be below 0 (did not being yet).
		time = max(0, time)
		
		time = time + _audio_play_offset
		rhythm_game.time = time
	
	if audio_stream_player.playing and not audio_stream_player.stream_paused:
		playhead_position = max(time * 1000.0, 0.0)
		emit_signal("playhead_position_changed")

func seek(value: int):
	playhead_position = clamp(max(value, 0.0), timeline._offset, 1010000000)
	if not audio_stream_player.playing:
		pause()
	else:
		play_from_pos(playhead_position)
		
	rhythm_game.time = playhead_position / 1000.0
	emit_signal("playhead_position_changed")
	rhythm_game.remove_all_notes_from_screen()
#	_on_timing_points_changed()
			
func delete_selected():
	if selected.size() > 0:
		if inspector.inspecting_item in selected:
			inspector.stop_inspecting()
	undo_redo.create_action("Delete notes")
	
	for selected_item in selected:
		selected_item.deselect()
		undo_redo.add_do_method(selected_item._layer, "remove_item", selected_item)
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_method(self, "add_item_to_layer", selected_item._layer, selected_item)
		undo_redo.add_undo_method(self, "_on_timing_points_changed")
	selected = []
	undo_redo.commit_action()

func user_create_timing_point(layer, item: EditorTimelineItem):
	undo_redo.create_action("Add new timing point")
	undo_redo.add_do_method(self, "add_item_to_layer", layer, item)
	undo_redo.add_do_method(self, "_on_timing_points_changed")
	undo_redo.add_undo_method(layer, "remove_item", item)
	undo_redo.add_undo_method(item, "deselect")
	undo_redo.add_undo_method(self, "_on_timing_points_changed")
	undo_redo.commit_action()
			
func _create_bpm_change():
	add_event_timing_point(HBBPMChange)
func pause():
	audio_stream_player.stream_paused = true
	audio_stream_player.volume_db = -80
	audio_stream_player.stop()
	audio_stream_player_voice.stream_paused = true
	audio_stream_player_voice.volume_db = -80
	audio_stream_player_voice.stop()
#	_on_timing_points_changed()
	rhythm_game.previewing = false
func _on_PauseButton_pressed():
	pause()


func _on_PlayButton_pressed():
	play_from_pos(playhead_position)


func _on_StopButton_pressed():
	play_from_pos(0)
	pause()
	
# Fired when any timing point is changed, gives the game the new data
func _on_timing_points_changed():
	rhythm_game.remove_all_notes_from_screen()
	rhythm_game.current_bpm = current_song.bpm # We reset the BPM
	rhythm_game.timing_points = get_timing_points()

func get_song_length():
	return audio_stream_player.stream.get_length()

func get_chart():
	var chart = HBChart.new()
	var layer_items = timeline.get_layers()
	chart.editor_settings = song_editor_settings
	var layers = []
	for layer in layer_items:
		layers.append({
			"name": layer.layer_name,
			"timing_points": layer.get_timing_points()
		})
	chart.layers = layers
	return chart
func serialize_chart():
	return get_chart().serialize()

func from_chart(chart: HBChart):
	timeline.clear_layers()
	undo_redo.clear_history()
	song_editor_settings = HBPerSongEditorSettings.new()
	selected = []
	layer_manager.clear_layers()
	for layer in chart.layers:
		var layer_scene = EDITOR_LAYER_SCENE.instance()
		layer_scene.layer_name = layer.name
		timeline.add_layer(layer_scene)
		var layer_n = timeline.get_layers().size()-1
		for item_d in layer.timing_points:
			var item = item_d.get_timeline_item()
			item.data = item_d
			add_item(layer_n, item)
			
		var layer_visible = not layer.name in chart.editor_settings.hidden_layers
		layer_manager.add_layer(layer.name, layer_visible)
		timeline.change_layer_visibility(layer_visible, layer.name)
	_on_timing_points_changed()
	# Disconnect the cancel action in the chart open dialog, because we already have at least
	# a chart loaded
	if open_chart_popup_dialog.get_cancel().is_connected("pressed", self, "_on_ExitDialog_confirmed"):
		open_chart_popup_dialog.get_cancel().disconnect("pressed", self, "_on_ExitDialog_confirmed")


func _on_SaveSongSelector_chart_selected(song_id, difficulty):
	var song = SongLoader.songs[song_id]
	var chart_path = song.get_chart_path(difficulty)
	var file = File.new()
	file.open(chart_path, File.WRITE)
	file.store_string(JSON.print(serialize_chart(), "  "))

func load_song(song: HBSong, difficulty: String):
	rhythm_game.current_bpm = song.bpm
	var chart_path = song.get_chart_path(difficulty)
	var file = File.new()
	var dir = Directory.new()
	var chart = HBChart.new()
	if dir.file_exists(chart_path):
		file.open(chart_path, File.READ)
		
		var chart_json = JSON.parse(file.get_as_text())
		if chart_json.error == OK:
			var result = chart_json.result
			chart = HBChart.new()
			chart.deserialize(result)
	current_song = song
	from_chart(chart)
	OS.set_window_title("Project Heartbeat - " + song.get_visible_title() + " - " + difficulty.capitalize())
	current_title_button.text = "%s (%s)" % [song.get_visible_title(), difficulty.capitalize()]
	BPM_spinbox.value = song.bpm

	current_difficulty = difficulty
	save_button.disabled = false
	save_as_button.disabled = false
	audio_stream_player.stream = song.get_audio_stream()
	if song.voice:
		audio_stream_player_voice.volume_db = 0
		audio_stream_player_voice.stream = song.get_voice_stream()
	else:
		audio_stream_player_voice.volume_db = -100
	emit_signal("load_song", song)


func _on_ExitDialog_confirmed():
	Diagnostics.show_WIP_label()
	get_tree().change_scene_to(load("res://menus/MainMenu3D.tscn"))

func get_beats_per_bar():
	match metre_option_button.selected:
		0:
			return 4
		1:
			return 3
		2:
			return 2
		3:
			return 1

func get_note_resolution():
	return 1/$VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/NoteResolution.value

func get_note_snap_offset():
	return $VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Offset.value

func _on_timing_information_changed(ignoredarg=null):
	emit_signal("timing_information_changed")


func _on_SaveButton_pressed():
	var chart_path = current_song.get_chart_path(current_difficulty)
	var file = File.new()
	file.open(chart_path, File.WRITE)
	file.store_string(JSON.print(serialize_chart(), "  "))


func _on_ShowGridbutton_toggled(button_pressed):
	grid_renderer.visible = button_pressed

func _on_GridSnapButton_toggled(button_pressed):
	snap_to_grid_enabled = button_pressed

func snap_position_to_grid(new_pos: Vector2):
	var final_position = new_pos
	
	if snap_to_grid_enabled:
		new_pos = new_pos / rhythm_game.BASE_SIZE
		final_position.x = round(grid_renderer.vertical * new_pos.x) / float(grid_renderer.vertical)
		final_position.y = round(grid_renderer.horizontal * new_pos.y) / float(grid_renderer.horizontal)
		final_position = final_position * rhythm_game.BASE_SIZE
	return final_position


func _on_TimelineGridSnapButton_toggled(button_pressed):
	timeline_snap_enabled = button_pressed

func snap_time_to_timeline(time):

	if timeline_snap_enabled:
		var bars_per_minute = get_bpm() / float(get_beats_per_bar())
		var seconds_per_bar = 60.0/bars_per_minute
		
		var beat_length = seconds_per_bar / float(get_beats_per_bar())
		var note_length = 1.0/4.0 # a quarter of a beat
		var interval = (get_note_resolution() / note_length) * beat_length
		time -= get_note_snap_offset()*1000.0
		interval = interval * 1000.0
		var n = time / float(interval)
		n = round(n)
		return n*interval + get_note_snap_offset()*1000.0
	else:
		return time

func arrange_selected_by_angle(diff):
	undo_redo.create_action("Arrange selected notes by angle")
	var mult = 0
	var first_angle = null
	for selected_item in selected:
		if not first_angle:
			first_angle = selected_item.data.entry_angle
		undo_redo.add_do_property(selected_item.data, "entry_angle", int(first_angle + diff * mult))
		undo_redo.add_do_method(self, "_on_timing_points_changed")
		undo_redo.add_undo_property(selected_item.data, "entry_angle", selected_item.data.entry_angle)
		undo_redo.add_undo_method(self, "_on_timing_points_changed")
		mult += 1
	inspector.update_values()
	undo_redo.commit_action()
func _on_AngleArrangeButtonPlus_pressed():
	arrange_selected_by_angle(angle_arrange_spinbox.value)


func _on_AngleArrangeButtonMinus_pressed():
	arrange_selected_by_angle(-angle_arrange_spinbox.value)

# Arranges the selected notes in the playarea by a certain distances
func arrange_selected_notes_by_time(direction: Vector2):
	var separation : Vector2 = Vector2.ZERO
	var hv_separation = time_arrange_hv_spinbox.value
	var diagonal_separation_x = time_arrange_diagonal_separation_x_spinbox.value
	var diagonal_separation_y = time_arrange_diagonal_separation_y_spinbox.value
	
	if abs(direction.x) > 0 and abs(direction.y) > 0:
		# We got a diagonal boi
		separation = Vector2(diagonal_separation_x, diagonal_separation_y)
	else:
		separation = Vector2(hv_separation, hv_separation)
	separation *= Vector2(sign(direction.x), sign(direction.y))
	
	var first_note_position : Vector2
	var first_note_time : int
	
	
	var bars_per_minute = get_bpm() / float(get_beats_per_bar())
	var seconds_per_bar = 60/bars_per_minute
	
	var beat_length = seconds_per_bar / float(get_beats_per_bar())
	var note_length = 1.0/4.0 # a quarter of a beat
	var interval = (get_note_resolution() / note_length) * beat_length * 2.0

	undo_redo.create_action("Arrange selected notes by time")
	var ordered_items = []
	
	for selected_item in selected:
		if selected_item.data is HBNoteData:
			if not first_note_position:
				first_note_position = selected_item.data.position
				first_note_time = selected_item.data.time
				continue
				
			# Real snapping hours
			var diff = selected_item.data.time - first_note_time
			var new_pos = first_note_position + (separation * (float(diff) / float(interval * 1000.0)))
			
			undo_redo.add_do_property(selected_item.data, "position", new_pos)
			undo_redo.add_do_method(self, "_on_timing_points_changed")
			undo_redo.add_do_method(selected_item, "update_widget_data")
			
			undo_redo.add_undo_property(selected_item.data, "position", selected_item.data.position)
			undo_redo.add_undo_method(self, "_on_timing_points_changed")
			undo_redo.add_undo_method(selected_item, "update_widget_data")
	undo_redo.commit_action()
#	inspector.update_value()

func add_button_to_tools_tab(button: BaseButton):
	$VBoxContainer/VSplitContainer/HBoxContainer/TabContainer2/Tools/PluginButtons/PluginButtonsVBox.add_child(button)
func add_tool_to_tools_tab(tool_control: Control):
	$VBoxContainer/VSplitContainer/HBoxContainer/TabContainer2/Tools/PluginButtons/PluginButtonsVBox.add_child(tool_control)
func _on_layer_visibility_changed(visibility: bool, layer_name: String):
	song_editor_settings.set_layer_visibility(visibility, layer_name)

func show_error(error: String):
	$PluginErrorDialog.rect_size = Vector2.ZERO
	$PluginErrorDialog.dialog_text = error
	$PluginErrorDialog.popup_centered_minsize(300, 80)
