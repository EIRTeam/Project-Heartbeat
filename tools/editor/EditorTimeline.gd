extends Control

var editor
const EDITOR_LAYER_SCENE = preload("res://tools/editor/EditorLayer.tscn")
onready var layers = get_node("VBoxContainer/ScrollContainer/HBoxContainer/Layers/LayerControl")
onready var layer_names = get_node("VBoxContainer/ScrollContainer/HBoxContainer/VBoxContainer/LayerNames")
signal offset_changed(offset)
const LAYER_NAME_SCENE = preload("res://tools/editor/EditorLayerName.tscn")
onready var playhead_area = get_node("VBoxContainer/HBoxContainer/PlayheadArea")
onready var scroll_bar = get_node("VBoxContainer/HScrollBar")
onready var scroll_container = get_node("VBoxContainer/ScrollContainer")
var _offset = 0
var _prev_playhead_position = Vector2()
signal layers_changed
const LOG_NAME = "Editor"
var _area_select_start = Vector2()
var _area_selecting = false
const TRIANGLE_HEIGHT = 15
func _ready():
	update()
	connect("resized", self, "_on_viewport_size_changed")
	scroll_container.connect("zoom_in", self, "_on_zoom_in")
	scroll_container.connect("zoom_out", self, "_on_zoom_out")
	
func _on_zoom_in():
	editor.change_scale(editor.scale-0.5)
func _on_zoom_out():
	editor.change_scale(editor.scale+0.5)
	
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
	var interval = (editor.get_note_resolution() / note_length) * beat_length
	
	_draw_interval(interval, editor.get_note_snap_offset(), seconds_per_bar)
	_draw_bars(seconds_per_bar, editor.get_note_snap_offset())
	#_draw_timing_line_interval(5, 0.75, 2.5)
	
func _draw():
	_draw_playhead()
	_draw_timing_lines()
	_draw_area_select()
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
	layers.rect_size.x = editor.scale_msec(editor.get_song_length() * 1000.0)

func _on_Editor_scale_changed(prev_scale, scale):
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
				var new_offset = max(_offset - editor.scale_pixels(event.relative.x), 0)
				set_layers_offset(new_offset)
				scroll_bar.value = new_offset / float(editor.get_song_length() * 1000.0)
		if _area_selecting:
			update()

func _gui_input(event):
	if event is InputEventMouseButton:
		if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
			if event.button_index == BUTTON_LEFT and event.pressed and not event.is_echo():
				get_tree().set_input_as_handled()
				_area_select_start = get_local_mouse_position()
				_area_selecting = true
		if event.button_index == BUTTON_LEFT and not event.pressed and not event.is_echo() and _area_selecting:
				get_tree().set_input_as_handled()
				_area_selecting = false
				_do_area_select()
				update()
				
				

func get_selection_rect():
	var origin = _area_select_start
	var end_point = get_local_mouse_position()
	if get_local_mouse_position().y > _area_select_start.y and get_local_mouse_position().x < _area_select_start.x:
		# Bottom left
		origin = Vector2(get_local_mouse_position().x, _area_select_start.y)
		end_point = Vector2(_area_select_start.x, get_local_mouse_position().y)
	if get_local_mouse_position().y < _area_select_start.y and get_local_mouse_position().x < _area_select_start.x:
		# Top left
		origin = get_local_mouse_position()
		end_point = _area_select_start
	if get_local_mouse_position().y < _area_select_start.y and get_local_mouse_position().x > _area_select_start.x:
		# Top right
		origin = Vector2(_area_select_start.x, get_local_mouse_position().y)
		end_point = Vector2(get_local_mouse_position().x, _area_select_start.y)
	var size = end_point - origin
	size.y = clamp(size.y, scroll_container.rect_position.y - _area_select_start.y, rect_size.y - origin.y)
	return Rect2(get_global_transform().xform(origin), size)

func _do_area_select():
	var rect = get_selection_rect()

	var timeline_rect = Rect2(rect_global_position, rect_size)
	var first = true
	for layer in get_layers():
		for item in layer.get_editor_items():
			if timeline_rect.has_point(item.rect_global_position):
				var item_rect = Rect2(item.rect_global_position, item.rect_size)
				if rect.intersects(item_rect):
					editor.select_item(item, !first)
					first = false
func _draw_area_select():
	if _area_selecting:
		var origin = _area_select_start
		var size = get_local_mouse_position() - _area_select_start
		size.y = clamp(size.y, scroll_container.rect_position.y - _area_select_start.y, rect_size.y - origin.y)
		var rect = Rect2(_area_select_start, size)
		var color = Color.turquoise
		color.a = 0.25
		draw_rect(rect, color, true, 1.0, false)
		color.a = 0.5
		draw_rect(rect, color, false, 1.0, false)

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


func _on_HScrollBar_scrolling():
	var new_position = (scroll_bar.value * editor.get_song_length()) * 1000.0
	set_layers_offset(int(new_position))
