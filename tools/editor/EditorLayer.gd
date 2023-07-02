extends Control

class_name EditorLayer

var editor

var layer_name : String = "New Layer"

@onready var preview = get_node("EditorTimelinePreview")

var timing_points = []
var _cull_start_time = 0
var _cull_end_time = 0
var _cull_start_note_i = 0
var _cull_end_note_i = 0
func _ready():
	preview.hide()


func set_style(use_lighter: bool):
	var stylebox = get_theme_stylebox("panel")
	if use_lighter:
		stylebox.bg_color = Color("#2D3444")
	else:
		stylebox.bg_color = Color("#252b38")
func _sort_timing_points(a: EditorTimelineItem, b: EditorTimelineItem):
	return (a.data.time) < (b.data.time)

func place_child(child: EditorTimelineItem):
	var x_pos = max(editor.scale_msec(child.data.time), 0.0)
	child.position = Vector2(x_pos, 0)
	child.size = child.get_editor_size()
	child.sync_value("end_time")

func place_preview(start: float, duration: float):
	var x_pos = max(editor.scale_msec(start), 0)
	preview.position = Vector2(x_pos, 0)
	preview.set_deferred("size", Vector2(editor.scale_msec(duration), preview.size.y))
	
	
func add_item(item: EditorTimelineItem):
	var insert_pos = timing_points.bsearch_custom(item.data.time, self.bsearch_time)
	item._layer = self
	item.editor = editor
	place_child(item)
	
	if not item.is_connected("time_changed", Callable(self, "_on_time_changed")):
		item.connect("time_changed", Callable(self, "_on_time_changed").bind(item))
	
	add_child(item)
	
	timing_points.insert(insert_pos, item)
	if timing_points.size() > 1:
		if item.data.time > _cull_start_time and item.data.time < _cull_end_time:
			item.set_process_input(true)
			item.show()
		else:
			item.set_process_input(false)
			item.hide()

func _on_time_changed(child):
	timing_points.sort_custom(Callable(self, "_sort_timing_points"))
	place_child(child)

func remove_item(item: EditorTimelineItem):
	timing_points.erase(item)
	if item.get_parent() == self:
		remove_child(item)

func _can_drop_data(position, data):
	if data is EditorTimelineItem:
		if not data in get_children():
			preview.show()
			place_preview(editor.scale_pixels(position.x + data._drag_x_offset), editor.scale_pixels(data.get_size().x))
			return true
	else:
		return false

func bsearch_time(a, b):
	var a_t = a
	var b_t = b
	if a is EditorTimelineItem:
		a_t = a.data.time
	if b is EditorTimelineItem:
		b_t = b.data.time
	return a_t < b_t

func _on_time_cull_changed(start_time, end_time):
	var early_note_i = timing_points.bsearch_custom(start_time, self.bsearch_time)
	var late_note_i = timing_points.bsearch_custom(end_time, self.bsearch_time)
	
	_cull_start_time = start_time
	_cull_end_time = end_time
	
	_cull_start_note_i = early_note_i
	_cull_end_note_i = late_note_i
	
	var orig_cull_start_time = _cull_start_time
	
	# this is a hack to allow sustains to be visible all the time, as fast as possible
	for i in range(_cull_start_note_i-1, -1, -1):
		var point = timing_points[i]
		if point is EditorTimelineItemSustainNote:
			if point.data.end_time > orig_cull_start_time and point.data.time < orig_cull_start_time:
				_cull_start_note_i = i
				_cull_start_time = point.data.time
	
	# From the earlierst note forward
	for i in range(_cull_start_note_i, late_note_i):
		var item = timing_points[i]
		
		if item.data.time <= _cull_end_time:
			if item is EditorTimelineItemSustainNote:
				item.set_process_input(true)
			
			item.show()
			place_child(item)
		else:
			break
		
		_cull_end_note_i = i

func get_timing_points():
	var points = []
	for child in get_children():
		if not child == preview:
			points.append(child.data)
	return points

func get_editor_items():
	var points = []
	for child in get_children():
		if not child == preview:
			points.append(child)
	return points

func _gui_input(event):
	if event is InputEventMouseButton:
		var ln = layer_name
		if ln.ends_with("2"):
		# For second layers of the same type, this ensures we don't
		# just do any layer with 2 at the end
			var new_val = ln.substr(0, ln.length()-1)
			if new_val in HBNoteData.NOTE_TYPE.keys():
				ln = new_val
		
		if ln in HBNoteData.NOTE_TYPE.keys():
			if event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
				var new_note = HBNoteData.new()
				new_note.note_type = HBNoteData.NOTE_TYPE[ln]
				new_note.time = int(editor.snap_time_to_timeline(editor.scale_pixels(get_local_mouse_position().x)))
				
				var found_item_at_same_time = false # To prevent items being placed at the same time when creating a note with snap on
				for i in get_timing_points():
					if i.time == new_note.time:
						found_item_at_same_time = true
						break
				
				if not found_item_at_same_time:
					var item = new_note.get_timeline_item()
					item.data = new_note
					editor.user_create_timing_point(self, item)
				
				get_viewport().set_input_as_handled()

func _on_EditorLayer_mouse_exited():
	preview.hide()

