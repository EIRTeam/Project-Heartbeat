extends Popup

class_name HBEditorArrangeMenu


signal angle_changed(new_angle, reverse)


onready var arrow_texture = get_node("ArrowTexture")

var editor setget set_editor
var rotation := 0.0 # In radians
var rotation_snaps := 16
var reverse := false

var normal_texture := StreamTexture.new()
var reverse_texture := StreamTexture.new()

func _ready():
	arrow_texture.rect_pivot_offset = arrow_texture.rect_size / 2
	normal_texture.load("res://.import/arrange-arrow.png-8e2c664528b9e0a712a8a9569f79ed1f.stex")
	reverse_texture.load("res://.import/arrange-arrow-backwards.png-60739e1bbc3bd3b625285ddd3f8df5f3.stex")

func _input(event):
	if visible:
		if event is InputEventKey:
			if event.alt != reverse:
				reverse = event.alt
				emit_signal("angle_changed", rotation, reverse)
				arrow_texture.texture = normal_texture if not reverse else reverse_texture
		
		if event is InputEventMouseMotion:
			var new_rotation := rotation 
			if get_global_mouse_position().distance_to(rect_position) > 10:
				new_rotation = get_global_mouse_position().angle_to_point(rect_position)
			
			if not Input.is_key_pressed(KEY_CONTROL):
				new_rotation /= PI / (rotation_snaps / 2.0)
				new_rotation = round(new_rotation) * (PI / (rotation_snaps / 2.0))
			
			if new_rotation != rotation:
				emit_signal("angle_changed", new_rotation, reverse)
				arrow_texture.set_rotation(new_rotation)
			
			rotation = new_rotation


func get_angle():
	return rotation

func set_editor(_editor):
	editor = _editor
