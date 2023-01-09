extends Popup

class_name HBEditorArrangeMenu

signal angle_changed(new_angle, reverse, autoangle_toggle)

onready var clip_mask = get_node("Control")
onready var arc_drawer = get_node("Control/Control")
onready var reverse_indicator = get_node("Control/ReverseIndicator")

var editor setget set_editor
var rotation := 0.0 # In radians
var reverse := false
var autoangle_toggle := false

func _input(event):
	if visible:
		if Input.is_key_pressed(KEY_SHIFT) != reverse:
			reverse = Input.is_key_pressed(KEY_SHIFT)
			reverse_indicator.visible = reverse
			emit_signal("angle_changed", rotation, reverse, autoangle_toggle)
		
		if Input.is_key_pressed(KEY_CONTROL) != autoangle_toggle:
			autoangle_toggle = Input.is_key_pressed(KEY_CONTROL)
			emit_signal("angle_changed", rotation, reverse, autoangle_toggle)
		
		if event is InputEventMouseMotion:
			var mouse_pos := get_global_mouse_position() - Vector2(120, 120)
			var mouse_distance := mouse_pos.distance_to(rect_position)
			
			var new_rotation := rotation
			if mouse_distance > 10:
				new_rotation = mouse_pos.angle_to_point(rect_position)
			
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
				emit_signal("angle_changed", new_rotation, reverse, autoangle_toggle)
			
			rotation = new_rotation
			update()
	else:
		rotation = 0.0

func _draw():
	var parent = get_parent_control()
	clip_mask.rect_position = Vector2.ZERO
	clip_mask.rect_size = Vector2(240, 240)
	
	var clip = clip_mask.get_global_rect().clip(parent.get_global_rect())
	
	clip_mask.rect_global_position = clip.position
	clip_mask.rect_size = clip.size
	
	$Control/BaseTexture.rect_position = -clip_mask.rect_position
	arc_drawer.rect_position = Vector2(120, 120) - clip_mask.rect_position
	reverse_indicator.rect_position = Vector2(161, 169) - clip_mask.rect_position
	
	if visible:
		var mouse_pos := get_global_mouse_position() - Vector2(120, 120)
		arc_drawer.mouse_distance = mouse_pos.distance_to(rect_position)
		arc_drawer.rotation = rotation
		arc_drawer.update()

func get_angle():
	return rotation

func set_editor(_editor):
	editor = _editor
