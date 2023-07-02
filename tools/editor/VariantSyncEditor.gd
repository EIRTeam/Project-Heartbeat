extends Control

var variant_size = 5.0: set = set_variant_size
@export var allow_dragging = false
var start = 0.0: set = set_start
var variant_offset = 0.0: set = set_variant_offset
var max_t = 0.0
@export var text = "Original": set = set_text
func set_text(val):
	text = val
	$PHAudioStreamEditor/Panel/Label.text = val

@onready var stream_editor = get_node("PHAudioStreamEditor")

var _drag_start_x = 0.0
var _drag_start_time = 0.0
var _drag_start_size = 0.0
var dragging = false
var queued_update = false
var shared_control
var red_line_x = -1.0

func set_start(val):
	start = val
	queue_update_stream_editor()

func set_variant_size(val):
	variant_size = val
	queue_update_stream_editor()
	
func set_variant_offset(val):
	variant_offset = val
	queue_update_stream_editor()

func share_red_line(ctrl: Control):
	shared_control = ctrl
	
func draw_red_line(x: float):
	if shared_control:
		shared_control.draw_red_line(x)
	red_line_x = -1
	if x > 0.0:
		red_line_x = x
	queue_redraw()

func queue_update_stream_editor():
	if not queued_update:
		queued_update = true
		call_deferred("update_stream_editor")
func update_stream_editor():
	stream_editor.start_point = start + variant_offset
	stream_editor.end_point = start + variant_size + variant_offset
	queued_update = false
	
func _gui_input(event):
	if allow_dragging:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					_drag_start_x = stream_editor.get_local_mouse_position().x
					_drag_start_size = variant_size
					_drag_start_time = start
					dragging = true
					draw_red_line(stream_editor.get_local_mouse_position().x)
				else:
					dragging = false
					draw_red_line(-1)
		if event is InputEventMouseMotion:
			if dragging:
				var time_delta = _drag_start_x - stream_editor.get_local_mouse_position().x
				time_delta /= stream_editor.size.x
				time_delta *= _drag_start_size
				set_start(_drag_start_time + time_delta)
				draw_red_line(stream_editor.get_local_mouse_position().x)

func _draw():
	if red_line_x > 0.0:
		draw_line(Vector2(red_line_x, 0.0), Vector2(red_line_x, size.y), Color.RED, 1.0)
