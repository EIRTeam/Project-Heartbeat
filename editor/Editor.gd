extends Control

var scale = 15.0 # Seconds per 500 pixels
	
var playhead_position := 0

signal scale_changed(prev_scale, scale)

onready var timeline = get_node("VBoxContainer/EditorTimelineContainer/EditorTimeline")
	
signal playhead_position_changed
signal load_song(song)

const EDITOR_LAYER_SCENE = preload("res://editor/EditorLayer.tscn")
const EDITOR_TIMELINE_ITEM_SCENE = preload("res://editor/timeline_items/EditorTimelineItemSingleNote.tscn")
var selected: EditorTimelineItem
var recording: bool = false
var time_begin
var time_delay
var _audio_play_offset

onready var recording_layer_select_button = get_node("VBoxContainer/HBoxContainer/TabContainer/Recording/MarginContainer/VBoxContainer/RecordingLayerSelectButton")

onready var rhythm_game = get_node("VBoxContainer/HBoxContainer/Preview/GamePreview/RythmGame")

onready var time_slider = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/TimeSlider")

onready var waveform_drawer = get_node("VBoxContainer/EditorTimelineContainer/EditorTimeline/VBoxContainer/ScrollContainer/HBoxContainer/Layers/BBCWaveform")

onready var audio_stream_player = get_node("AudioStreamPlayer")

const LOG_NAME = "HBEditor"

func _ready():
	timeline.editor = self
#	timeline.set_layers_offset(1000)
	timeline.add_layer(EDITOR_LAYER_SCENE.instance())
#	timeline.add_layer(EDITOR_LAYER_SCENE.instance())
#	var test_item = EDITOR_TIMELINE_ITEM_SCENE.instance()
#	test_item.data.time = 1000
#	var test_item2 = EDITOR_TIMELINE_ITEM_SCENE.instance()
#	test_item2.data.time = 2000
#	timeline.get_layers()[0].add_item(test_item)
#	timeline.get_layers()[0].add_item(test_item2)
	rhythm_game.set_process_unhandled_input(false)
	seek(0)
	var data := HBMultiNoteData.new()
	data.time = 1000
	for note in data.get_simplified():
		print(note.time)
	
	load_song_audio(SongLoader.songs["sands_of_time"])
	
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
	$VBoxContainer/HBoxContainer/TabContainer/Inspector.inspect(item)
func get_song_duration():
	return int(audio_stream_player.stream.get_length() * 1000.0)
func add_item(layer_n: int, item: EditorTimelineItem):
	if item.update_affects_timing_points:
		item.connect("item_changed", self, "_on_timing_points_changed")
	var layers = timeline.get_layers()
	var layer = layers[layer_n]
	layer.add_item(item)
	
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
	
	time_slider.max_value = audio_stream_player.stream.get_length()
	if audio_stream_player.playing:
		time = (OS.get_ticks_usec() - time_begin) / 1000000.0
		# Compensate for latency.
		time -= time_delay
		# May be below 0 (did not being yet).
		time = max(0, time)
		
		time = time + _audio_play_offset
		rhythm_game.time = time
	
	time_slider.value = time
	
	if audio_stream_player.playing and not audio_stream_player.stream_paused:
		$VBoxContainer/Panel2/MarginContainer/VBoxContainer/HBoxContainer/CurrentTimeLabel.text = HBUtils.format_time(time * 1000.0)
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
			selected.queue_free()
			_on_timing_points_changed()
			selected = null
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



func _on_test_pressed():
	serialize_chart()

func get_song_length():
	return audio_stream_player.stream.get_length()


func _on_RythmGame_note_selected(note):
	for layer in timeline.get_layers():
		for item in layer.get_editor_items():
			if item.data == note:
				select_item(item)
				return


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
	for layer in chart.layers:
		var layer_scene = EDITOR_LAYER_SCENE.instance()
		timeline.add_layer(layer_scene)
		for item_d in layer.timing_points:
			var item = item_d.get_timeline_item()
			item.data = item_d
			layer_scene.add_item(item)
	_on_timing_points_changed()

func _on_SongSelector_chart_selected(song_id, difficulty):
	var song = SongLoader.songs[song_id]
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
		load_song_audio(song)


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

func load_song_audio(song: HBSong):
	
	emit_signal("load_song", song)
	audio_stream_player.stream = load(song.get_song_audio_res_path())


func _on_ExitDialog_confirmed():
	get_tree().change_scene_to(load("res://menus/MainMenu.tscn"))
