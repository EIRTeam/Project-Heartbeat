extends Object

class_name HBTask

signal task_done

var _aborted := false
var _done := true
func _init():
	connect("task_done", self, "_on_task_finished_processing")

# Returns false if task it not done
func _task_process() -> bool:
	return false
	
func _on_task_finished_processing():
	free()
