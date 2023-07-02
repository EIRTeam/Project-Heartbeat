extends Control

signal position_offset_changed(offset)
signal time_cull_changed(start_time, end_time)

const LOG_NAME = "Editor"
const EDITOR_LAYER_SCENE = preload("res://tools/editor/EditorLayer.tscn")
const LAYER_NAME_SCENE = preload("res://tools/editor/EditorLayerName.tscn")
const TRIANGLE_HEIGHT = 15
const TIME_LABEL = preload("res://fonts/new_fonts/roboto_black_15.tres")

const SELECT_MODE = {
	"NORMAL": 0,
	"ADDITION": 1,
	"SUBSTRACTION": 2,
	"TOGGLE": 3,
}

@onready var layers = get_node("VBoxContainer/ScrollContainer/HBoxContainer/Layers/LayerControl")
@onready var layer_names = get_node("VBoxContainer/ScrollContainer/HBoxContainer/VBoxContainer/LayerNames")
@onready var playhead_area = get_node("VBoxContainer/Panel/HBoxContainer/PlayheadArea")
@onready var scroll_container = get_node("VBoxContainer/ScrollContainer")
@onready var minimap = get_node("VBoxContainer/Minimap")
@onready var playhead_container = get_node("VBoxContainer/Panel")
@onready var stream_editor = get_node("PHAudioStreamEditor")
@onready var modifier_texture = get_node("TextureRect")

@onready var copy_button: Button = get_node("%CopyButton")
@onready var cut_button: Button = get_node("%CutButton")
@onready var paste_button: Button = get_node("%PasteButton")
@onready var delete_button: Button = get_node("%DeleteButton")

var editor: HBEditor: set = set_editor
var _offset = 0
var _prev_playhead_position = Vector2()
signal layers_changed
var _area_select_start = Vector2()
var _area_selecting = false
var _cull_start_time = 0
var _cull_end_time = 0
var selection_mode = SELECT_MODE.NORMAL

var modifier_textures = {
	SELECT_MODE.NORMAL: CompressedTexture2D.new(),
	SELECT_MODE.ADDITION: load("res://graphics/plus-circle-outline.svg"),
	SELECT_MODE.SUBSTRACTION: load("res://graphics/minus-circle-outline.svg"),
	SELECT_MODE.TOGGLE: load("res://graphics/invert-circle-outline.svg"),
}

func set_editor(ed):
	editor = ed
	minimap.editor = ed
	
	# Load an empty chart
	var chart = HBChart.new()
	for layer in chart.layers:
		var layer_scene = EDITOR_LAYER_SCENE.instantiate()
		layer_scene.layer_name = layer.name
		add_layer(layer_scene)
	
	update_selected()


func _ready():
	connect("resized", Callable(self, "_on_viewport_size_changed"))
	connect("time_cull_changed", Callable(minimap, "_on_time_cull_changed"))
	
	scroll_container.connect("zoom_in", Callable(self, "_on_zoom_in"))
	scroll_container.connect("zoom_out", Callable(self, "_on_zoom_out"))
	scroll_container.connect("on_offset_left", Callable(self, "_on_offset_left"))
	scroll_container.connect("on_offset_right", Callable(self, "_on_offset_right"))
	
	minimap.connect("position_offset_changed", Callable(self, "set_layers_offset"))
	minimap.connect("resized", Callable(self, "queue_redraw"))

func _on_offset_left():
	set_layers_offset(_offset - 200)

func _on_offset_right():
	set_layers_offset(_offset + 200)
	
func _on_zoom_in():
	editor.change_scale(editor.editor_scale-0.5)
func _on_zoom_out():
	editor.change_scale(editor.editor_scale+0.5)
	
