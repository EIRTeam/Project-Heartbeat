extends Control

class_name EditorTimelineItem
var _class_name: String = "EditorTimelineItem" # Workaround for godot#4708
var _inheritance: Array = [] # HACK: ClassDB.get_parent_class() is retarded

# Emitted by children
# warning-ignore:unused_signal
signal property_changed(property_name, old_value, new_value)

var data = HBTimingPoint.new()

const DND_START_MARGIN = 25.0
const SIDE_MOVEMENT_DEADZONE = 10.0

var editor

var _drag_start_position : Vector2
var _drag_start_time : float
var _drag_x_offset : float
var _drag_new_time : float
var _drag_moving = false
var _dragging = false
var _layer
var _drag_last

var widget: HBEditorWidget
var update_affects_timing_points = false
signal time_changed

var _draw_selected_box = false

func _ready():
	deselect()
	set_process(false)
	queue_redraw()
	RenderingServer.canvas_item_set_z_index(get_canvas_item(), 1)
	add_to_group("editor_timeline_items")

func set_start(value: int):
	if data.time != value:
		data.time = value
		emit_signal("time_changed")


func get_editor_size():
	return Vector2(0, size.y)
func _process(delta):
	if _dragging:
		if abs(get_viewport().get_mouse_position().x - _drag_start_position.x) > SIDE_MOVEMENT_DEADZONE or _drag_moving:
			_drag_moving = true
			var new_time = _drag_start_time + editor.scale_pixels(get_viewport().get_mouse_position().x - _drag_start_position.x)
			new_time = int(editor.snap_time_to_timeline(new_time))
			var drag_delta = new_time -_drag_last
			_drag_last = new_time
			if abs(drag_delta) > 0:
				editor._change_selected_property_delta("time",  int(drag_delta), self)
				editor._change_selected_property_delta("end_time",  int(drag_delta), self)
				for item in editor.selected:
					item.emit_signal("time_changed")
#		set_start(clamp(new_time, 0.0, editor.get_song_duration()))

func deselect():
	_draw_selected_box = false
	queue_redraw()
	if widget:
		widget.queue_free()
		widget = null

func get_click_rect():
	var global_rect = get_global_rect()
	if has_node("TextureRect"):
		global_rect = $TextureRect.get_global_rect()
	return global_rect

func _gui_input(event: InputEvent):
	var global_rect = get_click_rect()
	
	if global_rect.has_point(get_global_mouse_position()):
		if event.is_action_pressed("editor_select") and not editor.game_playback.is_playing(): 
			if event is InputEventWithModifiers:
				get_viewport().set_input_as_handled()
				if not self in editor.selected:
					editor.select_item(self, event.shift_pressed)
				elif event.shift_pressed:
					editor.deselect_item(self)
				
				if not event.shift_pressed:
					_drag_moving = false
					_drag_start_position = get_viewport().get_mouse_position()
					_drag_start_time = data.time
					_drag_x_offset = (global_position - get_viewport().get_mouse_position()).x
					_drag_last = data.time
					set_process(true)
					_dragging = true
	
	if event.is_action_released("editor_select"):
		stop_dragging()

func stop_dragging():
	if _dragging:
		_drag_moving = false
		if is_processing():
			set_process(false)
			_dragging = false
			if _drag_start_time != data.time:
				editor._commit_selected_property_change("time")


func select():
	_draw_selected_box = true
	queue_redraw()
func _draw_timeline_item_selected():
	if _draw_selected_box:
		var selected_rect_size = Vector2(size.y, size.y) * 0.85
		var selected_square_rect = Rect2((Vector2(0.0, size.y) - selected_rect_size) / 2.0, selected_rect_size)
		draw_rect(selected_square_rect, Color.YELLOW, false, 1.0)
func _draw():
	_draw_timeline_item_selected()
		
func get_inspector_properties():
	pass
	
func get_editor_widget() -> PackedScene:
	return null
	
func connect_widget(_widget: HBEditorWidget):
	self.widget = _widget
	update_widget_data()
	if not editor.game_preview.widget_area.is_connected("widget_area_input", Callable(self, "_widget_area_input")):
		editor.game_preview.widget_area.connect("widget_area_input", Callable(self, "_widget_area_input"))

func _widget_area_input(event: InputEvent):
	if widget:
		widget._widget_area_input(event)
	
func update_widget_data():
	if widget:
		widget.starting_pos = data.position
		var new_pos = editor.rhythm_game.remap_coords(data.position)
		self.widget.position = new_pos - self.widget.size / 2
		widget.entry_angle = deg_to_rad(data.entry_angle)
		if not widget.note_data:
			widget.note_data = data

func get_duration():
	return 1000

func sync_value(property_name: String):
	if property_name == "time":
		set_start(data.time)
	if property_name == "position":
		if widget:
			widget.arrange_gizmo()

func get_ph_editor_description() -> String:
	return ""
