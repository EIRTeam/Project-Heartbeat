class_name HBJoystickData

const DEADZONE_MAX := 1.0

enum AXIS_BITFIELD {
	X = 0b1,
	Y = 0b10,
}

enum EVENT_STATES {
	SLIDE_LEFT = 1 << 0,
	SLIDE_RIGHT = 1 << 1,
	HEART = 1 << 2,
}

class MergedAxis:
	var axises: int
	var value: Vector2
	var timestamp := 0

var x_axis_idx := 0
var y_axis_idx := 0
var event_buffer: Array[InputEventJoypadMotion]
var joy_value: Vector2
var event_states := 0
var device_idx: int

func _init(_device_idx: int, _x_axis_idx: int, _y_axis_idx: int):
	x_axis_idx = _x_axis_idx
	y_axis_idx = _y_axis_idx
	device_idx = _device_idx
	joy_value.x = Input.get_joy_axis(device_idx, x_axis_idx)
	joy_value.y = Input.get_joy_axis(device_idx, y_axis_idx)

func _on_device_disconnected():
	var ev1 := InputEventJoypadMotion.new()
	ev1.axis = x_axis_idx
	ev1.axis_value = 0.0
	var ev2 := InputEventJoypadMotion.new()
	ev2.axis = y_axis_idx
	ev2.axis_value = 0.0
	push_input(ev1)
	push_input(ev2)

func _emulate_low_rate_input() -> bool:
	var ax := Vector2(Input.get_joy_axis(0, x_axis_idx), Input.get_joy_axis(0, y_axis_idx))
	if ax != joy_value && Engine.get_process_frames() % 60 == 0:
		var ev1 := InputEventJoypadMotion.new()
		ev1.axis = x_axis_idx
		ev1.axis_value = Input.get_joy_axis(0, x_axis_idx)
		var ev2 := InputEventJoypadMotion.new()
		ev2.axis = y_axis_idx
		ev2.axis_value = Input.get_joy_axis(0, y_axis_idx)
		event_buffer.push_back(ev1)
		event_buffer.push_back(ev2)
		return true
	return false
func merge_events() -> Array[MergedAxis]:
	var merged_events: Array[MergedAxis]
	merged_events.clear()
	while event_buffer.size() > 0:
		var ev := event_buffer[-1]
		var merged_ev := MergedAxis.new()
		merged_ev.value = Vector2()
		merged_ev.axises = AXIS_BITFIELD.X if ev.axis == x_axis_idx else AXIS_BITFIELD.Y
		merged_ev.value += Vector2(ev.axis_value, 0.0) if ev.axis == x_axis_idx else Vector2(0.0, ev.axis_value)
		merged_ev.timestamp = ev.timestamp
		if event_buffer.size() > 1 and event_buffer[-2].axis != ev.axis:
			var ev_prev := event_buffer[-2]
			merged_ev.axises = merged_ev.axises | (AXIS_BITFIELD.X if ev_prev.axis == x_axis_idx else AXIS_BITFIELD.Y)
			merged_ev.value += Vector2(ev_prev.axis_value, 0.0) if ev_prev.axis == x_axis_idx else Vector2(0.0, ev_prev.axis_value)
			merged_ev.timestamp = max(merged_ev.timestamp, ev_prev.timestamp)
			event_buffer.pop_back()
		event_buffer.pop_back()
		merged_events.push_back(merged_ev)
	merged_events.reverse()
	
	event_buffer.clear()
	return merged_events
func push_input(event: InputEventJoypadMotion) -> bool:
	if (event.axis == x_axis_idx or event.axis == y_axis_idx) and event.device == device_idx:
		event_buffer.push_back(event)
		return true
	return false

static func event_intersects_deadzone(deadzone: float, prev_pos: Vector2, new_pos: Vector2) -> bool:
	return false
	return Geometry2D.segment_intersects_circle(prev_pos, new_pos, Vector2.ZERO, deadzone) != -1