func send_time_cull_changed_signal():
	_cull_start_time = _offset
	_cull_end_time = _offset + editor.scale_pixels(size.x - layer_names.size.x)
	
	var variant_offset = 0
	if editor.current_song:
		variant_offset = editor.current_song.get_variant_offset(editor.song_editor_settings.selected_variant) / 1000.0
	
	stream_editor.start_point = _cull_start_time / 1000.0 - variant_offset
	stream_editor.end_point = _cull_end_time / 1000.0 - variant_offset
	stream_editor.size.x = size.x - layer_names.size.x - 13 # Account for scrollbar
	stream_editor.size.y = scroll_container.size.y
	stream_editor.global_position.y = scroll_container.global_position.y
	stream_editor.global_position.x = layer_names.size.x
	
	get_tree().call_group("editor_timeline_items", "hide")
	get_tree().call_group("editor_timeline_items", "set_process_input", false)
	get_tree().call_group("editor_timeline_items", "set_rect_position", Vector2(-1000.0, 0.0))
	emit_signal("time_cull_changed", _cull_start_time, _cull_end_time)
	
func _on_viewport_size_changed():
	# HACK: On linux we wait one frame because the size transformation doesn't
	# get applied on time, user should not notice this
	await get_tree().process_frame
	queue_redraw()
	set_layers_offset(_offset)

# Draw timeline yellow bars and time positions
# We iterate over these backwards to clip numbers correctly
func _draw_bars(map: Array, start_idx: int, end_idx: int):
	var draw_every = 1.0
	if editor.editor_scale > 5.0:
		draw_every = 2.0
	
	var last_x_pos = null
	for i in range(end_idx - 1, start_idx - 1, -1):
		var pos_msec = map[i]
		
		var starting_rect_pos = Vector2(playhead_area.position.x + layers.position.x, get_playhead_area_y_pos() + playhead_area.size.y - TIME_LABEL.get_height())
		starting_rect_pos += Vector2(editor.scale_msec(pos_msec), 0)
		var clip_w = last_x_pos - starting_rect_pos.x if last_x_pos else -1
		
		draw_line(starting_rect_pos, starting_rect_pos + Vector2(0, size.y), get_theme_color("timeline_separator_bar", "PHEditor"), 1.0)
		
		if fmod(i, draw_every) == 0:
			var time_string = HBUtils.format_time(pos_msec, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS | HBUtils.TimeFormat.FORMAT_MILISECONDS)
			draw_string(TIME_LABEL, starting_rect_pos + Vector2(5, TIME_LABEL.get_height() - 5), time_string, HORIZONTAL_ALIGNMENT_LEFT, clip_w, 16, Color.WHITE)
		
			# Leave at least 3px of breathing space
			last_x_pos = starting_rect_pos.x - 3

# Draw timeline grey and white bars
func _draw_beats(map: Array, bar_map: Array, start_idx: int, end_idx: int):
	for i in range(start_idx, end_idx):
		var pos_msec = map[i]
		
		var starting_rect_pos = Vector2(playhead_area.position.x + layers.position.x, get_playhead_area_y_pos() + playhead_area.size.y)
		starting_rect_pos += Vector2(editor.scale_msec(pos_msec), 0)
		
		if bar_map.has(pos_msec):
			continue
		
		var color_name = "timeline_separator_odd" if i % 2 else "timeline_separator_even"
		draw_line(starting_rect_pos, starting_rect_pos + Vector2(0, size.y), get_theme_color(color_name, "PHEditor"), 1.0)

func _draw_timing_lines():
	var timing_map = editor.get_timing_map()
	var timing_changes = editor.get_timing_changes()
	var signature_map = editor.get_signature_map()
	
	if not timing_map:
		return
	
	var first_timing_change_idx = timing_map.find(timing_changes[-1].data.time)
	timing_map = timing_map.slice(first_timing_change_idx, timing_map.size() - 1)
	
	var start_t = _offset
	var end_t = start_t + editor.scale_pixels(playhead_area.position.x + playhead_area.size.x)
	
	var start_beat_idx = timing_map.bsearch(start_t)
	var end_beat_idx = timing_map.bsearch(end_t)
	var start_bar_idx = signature_map.bsearch(start_t)
	var end_bar_idx = signature_map.bsearch(end_t)
	
	_draw_beats(timing_map, signature_map, start_beat_idx, end_beat_idx)
	_draw_bars(signature_map, start_bar_idx, end_bar_idx)

func _draw():
	_draw_area_select()
	
	draw_set_transform(Vector2(0, playhead_area.position.y + playhead_area.size.y), 0, Vector2.ONE)
	
	_draw_timing_lines()
	_draw_playhead()
	_draw_sections()
	_draw_timing_changes()

