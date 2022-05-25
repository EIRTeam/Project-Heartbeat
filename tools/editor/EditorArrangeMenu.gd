extends Popup

class_name HBEditorArrangeMenu

signal angle_changed(new_angle, reverse)

onready var arc_drawer = get_node("Control")

var editor setget set_editor
var rotation := 0.0 # In radians
var reverse := false

func _input(event):
	if visible:
		if event is InputEventWithModifiers:
			if event.shift != reverse:
				reverse = event.shift
				$ReverseIndicator.visible = reverse
				emit_signal("angle_changed", rotation, reverse)
		
		if event is InputEventMouseMotion:
			var mouse_distance := get_global_mouse_position().distance_to(rect_position)
			
			var new_rotation := rotation
			if mouse_distance > 10:
				new_rotation = get_global_mouse_position().angle_to_point(rect_position)
			
			var _rotation_snaps
			if mouse_distance > 70:
				_rotation_snaps = -1
			elif mouse_distance > 44:
				_rotation_snaps = 36
			else:
				_rotation_snaps = 8
			
			if _rotation_snaps != -1:
				new_rotation /= PI / (_rotation_snaps / 2.0)
				new_rotation = round(new_rotation) * (PI / (_rotation_snaps / 2.0))
			
			if new_rotation != rotation:
				emit_signal("angle_changed", new_rotation, reverse)
			
			rotation = new_rotation
			update()
	else:
		rotation = 0.0

func _draw():
	if visible:
		arc_drawer.mouse_distance = get_global_mouse_position().distance_to(rect_position)
		arc_drawer.rotation = rotation
		arc_drawer.update()

func get_angle():
	return rotation

func set_editor(_editor):
	editor = _editor
