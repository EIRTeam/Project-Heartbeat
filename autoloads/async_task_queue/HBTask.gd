class_name HBTask

# warning-ignore:unused_signal
signal task_done(data)

var _aborted := false
var _done := true
func _init():
	connect("task_done", self, "_on_task_finished_processing", [], CONNECT_DEFERRED)

# Returns false if task it not done
func _task_process() -> bool:
	return false
	
func _on_task_finished_processing(data):
	pass
func get_task_output_data():
	return null
