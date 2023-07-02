class_name HBTask

# warning-ignore:unused_signal
signal task_done(data)

var _aborted := false
var _done := true
func _init():
	print("çAINIT")
	connect("task_done", Callable(self, "_on_task_finished_processing"), CONNECT_DEFERRED)

# Returns false if task it not done
func _task_process() -> bool:
	return false
	
func _on_task_finished_processing(data):
	print("TASK DONE")
	call_deferred("free")

func get_task_output_data():
	return null
