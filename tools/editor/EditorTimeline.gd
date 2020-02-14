extends Control

var editor
const EDITOR_LAYER_SCENE = preload("res://tools/editor/EditorLayer.tscn")
onready var layers = get_node("VBoxContainer/ScrollContainer/HBoxContainer/Layers/LayerControl")
onready var layer_names = get_node("VBoxContainer/ScrollContainer/HBoxContainer/VBoxContainer/LayerNames")
signal offset_changed(offset)
const LAYER_NAME_SCENE = preload("res://tools/editor/EditorLayerName.tscn")
onready var playhead_area = get_node("VBoxContainer/HBoxContainer/PlayheadArea")
var _offset = 0
var _prev_playhead_position = Vector2()
signal layers_changed
const LOG_NAME = "Editor"

const TRIANGLE_HEIGHT = 15
func _ready():
	update()
	connect("resized", self, "_on_viewport_size_changed")

	
func _on_viewport_size_changed():
	# HACK: On linux we wait one frame because the size transformation doesn't
	# get applied on time, user should not notice this
	yield(get_tree(), "idle_frame")
	update()
	
	
func _draw_bars(interval, offset=0):
	var lines = int(editor.get_song_length() / interval)
	lines -= ceil(offset / interval)
	for line in range(lines):
		var starting_rect_pos = playhead_area.rect_position + Vector2(layers.rect_position.x, 0) + Vector2(editor.scale_msec((offset)*1000), 0)
		starting_rect_pos += Vector2(editor.scale_msec((line*interval)*1000), 0)
		var pos_sec = line*interval
		if abs(_offset) > (line*interval) * 1000.0:
			continue
		draw_line(starting_rect_pos, starting_rect_pos + Vector2(0, rect_size.y), Color(1.0, 1.0, 0.0, 1.0), 1.0, false)
	
func _draw_interval(interval, offset=0, ignore_interval=null):
	var lines = int(editor.get_song_length() / interval)
	lines -= ceil(offset / interval)
	for line in range(lines):
		var starting_rect_pos = playhead_area.rect_position + Vector2(0, 10) + Vector2(layers.rect_position.x, 0) + Vector2(editor.scale_msec((offset)*1000), 0)
		starting_rect_pos += Vector2(editor.scale_msec((line*interval)*1000), 0)
		
		var pos_sec = line*interval
		if abs(_offset) > (line*interval) * 1000.0:
			continue
		if ignore_interval and ignore_interval > 0:
			if is_equal_approx(fmod(pos_sec, ignore_interval), 0) or line == 0:
				continue
			
		draw_line(starting_rect_pos, starting_rect_pos + Vector2(0, rect_size.y), Color(0.5, 0.5, 0.5), 1.0, false)
	
func _draw_timing_lines():
	var bars_per_minute = editor.bpm / float(editor.get_beats_per_bar())
	var seconds_per_bar = 60/bars_per_minute
	
	var beat_length = seconds_per_bar / float(editor.get_beats_per_bar())
	var note_length = 1.0/4.0 # a quarter of a beat
	var note_res = editor.get_note_resolution()
	var interval = (editor.get_note_resolution() / note_length) * beat_length
	
	_draw_interval(interval, editor.get_note_snap_offset(), seconds_per_bar)
	_draw_bars(seconds_per_bar, editor.get_note_snap_offset())
	#_draw_timing_line_interval(5, 0.75, 2.5)
	
func _draw():
	_draw_playhead()
	_draw_timing_lines()
func calculate_playhead_position():
	return Vector2((playhead_area.rect_position.x + layers.rect_position.x + editor.scale_msec(editor.playhead_position)), 0.0)

func _draw_playhead():
	if editor.playhead_position > _offset:
		var playhead_pos = calculate_playhead_position()
		_prev_playhead_position = playhead_pos
	
		draw_line(playhead_pos + Vector2(0, playhead_area.rect_size.y), playhead_pos+Vector2(0.0, rect_size.y), Color(1.0, 0.0, 0.0), 1.0)
		
		# Draw playhead triangle
		var point1 = playhead_pos + Vector2(0, playhead_area.rect_size.y)
		var point2 = playhead_pos + Vector2(TRIANGLE_HEIGHT/2.0, playhead_area.rect_size.y - TRIANGLE_HEIGHT)
		var point3 = playhead_pos + Vector2(-TRIANGLE_HEIGHT/2.0, playhead_area.rect_size.y - TRIANGLE_HEIGHT)
		
		draw_colored_polygon(PoolVector2Array([point1, point2, point3]), Color.red, PoolVector2Array(), null, null, true)

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
	set_layers_offset(max(new_offset - editor.scale_pixels(diff), 0))
	
	for layer in layers.get_children():
		layer.place_all_children()
	scale_layers()
		
	update()
	
func _input(event):
	if event is InputEventMouseMotion:
		if get_global_rect().has_point(get_global_mouse_position()):
			if Input.is_action_pressed("editor_pan"):
				set_layers_offset(max(_offset - editor.scale_pixels(event.relative.x), 0))
	
func _on_new_song_loaded(song: HBSong):
	var file := File.new()
func clear_layers():
	for layer in layers.get_children():
		layer.free()
	for layer_name in layer_names.get_children():
		layer_name.free()


func _on_timing_information_changed():
	update()

func change_layer_visibility(visibility: bool, layer_name: String):
	for layer in layers.get_children():
		if layer.layer_name == layer_name:
			layer.visible = visibility
	for layer_n in layer_names.get_children():
		if layer_n.layer_name == layer_name:
			layer_n.visible = visibility
