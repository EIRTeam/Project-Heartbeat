extends Control

var editor

var layer_name : String = "New Layer"

onready var preview = get_node("EditorTimelinePreview")

func _ready():
	preview.hide()
	
	
func place_child(child: EditorTimelineItem):
	var x_pos = max(editor.scale_msec(child.data.time), 0.0)
	child.rect_position = Vector2(x_pos, 0)
	child.rect_size = child.get_editor_size()
	child.sync_value("end_time")
	
func place_all_children():
	for child in get_children():
		if child != preview:
			if child.data.time < editor.timeline.get_max_time() and child.data.time > editor.timeline.get_min_time():
				child.show()
				place_child(child)
			else:
				child.hide()
	
func place_preview(start: float, duration: float):
	var x_pos = max(editor.scale_msec(start), 0)
	preview.rect_position = Vector2(x_pos, 0)
	preview.rect_size = Vector2(editor.scale_msec(duration), preview.rect_size.y)
	
	
func add_item(item: EditorTimelineItem):
	item._layer = self
	item.editor = editor
	place_child(item)
	if not item.is_connected("time_changed", self, "_on_time_changed"):
		item.connect("time_changed", self, "_on_time_changed", [item])
		
	if get_child_count() > 1:
		var closest_child = get_child(1)
			
		for child in get_children():
			if child != preview:
				if child.data.time < item.data.time:
					closest_child = child
				else:
					break
		add_child_below_node(closest_child, item)
			
	else:
		add_child(item)
		

func _on_time_changed(child):
	place_child(child)

func remove_item(item: EditorTimelineItem):
	remove_child(item)

func can_drop_data(position, data):
	if data is EditorTimelineItem:
		if not data in get_children():
			preview.show()
			place_preview(editor.scale_pixels(position.x + data._drag_x_offset), editor.scale_pixels(data.get_size().x))
			return true
	else:
		return false

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
			if event.doubleclick and event.button_index == BUTTON_LEFT:
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

#func drop_data(position, data: EditorTimelineItem):
#	data._layer.remove_child(data)
##	data.disconnect("item_changed", data._layer, "place_child")
#
#	for i in get_timing_points():
#		if i.time == data.data.time:
#			return
#
#	if not position == null:
#		data.data.time = int(editor.scale_pixels(position.x + data._drag_x_offset))
#
#	var ln = layer_name
#	if ln.ends_with("2"):
#	# For second layers of the same type, this ensures we don't
#	# just do any layer with 2 at the end
#		var new_val = ln.substr(0, ln.length()-1)
#		if new_val in HBNoteData.NOTE_TYPE.keys():
#			ln = new_val
#
#	if ln in HBNoteData.NOTE_TYPE.keys():
#		if data.data is HBBaseNote:
#			data.data.note_type = HBNoteData.NOTE_TYPE[ln]
#
#	add_item(data)

func _on_EditorLayer_mouse_exited():
	preview.hide()

func show_children():
	for child in get_children():
		if child != preview:
			if child.data.time < editor.timeline.get_min_time():
				child.hide()
				continue
			elif child.data.time > editor.timeline.get_min_time() and child.data.time < editor.timeline.get_max_time():
				child.show()
				place_child(child)
			else:
				child.hide()
				break
