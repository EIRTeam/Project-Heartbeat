extends Panel

class_name EditorTimelineItem

signal item_changed

var data = HBTimingPoint.new()

const DND_START_MARGIN = 25.0

var editor

var _drag_start_position : Vector2
var _drag_start_time : float
var _drag_x_offset : float
var _layer
func _ready():
	deselect()
	set_process(false)

func set_start(value: int):
	data.time = value
	emit_signal("item_changed")

func get_editor_size():
	return Vector2(editor.scale_msec(get_duration()), rect_size.y)

func _process(delta):
	
	if abs(get_viewport().get_mouse_position().y - _drag_start_position.y) > DND_START_MARGIN:
		force_drag(self, Control.new())
		set_process(false)
	else:
		set_start(clamp(_drag_start_time + editor.scale_pixels(get_viewport().get_mouse_position().x - _drag_start_position.x), 0.0, editor.get_song_duration()))

func deselect():
	$SelectedPanel.hide()

func _gui_input(event: InputEvent):
	if event.is_action_pressed("editor_select"):
		_drag_start_position = get_viewport().get_mouse_position()
		_drag_start_time = data.time
		_drag_x_offset = (rect_global_position - get_viewport().get_mouse_position()).x
		set_process(true)
		editor.select_item(self)

	elif event.is_action_released("editor_select"):
		set_process(false)
		
func select():
	$SelectedPanel.show()
		
func get_inspector_properties():
	return {
		"time": "int",
		"position": "Vector2"
	}
	
func get_duration():
	return 1000
