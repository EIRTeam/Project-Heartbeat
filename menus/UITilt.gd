extends Node3D

func _process(delta: float) -> void:
	const MAX_TILT_ANGLE := deg_to_rad(2.0)
	var tilt_vector := Input.get_vector(&"gui_tilt_up", &"gui_tilt_down", &"gui_tilt_left", &"gui_tilt_right")
	var tilt_vector_3d := Vector3.FORWARD.rotated(Vector3.RIGHT, tilt_vector.x * MAX_TILT_ANGLE)
	tilt_vector_3d = tilt_vector_3d.rotated(Vector3.UP, MAX_TILT_ANGLE * tilt_vector.y)
	look_at(tilt_vector_3d)
