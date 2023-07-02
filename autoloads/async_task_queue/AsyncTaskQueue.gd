extends Node

class_name HBAsyncTaskQueue

const LOG_NAME = "AsyncTaskQueue"

var thread := Thread.new()
var semaphore := Semaphore.new()
var mutex := Mutex.new()
var exit_thread := false

var queue = []
func _ready() -> void:
	var err = thread.start(Callable(self, "_thread_function").bind({}))
	if err != OK:
		Log.log(self, "Error creating async task queue (%d)" % [err], Log.LogLevel.ERROR)
	assert(err == OK, "Error creating async task queue")
	set_process(false)
	process_mode = Node.PROCESS_MODE_ALWAYS

func queue_task(task: HBTask) -> void:
	if task:
		mutex.lock()
		queue.append(task)
		mutex.unlock()
		set_process(true)
	else:
		push_error("Error pushing task!")

func abort_task(task: HBTask) -> void:
	mutex.lock()
	if task in queue:
		task._aborted = true
		if queue.is_empty():
			set_process(false)
	mutex.unlock()
	
func _process(delta):
	mutex.lock()
	var queue_size := queue.size() as int
	mutex.unlock()
	_thread_function(null)
	
func is_task_aborted(task: HBTask):
	mutex.lock()
	var task_aborted = task._aborted
	mutex.unlock()
	return task_aborted
		
func _thread_function(_userdata):
	# wait to be posted (AKA to be asked to do a process cycle)
	mutex.lock()
	var should_exit = exit_thread # Protect with Mutex.
	mutex.unlock()
	
	if should_exit:
		return
	
	var current_task: HBTask
	
	mutex.lock()
	if not queue.is_empty():
		for i in range(queue.size()-1, -1, -1):
			var task = queue[i]
			if task._aborted:
				queue.erase(task)
			else:
				current_task = task
				break
	mutex.unlock()
	
	if current_task:
		if current_task._task_process():
			mutex.lock()
			if not current_task._aborted:
				print("EMIT SIGNAL", current_task.get_signal_connection_list("task_done"))
				
				current_task.call_deferred("emit_signal", "task_done", current_task.get_task_output_data())
			queue.erase(current_task)
			mutex.unlock()
		
func _end_thread():
	# Set exit condition to true.
	mutex.lock()
	if exit_thread == true:
		return
	exit_thread = true # Protect with Mutex.
	mutex.unlock()

func _exit_tree():
	_end_thread()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_end_thread()
