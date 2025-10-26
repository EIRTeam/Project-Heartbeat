## Video import task
class_name MediaImportTask

enum ImportError {
	OK,
	FILE_ALREADY_EXISTS,
	NO_AUDIO_AND_VIDEO,
	AUDIO_IMPORT_FAILED,
	VIDEO_IMPORT_FAILED
}

## Do note that for the final path we may choose to rename it based on the extension of the actual container
## hence why you should always use the container's final path
class MediaImportTaskResult:
	var error: ImportError
	var final_audio_path: String
	var final_video_path: String
	var error_message: String

var import_data: MediaImportDialog.MediaImportDialogResult
var target_path: String

var result := MediaImportTaskResult.new()

var task_id: int

signal finished(result: MediaImportTaskResult)

func _notify_import_error(error: ImportError, process: Process):
	var error_strs: PackedStringArray
	match error:
		ImportError.FILE_ALREADY_EXISTS:
			error_strs.append("File already exists!")
		ImportError.NO_AUDIO_AND_VIDEO:
			error_strs.append("Selected file did not contain video or audio!")
		ImportError.AUDIO_IMPORT_FAILED:
			error_strs.append("Audio import failed:")
		ImportError.VIDEO_IMPORT_FAILED:
			error_strs.append("Video import failed:")
	if error in [ImportError.VIDEO_IMPORT_FAILED, ImportError.AUDIO_IMPORT_FAILED]:
		if process:
			for _i in range(process.get_available_stderr_lines()):
				error_strs.append(process.get_stderr_line())
	result.error_message = "\n".join(error_strs)
	result.error = error
	finished.emit(result)

func _notify_import_ok():
	finished.emit(result)

func _task_finished():
	WorkerThreadPool.wait_for_task_completion(task_id)

func _task_execute():
	# Launch import
	var ffmpeg_exe := YoutubeDL.get_ffmpeg_executable() as String
	
	var audio_import_process: Process
	if import_data.has_audio_stream:
		result.final_audio_path = target_path + ".ogg"
		var args := ["-i", import_data.selected_video_path, "-vn", "-acodec", "libvorbis", result.final_audio_path]
		audio_import_process = PHNative.create_process(ffmpeg_exe, args)
	
		while audio_import_process.get_exit_status() == -1:
			OS.delay_msec(150)
		
		var exit_status = audio_import_process.get_exit_status()
		if exit_status != OK:
			_notify_import_error.call_deferred(ImportError.AUDIO_IMPORT_FAILED, audio_import_process)
			_task_finished.call_deferred()
			return
	
	var video_import_process: Process
	if import_data.has_video_stream:
		result.final_video_path = target_path + "." + import_data.selected_video_path.get_extension()
		var args := ["-i", import_data.selected_video_path, "-c", "copy", "-an", result.final_video_path]
		video_import_process = PHNative.create_process(ffmpeg_exe, args)
		while video_import_process.get_exit_status() == -1:
			OS.delay_msec(150)
		
		var exit_status = video_import_process.get_exit_status()
		if exit_status != OK:
			_notify_import_error.call_deferred(ImportError.VIDEO_IMPORT_FAILED, video_import_process)
			_task_finished.call_deferred()
			return
	result.error = ImportError.OK
	_notify_import_ok.call_deferred()
	_task_finished.call_deferred()

## _target_path should be the path without extensions
func _init(_import_data: MediaImportDialog.MediaImportDialogResult, _target_path: String) -> void:
	import_data = _import_data
	target_path = _target_path
	if not import_data.has_audio_stream and not not import_data.has_video_stream:
		printerr("Tried to import without data?")
		return
	
	task_id = WorkerThreadPool.add_task(_task_execute, true, "Import song media")
