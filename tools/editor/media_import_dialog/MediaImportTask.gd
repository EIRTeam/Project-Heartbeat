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
	var _tmp_dir_access: DirAccess
	var error: ImportError
	var final_audio_path: String
	var final_video_path: String
	var error_message: String
	var audio_loudness := 0.0

enum MediaApplyImportError {
	OK,
	AUDIO_COPY_FAILED,
	VIDEO_COPY_FAILED,
	INVALID_VARIANT_IDX
}

class MediaApplyImportResult:
	var error: MediaApplyImportError
	var error_message: String
	func _init(_error: MediaApplyImportError, _error_message: String):
		error = _error
		error_message = _error_message

var import_data: MediaImportDialog.MediaImportDialogResult
var target_path: String

var result := MediaImportTaskResult.new()

var task_id: int

signal finished(result: MediaImportTaskResult)

static func apply_import(song_meta: HBSong, song_folder: String, result: MediaImportTaskResult, variant := -1) -> MediaApplyImportResult:
	var audio_path: String
	var video_path: String
	if not result.final_audio_path.is_empty():
		audio_path = "audio.ogg"
		
		if variant != -1:
			var variant_idx := variant
			var variant_audio_path := "audio_v%d.ogg" % [variant_idx]
			
			while FileAccess.file_exists(variant_audio_path):
				variant_idx += 1
				variant_audio_path = "audio_v%d.ogg" % [variant_idx]
			audio_path = variant_audio_path
		var copy_result := DirAccess.copy_absolute(result.final_audio_path, song_folder.path_join(audio_path))
		if copy_result != OK:
			return MediaApplyImportResult.new(
				MediaApplyImportError.AUDIO_COPY_FAILED,
				"Error copying audio, error code %d" % copy_result
			)
	if not result.final_video_path.is_empty():
		var video_ext := result.final_video_path.get_extension()
		video_path = "video.%s" % [video_ext]
		if variant != -1:
			var variant_idx := variant
			var variant_video_path := "video_v%d.%s" % [variant_idx, video_ext]
			
			while FileAccess.file_exists(variant_video_path):
				variant_idx += 1
				variant_video_path = "video_v%d.ogg" % [variant_idx, video_ext]
			video_path = variant_video_path
		var copy_result := DirAccess.copy_absolute(result.final_video_path, song_folder.path_join(video_path))
		if copy_result != OK:
			return MediaApplyImportResult.new(
				MediaApplyImportError.VIDEO_COPY_FAILED,
				"Error copying video, error code %d" % copy_result
			)
			
	if not song_meta.has_variant(variant):
		# Passed invalid variant idx, oh my...
		if not song_meta.song_variants.size() == variant:
			return MediaApplyImportResult.new(
				MediaApplyImportError.INVALID_VARIANT_IDX,
				"Invalid variant IDX %d!" % [variant] 
			)
			
	song_meta.set_variant_audio_path(variant, audio_path)
	song_meta.set_variant_video_path(variant, video_path)
	song_meta.set_variant_audio_loudness(variant, result.audio_loudness)
	return MediaApplyImportResult.new(MediaApplyImportError.OK, "")
			

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
		
		var ss := Shinobu.register_sound_from_memory("meta_editor_norm_temp", HBUtils.load_ogg(result.final_audio_path).get_meta("raw_file_data"))
		var res = ss.ebur128_get_loudness()
		result.audio_loudness = res
	
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
func _init(_import_data: MediaImportDialog.MediaImportDialogResult) -> void:
	import_data = _import_data
	if not import_data.has_audio_stream and not not import_data.has_video_stream:
		printerr("Tried to import without data?")
		_notify_import_error(ImportError.NO_AUDIO_AND_VIDEO, null)
		return
	
	result._tmp_dir_access = DirAccess.create_temp("tmp_video")
	var tmp_dir := result._tmp_dir_access.get_current_dir()
	var media_base_path := tmp_dir.path_join("media")
	target_path = media_base_path
	
	task_id = WorkerThreadPool.add_task(_task_execute, true, "Import song media")
