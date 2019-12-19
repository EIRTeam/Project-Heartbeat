extends Control


signal scale_changed(prev_scale, scale)
signal playhead_position_changed
signal load_song(song)
signal timing_information_changed

const EDITOR_LAYER_SCENE = preload("res://tools/editor/EditorLayer.tscn")
const EDITOR_TIMELINE_ITEM_SCENE = preload("res://tools/editor/timeline_items/EditorTimelineItemSingleNote.tscn")
onready var save_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/SaveButton")
onready var save_as_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/SaveAsButton")
onready var timeline = get_node("VBoxContainer/EditorTimelineContainer/EditorTimeline")
onready var recording_layer_select_button = get_node("VBoxContainer/HBoxContainer/TabContainer/Recording/MarginContainer/VBoxContainer/RecordingLayerSelectButton")
onready var rhythm_game = get_node("VBoxContainer/HBoxContainer/Preview/GamePreview/RythmGame")
onready var waveform_drawer = get_node("VBoxContainer/EditorTimelineContainer/EditorTimeline/VBoxContainer/ScrollContainer/HBoxContainer/Layers/BBCWaveform")
onready var audio_stream_player = get_node("AudioStreamPlayer")
onready var game_preview = get_node("VBoxContainer/HBoxContainer/Preview/GamePreview")
onready var metre_option_button = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/MetreOptionButton")
onready var BPM_spinbox = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/BPMSpinBox")
onready var grid_renderer = get_node("VBoxContainer/HBoxContainer/Preview/GamePreview/GridRenderer")
const LOG_NAME = "HBEditor"

var playhead_position := 0
var scale = 3.0 # Seconds per 500 pixels
var selected: EditorTimelineItem
var recording: bool = false
var time_begin
var time_delay
var _audio_play_offset
var bpm = 150 setget set_bpm, get_bpm
var current_song: HBSong
var current_difficulty: String
var snap_to_grid_enabled = false

var timeline_snap_enabled = false
	
var undo_redo = UndoRedo.new()
	
func set_bpm(value):
	BPM_spinbox.value = value

func get_bpm():
	return BPM_spinbox.value
func _ready():
	MouseTrap.disable_mouse_trap()
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	get_viewport()
	timeline.editor = self
	
	from_chart(HBChart.new())
	
	rhythm_game.set_process_unhandled_input(false)
	seek(0)
#	load_song(SongLoader.songs["sands_of_time"], "easy")
	
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_undo"):
		get_tree().set_input_as_handled()
		undo_redo.undo()
	if event.is_action_pressed("ui_redo"):
		get_tree().set_input_as_handled()
		undo_redo.redo()
	
func get_timing_points():
	var points = []
	var chart = HBChart.new()
	var layers = timeline.get_layers()
	for layer in layers:
		points += layer.get_timing_points()
	return points
	
func get_simplified_timing_points():
	return get_chart().get_simplified_timing_points()
	
func scale_msec(msec: int) -> float:
	return ((msec/1000.0)/scale)*500.0

# pixels to msec
func scale_pixels(pixels: float) -> float:
	return (pixels * scale / 500) * 1000.0

func select_item(item: EditorTimelineItem):
	if selected:
		selected.deselect()
	selected = item
	selected.select()
	var widget := item.get_editor_widget()
	if widget:
		var widget_instance = widget.instance() as HBEditorWidget
		widget_instance.editor = self
		item.connect_widget(widget_instance)
		game_preview.widget_area.add_child(widget_instance)
	$VBoxContainer/HBoxContainer/TabContainer/Inspector.inspect(item)
func get_song_duration():
	return int(audio_stream_player.stream.get_length() * 1000.0)
func add_item(layer_n: int, item: EditorTimelineItem):

	var layers = timeline.get_layers()
	var layer = layers[layer_n]
	add_item_to_layer(layer, item)
	
func add_item_to_layer(layer, item: EditorTimelineItem):
	if item.update_affects_timing_points:
		if not item.is_connected("item_changed", self, "_on_timing_points_changed"):
			item.connect("item_changed", self, "_on_timing_points_changed")
	else:
		if not item.is_connected("item_changed", self, "_on_item_changed"):
			item.connect("item_changed", self, "_on_item_changed")
	layer.add_item(item)
	