func get_playhead_area_y_pos():
	return playhead_container.position.y - playhead_area.size.y

func calculate_playhead_position():
	var x_pos = playhead_area.position.x + layers.position.x + editor.scale_msec(editor.playhead_position)
	
	return Vector2(x_pos, get_playhead_area_y_pos())

func _draw_playhead():
	if editor.playhead_position > _offset-1:
		var playhead_pos = calculate_playhead_position()
		_prev_playhead_position = playhead_pos
		
		var y_offset = Vector2(0, playhead_area.size.y)
		
		draw_line(playhead_pos + y_offset, playhead_pos+Vector2(0.0, size.y), Color(1.0, 0.0, 0.0), 1.0)
		
		# Draw playhead triangle
		var point1 = playhead_pos + y_offset
		var point2 = playhead_pos + y_offset + Vector2(TRIANGLE_HEIGHT/2.0, -TRIANGLE_HEIGHT)
		var point3 = playhead_pos + y_offset + Vector2(-TRIANGLE_HEIGHT/2.0, -TRIANGLE_HEIGHT)
		
		draw_colored_polygon(PackedVector2Array([point1, point2, point3]), Color.RED)

func _draw_sections():
	if not editor.current_song:
		return
	for layer in get_layers():
		if layer.layer_name == "Sections" and not layer.visible:
			return
	
	for section in editor.get_sections():
		var x_pos = playhead_area.position.x + layers.position.x + editor.scale_msec(section.time)
		if x_pos < playhead_area.position.x or x_pos > playhead_area.position.x + playhead_area.size.x:
			continue
		
		var top = playhead_container.position.y
		var bottom = playhead_container.position.y + scroll_container.size.y
		
		draw_line(Vector2(x_pos, top), Vector2(x_pos, bottom), section.color, 1.0)
		
		# Draw upper triangle
		var point1 = Vector2(x_pos, top + TRIANGLE_HEIGHT)
		var point2 = Vector2(x_pos + TRIANGLE_HEIGHT/2.0, top)
		var point3 = Vector2(x_pos - TRIANGLE_HEIGHT/2.0, top)
		
		draw_colored_polygon(PackedVector2Array([point1, point2, point3]), section.color)
		
		# Draw lower triangle
		point1 = Vector2(x_pos, bottom - TRIANGLE_HEIGHT)
		point2 = Vector2(x_pos + TRIANGLE_HEIGHT/2.0, bottom)
		point3 = Vector2(x_pos - TRIANGLE_HEIGHT/2.0, bottom)
		
		draw_colored_polygon(PackedVector2Array([point1, point2, point3]), section.color)

var timing_changes_x_map = {}
func _draw_timing_changes():
	timing_changes_x_map.clear()
	
	var last_x_pos = null
	for item in editor.get_timing_changes():
		var timing_change = item.data as HBTimingChange
		
		var tempo_info = "{0} BPM; %d/%d".format([timing_change.bpm]) % [timing_change.time_signature.numerator, timing_change.time_signature.denominator]
		
		# Always show something at least one on the timeline
		if timing_change.time < _offset:
			var x_pos = playhead_area.position.x
			var clip_w = last_x_pos - x_pos if last_x_pos else -1
			draw_string(TIME_LABEL, Vector2(x_pos, get_playhead_area_y_pos() + TIME_LABEL.get_height()), tempo_info, HORIZONTAL_ALIGNMENT_LEFT, clip_w, 16, Color.WHITE)
			
			last_x_pos = x_pos
			timing_changes_x_map[x_pos] = item
			break
		
		var x_pos = playhead_area.position.x + layers.position.x + editor.scale_msec(timing_change.time)
		if x_pos < playhead_area.position.x or x_pos > playhead_area.position.x + playhead_area.size.x:
			continue
		var clip_w = last_x_pos - x_pos if last_x_pos else -1
		
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, playhead_container.position.x), Color.PURPLE)
		draw_string(TIME_LABEL, Vector2(x_pos, get_playhead_area_y_pos() + TIME_LABEL.get_height()), tempo_info, HORIZONTAL_ALIGNMENT_LEFT, clip_w, 16, Color.WHITE)
		
		# Leave at least 3px of breathing space
		last_x_pos = x_pos - 3
		timing_changes_x_map[x_pos] = item

