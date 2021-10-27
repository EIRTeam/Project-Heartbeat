extends Control

var size = 5.0 setget set_siz
export var allow_dragging = false
var start = 0.0 setget set_start
var offset = 0.0 setget set_offset
var max_t = 0.0
export var text = "Original" setget set_text
func set_text(val):
	text = val
	$PHAudioStreamEditor/Panel/Label.text = val

onready var stream_editor = get_node("PHAudioStreamEditor")

var _drag_start_x = 0.0
var _drag_start_time = 0.0
var _drag_start_size = 0.0
var dragging = false
var queued_update = false

func set_start(val):
	start = val
	queue_update_stream_editor()

func set_siz(val):
	size = val
	queue_update_stream_editor()
	
func set_offset(val):
	offset = val
	queue_update_stream_editor()

func queue_update_stream_editor():
	if not queued_update:
		queued_update = true
		call_deferred("update_stream_editor")
func update_stream_editor():
	stream_editor.start_point = start + offset
	stream_editor.end_point = start + size + offset
	queued_update = false
	
func _gui_input(event):
	if allow_dragging:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				if event.is_pressed():
					_drag_start_x = stream_editor.get_local_mouse_position().x
					_drag_start_size = size
					_drag_start_time = start
					dragging = true
				else:
					dragging = false
		if event is InputEventMouseMotion:
			if dragging:
				var time_delta = _drag_start_x - stream_editor.get_local_mouse_position().x
				time_delta /= stream_editor.rect_size.x
				time_delta *= _drag_start_size
				set_start(_drag_start_time + time_delta)