func _on_item_changed():
	# Ensure note is in the proper layer
	if selected:
		var note = selected.data
		if note is HBNoteData:
			for layer in timeline.get_layers():
				if note in layer.get_timing_points():
					var note_type_string = HBUtils.find_key(HBNoteData.NOTE_TYPE, note.note_type)
					# We move the note to the proper layer if we find it's not in the correct one
					if not note_type_string == layer.layer_name:
						var found_proper_layer = false
						for l in timeline.get_layers():
							if l.layer_name == note_type_string:
								l.drop_data(null, selected)
								break
						if found_proper_layer:
							break
					else:
						break
	
func add_user_timing_point(timing_point_class: GDScript):
	var timing_point := timing_point_class.new() as HBTimingPoint
	timing_point.time = playhead_position
	add_item(0, timing_point.get_timeline_item())
	_on_timing_points_changed()
func play_from_pos(position: float):
	audio_stream_player.stream_paused = false
	audio_stream_player.volume_db = 0
	audio_stream_player.play()
	audio_stream_player.seek(position / 1000.0)
	time_begin = OS.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	_audio_play_offset = position / 1000.0
	
	playhead_position = max(position, 0.0)
	emit_signal("playhead_position_changed")

func start_recording():
	pass

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
	if recording:
		for type in rhythm_game.NOTE_TYPE_TO_ACTIONS_MAP:
			var actions = rhythm_game.NOTE_TYPE_TO_ACTIONS_MAP[type]
			for action in actions:
				if Input.is_action_just_pressed(action):
					var note = EDITOR_TIMELINE_ITEM_SCENE.instance()
					note.data.time = int(time * 1000)
					note.data.note_type = type
					add_item(recording_layer_select_button.get_selected_id(), note)
					_on_timing_points_changed()

func seek(value: int):
	playhead_position = clamp(max(value, 0.0), timeline._offset, 1010000000)
	if not audio_stream_player.playing:
		pause()
	else:
		play_from_pos(playhead_position)
		
	rhythm_game.time = playhead_position / 1000.0
	
	emit_signal("playhead_position_changed")
	
func _input(event):
	var prev_scale = scale
	if timeline.get_global_rect().has_point(get_global_mouse_position()):
		if event.is_action_pressed("editor_scale_down"):
			scale += 0.5
			scale = max(scale, 0.1)
			emit_signal("scale_changed", prev_scale, scale)
		if event.is_action_pressed("editor_scale_up"):
			scale -= 0.5
			scale = max(scale, 0.1)
			emit_signal("scale_changed", prev_scale, scale)
	if event.is_action_pressed("editor_delete"):
		if selected:
			delete_selected()
			
func delete_selected():
	if selected == $VBoxContainer/HBoxContainer/TabContainer/Inspector.inspecting_item:
		$VBoxContainer/HBoxContainer/TabContainer/Inspector.stop_inspecting()
	selected.deselect()
	undo_redo.create_action("Delete note")
	undo_redo.add_do_reference(selected)
	undo_redo.add_do_method(selected._layer, "remove_item", selected)
	undo_redo.add_do_method(self, "_on_timing_points_changed")
	undo_redo.add_undo_reference(selected)
	undo_redo.add_undo_method("add_item_to_layer", selected._layer, selected)
	undo_redo.add_undo_method(self, "_on_timing_points_changed")
	undo_redo.commit_action()
			
func user_create_timing_point(layer, item: EditorTimelineItem):
	undo_redo.create_action("Add new timing point")
	undo_redo.add_do_reference(item)
	undo_redo.add_do_method(self, "add_item_to_layer", layer, item)
	undo_redo.add_do_method(self, "_on_timing_points_changed")
	undo_redo.add_undo_reference(item)
	undo_redo.add_undo_method(layer, "remove_item", item)
	undo_redo.add_undo_method(self, "_on_timing_points_changed")
	undo_redo.commit_action()
			
func pause():
	recording = false
	audio_stream_player.stream_paused = true
	audio_stream_player.volume_db = -80
	audio_stream_player.stop()