func add_layer(layer):
	layer.editor = editor
	layers.add_child(layer)
	var lns = LAYER_NAME_SCENE.instantiate()
	lns.layer_name = layer.layer_name
	layer_names.add_child(lns)
	scale_layers()
	connect("time_cull_changed", Callable(layer, "_on_time_cull_changed"))
	emit_signal("layers_changed")
	layer._on_time_cull_changed(_cull_start_time, _cull_end_time)


func get_layers():
	return layers.get_children()

func get_visible_layers():
	var visible_layers = []
	for layer in layers.get_children():
		if layer.visible:
			visible_layers.append(layer)
	return visible_layers

func update_layer_styles():
	var visible_layers = get_visible_layers()
	for i in range(visible_layers.size()):
		visible_layers[i].set_style(i % 2 == 0)

func _on_PlayheadArea_mouse_x_input(value):
	editor.seek(clamp(editor.scale_pixels(int(value)) + _offset, _offset, editor.get_song_length()*1000.0))

func _on_PlayheadArea_double_click():
	var current_item = null
	var x_pos = get_local_mouse_position().x
	for item_x_pos in timing_changes_x_map:
		if item_x_pos <= x_pos:
			current_item = timing_changes_x_map[item_x_pos]
			break
	
	if current_item:
		editor.select_item(current_item)

func _on_playhead_position_changed():
	queue_redraw()

var _prev_layers_rect_position
func set_layers_offset(ms: int):
	var song_length_ms: int = int(editor.get_song_length() * 1000.0)
	_offset = clamp(ms, 0, song_length_ms - editor.scale_pixels(playhead_area.size.x))
	layers.position.x = -editor.scale_msec(_offset)
	_prev_layers_rect_position = layers.position
	
	emit_signal("position_offset_changed")
	send_time_cull_changed_signal()
	
	queue_redraw()

func scale_layers():
	layers.size.x = editor.scale_msec(editor.get_song_length() * 1000.0)

func _on_editor_scale_changed(prev_scale, scale):
	var new_offset = _offset * (scale/prev_scale)
	var diff = _prev_playhead_position.x - calculate_playhead_position().x
	
	scale_layers()
	
	set_layers_offset(max(new_offset - editor.scale_pixels(diff), 0))
	
	queue_redraw()
	
func _input(event):
	if event is InputEventMouseMotion:
		if get_global_rect().has_point(get_global_mouse_position()):
			if Input.is_action_pressed("editor_pan"):
				var new_offset = max(_offset - editor.scale_pixels(event.relative.x), 0)
				set_layers_offset(new_offset)
		
		if _area_selecting:
			queue_redraw()
	
	if event.is_action_released("editor_select"):
		for note in editor.selected:
			note.stop_dragging()
	
	var new_selection_mode = SELECT_MODE.NORMAL
	if Input.is_key_pressed(KEY_SHIFT):
		new_selection_mode = SELECT_MODE.ADDITION
	elif Input.is_key_pressed(KEY_ALT):
		new_selection_mode = SELECT_MODE.SUBSTRACTION
	
	if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_ALT):
		new_selection_mode = SELECT_MODE.TOGGLE
	
	if selection_mode != new_selection_mode:
		selection_mode = new_selection_mode
		update_selection_mode()
	
	if get_global_rect().has_point(get_global_mouse_position()):
		if event.is_action_pressed("editor_contextual_menu") and not editor.get_node("%EditorGlobalSettings").visible:
			editor.show_contextual_menu()

func _gui_input(event):
	if event is InputEventMouseButton:
		if scroll_container.get_global_rect().has_point(get_global_mouse_position()):
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.is_echo():
				get_viewport().set_input_as_handled()
				_area_select_start = get_local_mouse_position()
				_area_selecting = true
				modifier_texture.visible = true
				queue_redraw()
		
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not event.is_echo() and _area_selecting:
			get_viewport().set_input_as_handled()
			_area_selecting = false
			_do_area_select()
			modifier_texture.visible = false
			queue_redraw()

