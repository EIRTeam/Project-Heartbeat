extends Node

var input_manager: HBGameInputManager

class GestureManager:
	const SWIPE_DISTANCE = 5.0
	const MAX_DIAGONAL_SLOPE = 1.3
	
	var index: int
	var direction := Vector2.ZERO
	var starting_pos: Vector2
	var current_pos: Vector2
	var is_tapping = false
	var input_mode = 0
	signal swipe_started(direction)
	signal swipe_ended(direction)
	signal tap_started(position)
	signal tap_ended(position)
	
	func _init(_index: int, _starting_pos: Vector2, _current_pos: Vector2, _input_mode: int):
		self.index = _index
		self.starting_pos = _starting_pos
		self.current_pos = _current_pos
		self.input_mode = _input_mode
	func begin_detection():
		if input_mode == 0:
			do_tap()
	func do_tap():
		is_tapping = true
		emit_signal("tap_started", current_pos)
	func is_sliding():
		return direction != Vector2.ZERO
	func change_position(new_position: Vector2):
		if input_mode == 1:
			var previous_position = current_pos
			current_pos = new_position
			if not is_sliding() and not is_tapping:
				if starting_pos.distance_to(current_pos) > 20:
					_on_swipe_begun()
			if is_sliding():
				if sign(current_pos.x - previous_position.x) != 0:
					if sign(direction.x) != sign(current_pos.x - previous_position.x):
						release_touch()
			
	func release_touch():
		if is_tapping:
			emit_signal("tap_ended", current_pos)
		elif is_sliding():
			emit_signal("swipe_ended", direction)
		elif not is_tapping:
			do_tap()
			emit_signal("tap_ended", current_pos)
			
	func _on_swipe_begun():
		direction = (current_pos - starting_pos).normalized()
		# Swipe angle is too steep
#		if abs(direction.x) + abs(direction.y) >= MAX_DIAGONAL_SLOPE:
#			return
	
		direction = Vector2(sign(direction.x), 0.0)
		emit_signal("swipe_started", direction)

enum InputMode {
	TAPS,
	SLIDES
}

var gestures = []

# warning-ignore:unused_signal
signal swipe_canceled(start_position)
# warning-ignore:unused_signal
signal swipe_started(direction)
@export var swipe_min_distance: float = 20.0
@onready var timer: Node = $SwipeTimeout
var swipe_start_position: = Vector2()
var last_drag = 0
var input_mode = InputMode.TAPS

func get_gesture_for_index(idx: int):
	for gesture in gestures:
		if gesture.index == idx:
			return gesture

func _init():
	name = "SwipeDetector"

func _input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch and not event is InputEventScreenDrag:
		return
		
		
	var event_index = 0
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		event_index = event.index

	var current_gesture = get_gesture_for_index(event_index) as GestureManager

	if event is InputEventScreenTouch:
		if event.pressed:
			if not current_gesture:
				var swipe_status_timer = timer.duplicate()
				add_child(swipe_status_timer)
				var gesture = GestureManager.new(event_index, event.position, event.position, input_mode)
				gestures.append(gesture)
				gesture.connect("swipe_started", Callable(self, "_on_swipe_started").bind(gesture))
				gesture.connect("swipe_ended", Callable(self, "_on_swipe_ended").bind(gesture))
				gesture.connect("tap_started", Callable(self, "_on_tap_started").bind(gesture))
				gesture.connect("tap_ended", Callable(self, "_on_tap_ended").bind(gesture))
				gesture.begin_detection()
			else:
				print("IGNORING TOCH CUZ WE ALREADY HAVE IT")
		else:
			if current_gesture:
				var status := current_gesture as GestureManager
				status.release_touch()
				remove_gesture(status)
	if event is InputEventScreenDrag:
		var cur = Time.get_ticks_usec()
		last_drag = cur
		if current_gesture:
			var gesture := current_gesture as GestureManager
			gesture.change_position(event.position)
var process_time = 0
func _process(delta):
	process_time += delta

func send_event(action, pressed, gest):
	if input_manager and is_instance_valid(input_manager):
		input_manager.send_input(action, pressed, 1, gest)

func _on_swipe_started(direction: Vector2, gesture: GestureManager):
	var action = "slide_left"
	if direction == Vector2.RIGHT:
		action = "slide_right"
	send_event(action, true, gesture.index)
func _on_swipe_ended(direction: Vector2, gesture: GestureManager):
	var action = "slide_left"
	if direction == Vector2.RIGHT:
		action = "slide_right"
	send_event(action, true, gesture.index)
func remove_gesture(gesture: GestureManager):
	gestures.erase(gesture)
	for ges in gestures:
		if ges.index > gesture.index:
			ges.index -= 1
func _on_tap_started(position: Vector2, gesture: GestureManager):
	var button = clamp(int(position.x / (get_viewport().get_size_2d_override().x/4.0)), 0, 3)
	var action = HBGame.NOTE_TYPE_TO_ACTIONS_MAP[button][0]
	send_event(action, true, gesture.index)

func _on_tap_ended(position: Vector2, gesture: GestureManager):
	var button = int(position.x / (get_window().get_size_with_decorations().x / 4.0))
	var action = HBGame.NOTE_TYPE_TO_ACTIONS_MAP[button][0]
	send_event(action, false, gesture.index)