func _on_PauseButton_pressed():
	pause()


func _on_PlayButton_pressed():
	play_from_pos(playhead_position)


func _on_StopButton_pressed():
	recording = false
	play_from_pos(0)
	pause()

func _on_RecordButton_pressed():
	recording = true
	play_from_pos(playhead_position)
	
func _on_timing_points_changed():
	rhythm_game.remove_all_notes_from_screen()
	rhythm_game.timing_points = get_timing_points()

func get_song_length():
	return audio_stream_player.stream.get_length()


func _on_RythmGame_note_updated(note):
	if selected:
		if note == selected.data:
			selected.emit_signal("item_changed")

func get_chart():
	var chart = HBChart.new()
	var layers = timeline.get_layers()
	for layer in layers:
		chart.layers.append({
			"name": layer.layer_name,
			"timing_points": layer.get_timing_points()
		})
	return chart
func serialize_chart():
	return get_chart().serialize()

func from_chart(chart: HBChart):
	timeline.clear_layers()

	selected = null
	for layer in chart.layers:
		var layer_scene = EDITOR_LAYER_SCENE.instance()
		layer_scene.layer_name = layer.name
		timeline.add_layer(layer_scene)
		var layer_n = timeline.get_layers().size()-1
		for item_d in layer.timing_points:
			var item = item_d.get_timeline_item()
			item.data = item_d
			add_item(layer_n, item)
	_on_timing_points_changed()

func _on_SongSelector_chart_selected(song_id, difficulty):
	var song = SongLoader.songs[song_id]
	load_song(song, difficulty)


func _on_SaveSongSelector_chart_selected(song_id, difficulty):
	var song = SongLoader.songs[song_id]
	var chart_path = song.get_chart_path(difficulty)
	var file = File.new()
	file.open(chart_path, File.WRITE)
	file.store_string(JSON.print(serialize_chart(), "  "))
	


func _on_EditorTimeline_layers_changed():

	recording_layer_select_button.clear()
	for layer_i in range(timeline.get_layers().size()):
		var layer = timeline.get_layers()[layer_i]
		recording_layer_select_button.add_item(layer.layer_name, layer_i)
	recording_layer_select_button.select(0)

func load_song(song: HBSong, difficulty: String):
	rhythm_game.current_bpm = song.bpm
	var chart_path = song.get_chart_path(difficulty)
	var file = File.new()
	file.open(chart_path, File.READ)
	
	var chart_json = JSON.parse(file.get_as_text())
	if chart_json.error == OK:
		var result = chart_json.result
		var chart = HBChart.new()
		chart.deserialize(result)
		from_chart(chart)
		OS.set_window_title("Project Heartbeat - " + song.title + " - " + difficulty.capitalize())
		$VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/BPMSpinBox.value = song.bpm
		current_song = song
		current_difficulty = difficulty
		save_button.disabled = false
		save_as_button.disabled = false
	audio_stream_player.stream = HBUtils.load_ogg(song.get_song_audio_res_path())
	emit_signal("load_song", song)


func _on_ExitDialog_confirmed():
	MouseTrap.enable_mouse_trap()
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	get_tree().change_scene_to(load("res://menus/MainMenu3D.tscn"))

func get_beats_per_bar():
	match metre_option_button.selected:
		0:
			return 4
		1:
			return 3
		2:
			return 2

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
	timeline_snap_enabled = true

func snap_time_to_timeline(time):

	if timeline_snap_enabled:
		var bars_per_minute = get_bpm() / float(get_beats_per_bar())
		var seconds_per_bar = 60.0/bars_per_minute
		
		var beat_length = seconds_per_bar / float(get_beats_per_bar())
		var note_length = 1.0/4.0 # a quarter of a beat
		var note_res = get_note_resolution()
		var interval = (get_note_resolution() / note_length) * beat_length
		time -= get_note_snap_offset()*1000.0
		interval = interval * 1000.0
		print(interval, " ", time)
		var n = time / float(interval)
		n = round(n)
		print("FINAL TIME: ", n*interval)
		return n*interval + get_note_snap_offset()*1000.0
	else:
		return time