func _unhandled_input(event):
	if _area_selecting and event is InputEventWithModifiers:
		var area_select_size = abs(_area_select_start.x - get_local_mouse_position().x)
		if area_select_size < 10:
			return
		
		if event.is_action_pressed("slide_left", false, true) and layer_visible("SLIDE_LEFT"):
			make_slide(HBBaseNote.NOTE_TYPE.SLIDE_LEFT, HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT, "SLIDE_LEFT")
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("slide_right", false, true) and layer_visible("SLIDE_RIGHT"):
			make_slide(HBBaseNote.NOTE_TYPE.SLIDE_RIGHT, HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT, "SLIDE_RIGHT")
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("slide_left", false, false) and event.shift_pressed and layer_visible("SLIDE_LEFT2"):
			make_slide(HBBaseNote.NOTE_TYPE.SLIDE_LEFT, HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT, "SLIDE_LEFT2")
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("slide_right", false, false) and event.shift_pressed and layer_visible("SLIDE_RIGHT2"):
			make_slide(HBBaseNote.NOTE_TYPE.SLIDE_RIGHT, HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT, "SLIDE_RIGHT2")
			get_viewport().set_input_as_handled()
		else:
			for note_type in [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT, HBBaseNote.NOTE_TYPE.HEART]:
				var action = HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_type][0]
				var layer_name = HBBaseNote.NOTE_TYPE.keys()[note_type]
				
				if event.is_action_pressed(action, false, true) and layer_visible(layer_name):
					make_spam(note_type, layer_name)
					get_viewport().set_input_as_handled()
					break

func make_slide(note_type: int, piece_note_type: int, layer_name: String):
	var layer := find_layer_by_name(layer_name)
	var second_layer := "2" in layer_name
	var map := editor.get_timing_map()
	
	var first_pos = _area_select_start
	var second_pos = get_local_mouse_position()
	
	var first_time = clamp(editor.scale_pixels(int(first_pos.x - playhead_area.position.x)) + _offset, _offset, editor.get_song_length() * 1000.0)
	var second_time = clamp(editor.scale_pixels(int(second_pos.x - playhead_area.position.x)) + _offset, _offset, editor.get_song_length() * 1000.0)
	first_time = editor.snap_time_to_timeline(first_time)
	second_time = editor.snap_time_to_timeline(second_time)
	
	var start_time = min(first_time, second_time)
	var end_time = max(first_time, second_time)
	var start_i := HBUtils.bsearch_closest(map, start_time)
	var end_i := HBUtils.bsearch_closest(map, end_time)
	
	var piece_count := (end_i - start_i) * 2
	
	var start_time_as_eight = editor.get_time_as_eight(start_time)
	start_time_as_eight = fmod(start_time_as_eight, 15.0)
	if start_time_as_eight < 0:
		start_time_as_eight = fmod(15.0 - abs(start_time_as_eight), 15.0)
	
	var first_slide := HBNoteData.new()
	first_slide.time = start_time
	first_slide.note_type = note_type
	first_slide.oscillation_frequency = -2 if note_type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT else 2
	first_slide.entry_angle = -90
	
	first_slide.position.y = 918
	first_slide.position.x = 242 + 96 * start_time_as_eight
	if note_type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT:
		first_slide.position.x += 32 * piece_count
	
	first_slide.set_meta("second_layer", second_layer)
	
	var first_timeline_item = first_slide.get_timeline_item()
	
	editor.undo_redo.create_action("Create slide chain")
	
	editor.undo_redo.add_do_method(editor.deselect_all)
	editor.undo_redo.add_undo_method(editor.deselect_all)
	
	editor.undo_redo.add_do_method(editor.add_item_to_layer.bind(layer, first_timeline_item))
	editor.undo_redo.add_do_method(editor.select_item.bind(first_timeline_item))
	editor.undo_redo.add_undo_method(editor.remove_item_from_layer.bind(layer, first_timeline_item))
	
	for i in range(piece_count):
		var time_i = min(start_i + (i + 1.0) / 2.0, map.size() - 1)
		var time
		if is_equal_approx(fmod(time_i, 1.0), 0.0):
			time = map[int(time_i)]
		else:
			time = map[int(time_i - 0.5)]
			time += (map[int(time_i + 0.5)] - map[int(time_i - 0.5)]) / 2.0
		
		var slide_piece := HBNoteData.new()
		
		slide_piece.time = time
		slide_piece.note_type = piece_note_type
		slide_piece.oscillation_frequency = -2 if piece_note_type == HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT else 2
		slide_piece.entry_angle = -90
		slide_piece.position = first_slide.position
		
		if piece_note_type == HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT:
			slide_piece.position.x += 48 + 32 * i
		else:
			slide_piece.position.x -= 48 + 32 * i
		
		slide_piece.set_meta("second_layer", second_layer)
		
		var timeline_item = slide_piece.get_timeline_item()
		
		editor.undo_redo.add_do_method(editor.add_item_to_layer.bind(layer, timeline_item))
		editor.undo_redo.add_do_method(editor.select_item.bind(timeline_item, true))
		editor.undo_redo.add_undo_method(editor.remove_item_from_layer.bind(layer, timeline_item))
	
	editor.undo_redo.add_do_method(editor._on_timing_points_changed)
	editor.undo_redo.add_undo_method(editor._on_timing_points_changed)
	
	_area_selecting = false
	modifier_texture.visible = false
	editor.deselect_all()
	queue_redraw()
	editor.undo_redo.commit_action()
	
	editor._on_PauseButton_pressed()

