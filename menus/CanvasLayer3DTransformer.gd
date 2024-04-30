extends Node3D

class_name CanvasLayer3DTransformer

func _ready() -> void:
	set_notify_transform(true)

func _update_transform():
	var cl_3d := get_child(0) as CanvasLayer
	if cl_3d:
		cl_3d.use_3d_transform = true
		cl_3d.transform_3d = global_transform

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			_update_transform()
