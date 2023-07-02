extends HBTask

class_name HBLoadMainMenuTask

var loaded_scene: Node
var scene_path: String

func _init(_scene_path: String):
	super()
	scene_path = _scene_path

func get_task_output_data():
	return loaded_scene

func _task_process() -> bool:
	loaded_scene = load(scene_path).instantiate() as Node
	return true
