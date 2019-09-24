extends Panel

class_name EditorTimelineItem

signal item_bounds_changed

export (float) var start = 0 setget set_start
export (float) var duration = 1 setget set_duration

const DND_START_MARGIN = 25.0

var editor

var _drag_start_position : Vector2
var _drag_start_time : float
var _drag_x_offset : float
var _layer
func _ready():
	set_process(false)

func set_start(value: float):
	start = value
	emit_signal("item_bounds_changed")
	
func set_duration(value: float):
	duration = value
	emit_signal("item_bounds_changed")

func _process(delta):
	if abs(get_viewport().get_mouse_position().y - _drag_start_position.y) > DND_START_MARGIN:
		force_drag(self, Control.new())
		set_process(false)
	set_start(clamp(_drag_start_time + editor.scale_pixels(get_viewport().get_mouse_position().x - _drag_start_position.x), 0.0, 10000.0))

func _gui_input(event: InputEvent):
	if event.is_action_pressed("editor_select"):
		_drag_start_position = get_viewport().get_mouse_position()
		_drag_start_time = start
		_drag_x_offset = (rect_global_position - get_viewport().get_mouse_position()).x
		set_process(true)
	elif event.is_action_released("editor_select"):
		set_process(false)
