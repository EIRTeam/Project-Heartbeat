extends Control

var scale = 15.0 # Seconds per 500 pixels
	
var playhead_position := 0

signal scale_changed(prev_scale, scale)

onready var timeline = get_node("VBoxContainer/EditorTimelineContainer/EditorTimeline")
	
signal playhead_position_changed
	
const EDITOR_LAYER_SCENE = preload("res://editor/EditorLayer.tscn")
const EDITOR_TIMELINE_ITEM_SCENE = preload("res://editor/timeline_items/EditorTimelineItemSingleNote.tscn")
var selected: EditorTimelineItem
var recording: bool = false
var time_begin
var time_delay
var _audio_play_offset

onready var rhythm_game = get_node("VBoxContainer/HBoxContainer/Preview/GamePreview/RythmGame")

func _ready():
	timeline.editor = self
	timeline.set_layers_offset(1000)
	timeline.add_layer(EDITOR_LAYER_SCENE.instance())
	timeline.add_layer(EDITOR_LAYER_SCENE.instance())
	var test_item = EDITOR_TIMELINE_ITEM_SCENE.instance()
	test_item.data.time = 1000
	var test_item2 = EDITOR_TIMELINE_ITEM_SCENE.instance()
	test_item2.data.time = 2000
	timeline.get_layers()[0].add_item(test_item)
	timeline.get_layers()[0].add_item(test_item2)
	rhythm_game.set_process_unhandled_input(false)
	seek(0)
	
func get_timing_points():
	var points = []
	var chart = HBChart.new()
	var layers = timeline.get_layers()
	for layer in layers:
		points += layer.get_timing_points()
	return points
	
func scale_msec(msec: int) -> float:
	return ((msec/1000.0)/scale)*500.0

# pixels to msec
func scale_pixels(pixels: float) -> float:
	return (pixels * scale / 500) * 1000.0

func select_item(item: EditorTimelineItem):
	if selected:
		selected.deselect()
	selected = item
	$VBoxContainer/HBoxContainer/TabContainer/Inspector.inspect(item)
func get_song_duration():
	return int($AudioStreamPlayer.stream.get_length() * 1000.0)
func add_item(layer_n: int, item: EditorTimelineItem):
	var layers = timeline.get_layers()
	var layer = layers[layer_n]
	layer.add_item(item)

func play_from_pos(position: float):
	$AudioStreamPlayer.stream_paused = false
	$AudioStreamPlayer.volume_db = 0
	$AudioStreamPlayer.play()
	$AudioStreamPlayer.seek(position / 1000.0)
	time_begin = OS.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	_audio_play_offset = position / 1000.0
	
	playhead_position = max(position, 0.0)
	emit_signal("playhead_position_changed")

func start_recording():
	pass

func _process(delta):
	var time = 0.0
	if $AudioStreamPlayer.playing:
		time = (OS.get_ticks_usec() - time_begin) / 1000000.0
		# Compensate for latency.
		time -= time_delay
		# May be below 0 (did not being yet).
		time = max(0, time)
		
		time = time + _audio_play_offset
		rhythm_game.time = time
	if $AudioStreamPlayer.playing and not $AudioStreamPlayer.stream_paused:
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
					add_item(0, note)
					_on_timing_points_changed()

func seek(value: int):
	playhead_position = clamp(max(value, 0.0), timeline._offset, 1010000000)
	if not $AudioStreamPlayer.playing:
		pause()
	else:
		play_from_pos(playhead_position)
		
	rhythm_game.time = playhead_position / 1000.0
	
	emit_signal("playhead_position_changed")
	
func _input(event):
	var prev_scale = scale
	if get_global_rect().has_point(get_global_mouse_position()):
		if event.is_action_pressed("editor_scale_down"):
			scale += 0.5
			scale = max(scale, 0.1)
			emit_signal("scale_changed", prev_scale, scale)
		if event.is_action_pressed("editor_scale_up"):
			scale -= 0.5
			scale = max(scale, 0.1)
			emit_signal("scale_changed", prev_scale, scale)
func pause():
	recording = false
	$AudioStreamPlayer.stream_paused = true
	$AudioStreamPlayer.volume_db = -80
	$AudioStreamPlayer.stop()
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
	rhythm_game.timing_points = get_timing_points()
	rhythm_game.remove_all_notes_from_screen()


func serialize_chart():
	var chart = HBChart.new()
	var layers = timeline.get_layers()
	for layer in layers:
		chart.layers.append({
			"name": layer.layer_name,
			"timing_points": layer.get_timing_points()
		})
	print(chart.serialize())
func _on_test_pressed():
	serialize_chart()

func get_song_length():
	return $AudioStreamPlayer.stream.get_length()
