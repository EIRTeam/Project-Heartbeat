extends EditorTimelineItemSingleNote

class_name EditorTimelineItemSustainNote

var _end_time_drag_start_position : Vector2
var _end_time_drag_start_time : float
var _end_time_drag_x_offset : float
var _end_time_drag_new_time : float
var _end_time_drag_moving = false
var _end_time_dragging = false
var _end_time_drag_last

@onready var hack = get_node("TextureRect2/Control")

func _init():
	_class_name = "EditorTimelineItemSustainNote" # Workaround for godot#4708
	_inheritance.append("EditorTimelineItemSingleNote")

func set_texture():
	super.set_texture()
	if data is HBSustainNote:
		$TextureRect2.texture = HBNoteData.get_note_graphic(data.note_type, "sustain_note")
	$TextureRect2.set_deferred("size", Vector2(get_size().y, get_size().y))
	_on_end_time_changed()

func _draw():
	if data is HBSustainNote:
		var width = 5
		
		var y = ($TextureRect.size.y - width)/2
		var start = Vector2(0.0, y)
		var size = Vector2(editor.scale_msec(data.get_duration()), width)
		var color = ResourcePackLoader.get_note_trail_color(data.note_type).darkened(0.15)
		
		draw_rect(Rect2(start, size), color)
		hack.set_enable_hack(false)
		if global_position.x <= 0.0:
			hack.set_enable_hack(true)
			hack.run_uwu_hack(size.x, color)
		
func _on_view_port_size_changed():
	if get_viewport():
		_on_end_time_changed()
		
func _on_end_time_changed():
	$TextureRect2.position.x = editor.scale_msec(data.get_duration())-get_size().y / 2
	queue_redraw()

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
			if data.end_time + drag_delta > data.time:
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
			_end_time_drag_x_offset = (global_position - get_viewport().get_mouse_position()).x
			_end_time_drag_last = data.end_time
			set_process(true)
	
	if event.is_action_released("editor_select") and _end_time_dragging:
		editor.select_item(self)
		_end_time_dragging = false
		if is_processing():
			set_process(false)
			if _drag_start_time != data.end_time:
				editor._commit_selected_property_change("end_time")
func sync_value(property_name: String):
	super.sync_value(property_name)
	if property_name == "end_time":
		_on_end_time_changed()
