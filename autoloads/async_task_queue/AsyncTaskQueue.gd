extends Node

var thread := Thread.new()
var semaphore := Semaphore.new()
var mutex := Mutex.new()
var exit_thread := false

var queue = []
func _ready() -> void:
	assert(thread.start(self, "_thread_function") == OK, "Error creating async task queue")
	set_physics_process(false)

func queue_task(task: HBTask) -> void:
	mutex.lock()
	queue.append(task)
	mutex.unlock()
	set_process(true)

func abort_task(task: HBTask) -> void:
	mutex.lock()
	if task in queue:
		task._aborted = true
		if queue.empty():
			set_process(false)
	mutex.unlock()
	
func _process(delta):
	mutex.lock()
	var queue_size := queue.size() as int
	mutex.unlock()
	
	if queue_size > 0:
		semaphore.post()
		
func is_task_aborted(task: HBTask):
	mutex.lock()
	var task_aborted = task._aborted
	mutex.unlock()
	return task_aborted
		
func _thread_function(_userdata):
	while true:
		# wait to be posted (AKA to be asked to do a process cycle)
		semaphore.wait()
		
		mutex.lock()
		var should_exit = exit_thread # Protect with Mutex.
		mutex.unlock()
		
		if should_exit:
			break
		
		var current_task: HBTask
		
		mutex.lock()
		if not queue.empty():
			for i in range(queue.size()-1, -1, -1):
				var task = queue[i]
				if task._aborted:
					queue.erase(task)
					task.free()
				else:
					current_task = task
					break
		mutex.unlock()
		
		if current_task:
			if current_task._task_process():
				mutex.lock()
				if not current_task._aborted:
					current_task.call_deferred("emit_signal", "task_done")
				queue.erase(current_task)
				mutex.unlock()
		mutex.lock()
		if current_task:
			if current_task._aborted:
				queue.erase(current_task)
				current_task.free()
		mutex.unlock()
func _exit_tree():
	# Set exit condition to true.
	mutex.lock()
	exit_thread = true # Protect with Mutex.
	mutex.unlock()

	# Unblock by posting.
	semaphore.post()

	# Wait until it exits.
	thread.wait_to_finish()
