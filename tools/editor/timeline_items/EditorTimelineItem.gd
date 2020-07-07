extends Control

class_name EditorTimelineItem

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

func _ready():
	deselect()
	set_process(false)
	update()

func set_start(value: int):
	if data.time != value:
		data.time = value
		emit_signal("time_changed")


func get_editor_size():
	return Vector2(0, rect_size.y)
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
	modulate = Color.white
	if widget:
		widget.queue_free()
		widget = null

func _gui_input(event: InputEvent):
	var global_rect = get_global_rect()
	if has_node("TextureRect"):
		global_rect = $TextureRect.get_global_rect()
		
	if global_rect.has_point(get_global_mouse_position()):
		if event.is_action_pressed("editor_select"): 
				if event is InputEventWithModifiers:
					get_tree().set_input_as_handled()
					if not self in editor.selected:
						editor.select_item(self, event.shift)
					
					if not event.shift:
						_drag_moving = false
						_drag_start_position = get_viewport().get_mouse_position()
						_drag_start_time = data.time
						_drag_x_offset = (rect_global_position - get_viewport().get_mouse_position()).x
						_drag_last = data.time
						set_process(true)
						_dragging = true
	if event.is_action_released("editor_select") and not event.is_echo() and _dragging:
		_drag_moving = false
		if is_processing():
			get_tree().set_input_as_handled()
			set_process(false)
			_dragging = false
			if _drag_start_time != data.time:
				editor._commit_selected_property_change("time")
#		if _drag_start_time != data.time:
#			emit_signal("property_changed", "time", _drag_start_time, data.time)
			
		
func select():
	modulate = Color(0.5, 0.5, 0.5, 1.0)
		
func get_inspector_properties():
	pass
	
func get_editor_widget() -> PackedScene:
	return null
	
func connect_widget(_widget: HBEditorWidget):
	self.widget = _widget
	update_widget_data()
	if not editor.game_preview.widget_area.is_connected("widget_area_input", self, "_widget_area_input"):
		editor.game_preview.widget_area.connect("widget_area_input", self, "_widget_area_input")

func _widget_area_input(event: InputEvent):
	if widget:
		widget._widget_area_input(event)
	
func update_widget_data():
	if widget:
		widget.starting_pos = data.position
		var new_pos = editor.rhythm_game.remap_coords(data.position)
		self.widget.rect_position = new_pos - self.widget.rect_size / 2
		widget.entry_angle = deg2rad(data.entry_angle)
	
func get_duration():
	return 1000

func sync_value(property_name: String):
	if property_name == "time":
		set_start(data.time)
	if property_name == "position":
		if widget:
			widget.arrange_gizmo()
