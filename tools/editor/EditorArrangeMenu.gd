extends Popup

class_name HBEditorArrangeMenu


signal angle_changed(new_angle)


onready var arrow_texture = get_node("ArrowTexture")

var rotation := 0.0 # In radians
var rotation_snaps := 16
var selected_backup := [] setget backup_selected, get_selected_backup


func _ready():
	arrow_texture.rect_pivot_offset = arrow_texture.rect_size / 2

func _input(event):
	if visible:
		if event is InputEventMouseMotion:
			var new_rotation : float = get_global_mouse_position().angle_to_point(rect_position)
			
			if not Input.is_key_pressed(KEY_SHIFT):
				new_rotation /= PI / (rotation_snaps / 2.0)
				new_rotation = round(new_rotation) * (PI / (rotation_snaps / 2.0))
			
			if new_rotation != rotation:
				emit_signal("angle_changed", new_rotation)
			
			rotation = new_rotation
			arrow_texture.set_rotation(rotation)


func get_angle():
	return rotation

func backup_selected(selected):
	selected_backup = selected
func get_selected_backup():
	return selected_backup