func make_spam(note_type: int, layer_name: String):
	var layer := find_layer_by_name(layer_name)
	var map := editor.get_timing_map()
	
	var first_pos = _area_select_start
	var second_pos = get_local_mouse_position()
	
	var first_time = clamp(editor.scale_pixels(int(first_pos.x - playhead_area.position.x)) + _offset, _offset, editor.get_song_length() * 1000.0)
	var second_time = clamp(editor.scale_pixels(int(second_pos.x - playhead_area.position.x)) + _offset, _offset, editor.get_song_length() * 1000.0)
	first_time = editor.snap_time_to_timeline(first_time)
	second_time = editor.snap_time_to_timeline(second_time)
	
	var start_time = min(first_time, second_time)
	var end_time = max(first_time, second_time)
	var start_i := HBUtils.bsearch_closest(map, start_time)
	var end_i := HBUtils.bsearch_closest(map, end_time)
	
	var type_name = HBGame.NOTE_TYPE_TO_STRING_MAP[note_type]
	editor.undo_redo.create_action("Create " + type_name + " spam")
	
	editor.undo_redo.add_do_method(editor.deselect_all)
	editor.undo_redo.add_undo_method(editor.deselect_all)
	
	var multi_check_times := []
	for i in range(start_i, min(end_i + 1, map.size() - 1)):
		var note = HBNoteData.new()
		note.time = map[i]
		note.note_type = note_type
		
		if UserSettings.user_settings.editor_auto_place:
			note = editor.autoplace(note)
		
		var timeline_item = note.get_timeline_item()
		
		editor.undo_redo.add_do_method(editor.add_item_to_layer.bind(layer, timeline_item, false))
		editor.undo_redo.add_do_method(editor.select_item.bind(timeline_item, (i != 0)))
		editor.undo_redo.add_undo_method(editor.remove_item_from_layer.bind(layer, timeline_item))
		
		multi_check_times.append(note.time)
	
	editor.undo_redo.add_do_method(editor.sort_groups)
	
	editor.undo_redo.add_do_method(editor._on_timing_points_changed)
	editor.undo_redo.add_undo_method(editor._on_timing_points_changed)
	
	_area_selecting = false
	modifier_texture.visible = false
	queue_redraw()
	editor.undo_redo.commit_action()
	
	editor.check_for_multi_changes(multi_check_times)
	
	editor._on_PauseButton_pressed()

func get_time_being_hovered() -> int:
	return editor.snap_time_to_timeline(editor.scale_pixels(get_layers()[0].get_local_mouse_position().x))

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
	size.y = clamp(size.y, scroll_container.position.y - _area_select_start.y, size.y - origin.y)
	return Rect2(get_global_transform() * (origin), size)

func is_playhead_visible():
	var x = calculate_playhead_position().x
	return x >= playhead_area.position.x and x <= playhead_area.position.x + playhead_area.size.x
