extends Control

var editor
const EDITOR_LAYER_SCENE = preload("res://editor/EditorLayer.tscn")
onready var layers = get_node("VBoxContainer/ScrollContainer/HBoxContainer/Layers/LayerControl")
onready var layer_names = get_node("VBoxContainer/ScrollContainer/HBoxContainer/VBoxContainer/LayerNames")
signal offset_changed(offset)
const LAYER_NAME_SCENE = preload("res://editor/EditorLayerName.tscn")
onready var playhead_area = get_node("VBoxContainer/HBoxContainer/PlayheadArea")
var _offset = 0
var _prev_playhead_position = Vector2()
onready var waveform_drawer = get_node("VBoxContainer/ScrollContainer/HBoxContainer/Layers/BBCWaveform")
signal layers_changed
func _ready():
	update()
	connect("resized", self, "_on_viewport_size_changed")

	
func _on_viewport_size_changed():
	# HACK: On linux we wait one frame because the size transformation doesn't
	# get applied on time, user should not notice this
	yield(get_tree(), "idle_frame")
	update()
	
	
func _draw_timing_line_interval(interval, line_scale=0.5, offset=0):
	var lines = int(editor.get_song_length() / interval)
	lines -= ceil(offset / interval)
	for line in range(lines):
		var starting_rect_pos = playhead_area.rect_position + Vector2(layers.rect_position.x, 0) + Vector2(editor.scale_msec((offset)*1000), 0)
		starting_rect_pos += Vector2(editor.scale_msec((line*interval)*1000), 0)
		draw_line(starting_rect_pos, starting_rect_pos + Vector2(0, playhead_area.rect_size.y * line_scale), Color.white, 1.0, false)
	
func _draw_timing_label():
	pass
	
func _draw_timing_lines():
	_draw_timing_line_interval(1, 0.5)
	#_draw_timing_line_interval(5, 0.75, 2.5)
	
func _draw():
	scale_waveform()
	_draw_playhead()
	_draw_timing_lines()
func calculate_playhead_position():
	return Vector2((playhead_area.rect_position.x + layers.rect_position.x + editor.scale_msec(editor.playhead_position)), 0.0)

func _draw_playhead():
	var playhead_pos = calculate_playhead_position()
	_prev_playhead_position = playhead_pos
	draw_line(playhead_pos, playhead_pos+Vector2(0.0, rect_size.y), Color(1.0, 0.0, 0.0), 1.0)

func add_layer(layer):
	layer.editor = editor
	layers.add_child(layer)
	var lns = LAYER_NAME_SCENE.instance()
	lns.layer_name = layer.layer_name
	layer_names.add_child(lns)
	scale_layers()
	emit_signal("layers_changed")


func get_layers():
	return layers.get_children()


func _on_PlayheadArea_mouse_x_input(value):
	editor.seek(clamp(editor.scale_pixels(int(value)) + _offset, _offset, editor.get_song_length()*1000.0))

func _on_playhead_position_changed():
	update()
	$VBoxContainer/HBoxContainer/PlayheadPosText/Label.text = HBUtils.format_time(editor.playhead_position)
var _prev_layers_rect_position
func set_layers_offset(ms: int):
	_offset = max(ms, 0)
	layers.rect_position.x = -editor.scale_msec(ms)
	#print("pos", layers.rect_position.x)
	_prev_layers_rect_position = layers.rect_position
	emit_signal("offset_changed")
	update()

func scale_layers():
	print("SCALING LAYER TO", editor.scale_msec(editor.get_song_length() * 1000.0))
	layers.rect_size.x = editor.scale_msec(editor.get_song_length() * 1000.0)

func _on_Editor_scale_changed(prev_scale, scale):
	print("scale change", (scale/prev_scale))
	var new_offset = _offset * (scale/prev_scale)
	var diff = _prev_playhead_position.x - calculate_playhead_position().x
	set_layers_offset(new_offset - editor.scale_pixels(diff))
	
	for layer in layers.get_children():
		layer.place_all_children()
	scale_layers()
		
	update()
	
func _input(event):
	if event is InputEventMouseMotion:
		if get_global_rect().has_point(get_global_mouse_position()):
			if Input.is_action_pressed("editor_pan"):
				set_layers_offset(_offset - editor.scale_pixels(event.relative.x))


func _on_NewLayerButton_pressed():
	add_layer(EDITOR_LAYER_SCENE.instance())
	
func _on_new_song_loaded(song: HBSong):
	var file := File.new()
	if file.file_exists(song.get_waveform_path()):
		file.open(song.get_waveform_path(), File.READ)
		
		var result = JSON.parse(file.get_as_text())
		if result.error == OK:
			waveform_drawer.waveform_data = result.result
	else:
		Log.log(self, "Error loading song waveform %s" % [song.get_waveform_path()], Log.LogLevel.ERROR)
	scale_waveform()
func scale_waveform():
	var song_length = editor.audio_stream_player.stream.get_length()
	waveform_drawer.min_position = (clamp(editor.scale_pixels(int(0)) + _offset, _offset, editor.get_song_length()*1000.0) / 1000.0) / editor.audio_stream_player.stream.get_length()
	waveform_drawer.max_position = (clamp(editor.scale_pixels(int(waveform_drawer.rect_size.x)) + _offset, _offset, editor.get_song_length()*1000.0) / 1000.0) / editor.audio_stream_player.stream.get_length()
	waveform_drawer.min_position = waveform_drawer.min_position * 2.0
	waveform_drawer.max_position = waveform_drawer.max_position * 2.0
func clear_layers():
	for layer in layers.get_children():
		layer.queue_free()
	for layer_name in layer_names.get_children():
		layer_name.queue_free()
