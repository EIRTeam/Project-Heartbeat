extends "EditorTimelineItemSingleNote.gd"

class_name EditorTimelineItemSustainNote

var _end_time_drag_start_position : Vector2
var _end_time_drag_start_time : float
var _end_time_drag_x_offset : float
var _end_time_drag_new_time : float
var _end_time_drag_moving = false
var _end_time_dragging = false
var _end_time_drag_last

func set_texture():
	.set_texture()
	if data is HBSustainNote:
		$TextureRect2.texture = HBNoteData.get_note_graphics(data.note_type).sustain_note
	$TextureRect2.rect_size = Vector2(get_size().y, get_size().y)
	_on_end_time_changed()

func _draw():
	if data is HBSustainNote:
		var y = $TextureRect.rect_size.y/2.0
		var target = Vector2(editor.scale_msec(data.get_duration()), y)
		draw_line(Vector2(0.0, y), target, IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, data.note_type)))
		
func _on_view_port_size_changed():
	if get_viewport():
		_on_end_time_changed()
		
func _on_end_time_changed():
	update()
	$TextureRect2.rect_position.x = editor.scale_msec(data.get_duration())-get_size().y / 2

func _process(delta):
	if _end_time_dragging:
		if abs(get_viewport().get_mouse_position().x - _end_time_drag_start_position.x) > SIDE_MOVEMENT_DEADZONE\
				or _end_time_drag_moving:
			_end_time_drag_moving = true
			var new_time = _end_time_drag_start_time + editor.scale_pixels(get_viewport().get_mouse_position().x - _end_time_drag_start_position.x)
			new_time = int(editor.snap_time_to_timeline(new_time))
			var drag_delta = new_time -_end_time_drag_last
			_end_time_drag_last = new_time
			editor.select_item(self)
			if abs(drag_delta) > 0:
				editor._change_selected_property_delta("end_time",  int(drag_delta), self)
			_on_end_time_changed()

func _input(event):
	if $TextureRect2.get_global_rect().has_point(get_global_mouse_position()):
		if event.is_action_pressed("editor_select"):
			editor.select_item(self)
			_end_time_dragging = true
			_end_time_drag_moving = false
			_end_time_drag_start_position = get_viewport().get_mouse_position()
			_end_time_drag_start_time = data.end_time
			_end_time_drag_x_offset = (rect_global_position - get_viewport().get_mouse_position()).x
			_end_time_drag_last = data.end_time
			print("Dragging")
			set_process(true)
	if event.is_action_released("editor_select") and _end_time_dragging:
		editor.select_item(self)
		_end_time_dragging = false
		if is_processing():
			set_process(false)
			if _drag_start_time != data.end_time:
				editor._commit_selected_property_change("end_time")
func sync_value(property_name: String):
	.sync_value(property_name)
	if property_name == "end_time":
		_on_end_time_changed()