func ensure_playhead_is_visible():
	if not is_playhead_visible():
		set_layers_offset(max(editor.playhead_position - 300, 0))

func _do_area_select():
	if selection_mode == SELECT_MODE.NORMAL:
		editor.deselect_all()
	
	var rect = get_selection_rect()

	var timeline_rect = Rect2(global_position, size)
	var first = true
	for layer in get_layers():
		if not layer.visible:
			continue
		
		for item in layer.get_editor_items():
			if timeline_rect.has_point(item.global_position):
				if item.visible:
					var item_rect = Rect2(item.global_position, item.size)
					if rect.intersects(item_rect):
						if selection_mode == SELECT_MODE.NORMAL:
							editor.select_item(item, !first)
						elif selection_mode == SELECT_MODE.ADDITION:
							editor.select_item(item, true)
						elif selection_mode == SELECT_MODE.SUBSTRACTION:
							editor.deselect_item(item)
						elif selection_mode == SELECT_MODE.TOGGLE:
							editor.toggle_selection(item)
						
						first = false

func _draw_area_select():
	if _area_selecting:
		var mouse_position = get_global_mouse_position()
		var playhead_rect = playhead_area.get_global_rect()
		var bounds = Rect2(
			playhead_rect.position.x,
			playhead_rect.position.y + playhead_rect.size.y,
			playhead_rect.size.x - 13, # Account for scrollbar
			scroll_container.get_global_rect().size.y
		)
		mouse_position.x = clamp(mouse_position.x, bounds.position.x, bounds.position.x + bounds.size.x)
		mouse_position.y = clamp(mouse_position.y, bounds.position.y, bounds.position.y + bounds.size.y)
		mouse_position = get_global_transform().affine_inverse() * (mouse_position) # Make local
		
		var size = mouse_position - _area_select_start
		var rect = Rect2(_area_select_start, size)
		
		var color = Color.TURQUOISE
		color.a = 0.25
		draw_rect(rect, color, true, 1.0)# false) TODOGODOT4 Antialiasing argument is missing
		color.a = 0.5
		draw_rect(rect, color, false, 1.0)# false) TODOGODOT4 Antialiasing argument is missing
		
		modifier_texture.position = _area_select_start - Vector2(10, 10)

func update_selection_mode():
	modifier_texture.texture = modifier_textures[selection_mode]

func clear_layers():
	for layer in layers.get_children():
		layer.free()
	for layer_name in layer_names.get_children():
		layer_name.free()


func _on_timing_information_changed():
	queue_redraw()

func change_layer_visibility(visibility: bool, layer_name: String):
	for layer in layers.get_children():
		if layer.layer_name == layer_name:
			layer.visible = visibility
	for layer_n in layer_names.get_children():
		if layer_n.layer_name == layer_name:
			layer_n.visible = visibility
	update_layer_styles()
	minimap.queue_redraw()
	
func set_waveform(state):
	if state:
		stream_editor.show()
	else:
		stream_editor.hide()

func set_audio_stream(stream: AudioStream):
	stream_editor.edit(stream)

func find_layer_by_name(name: String) -> EditorLayer:
	var r = null
	for layer in layers.get_children():
		if layer.layer_name == name:
			r = layer
			break
	
	return r

func _on_HBoxContainer_item_rect_changed():
	queue_redraw()

func layer_visible(layer_name: String) -> bool:
	var layer := find_layer_by_name(layer_name)
	
	return layer.visible

func update_selected():
	copy_button.disabled = editor.selected.size() == 0
	cut_button.disabled = editor.selected.size() == 0
	paste_button.disabled = editor.copied_points.size() == 0
	delete_button.disabled = editor.selected.size() == 0

func _copy():
	editor.copy_selected()

func _cut():
	editor.copy_selected()
	editor.delete_selected()

func _paste():
	var time = editor.playhead_position
	
	if paste_button.by_shortcut:
		time = clamp(editor.scale_pixels(int(get_local_mouse_position().x - playhead_area.position.x)) + _offset, _offset, editor.get_song_length() * 1000.0)
	
	editor.paste(editor.snap_time_to_timeline(time))

func _delete():
	editor.delete_selected()
