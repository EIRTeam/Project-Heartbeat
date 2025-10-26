extends AcceptDialog

class_name MediaImporterUI

@onready var error_dialog: AcceptDialog = AcceptDialog.new()

enum MediaImporterUIError {
	OK,
	IMPORT_FAILED,
	APPLY_FAILED
}

class MediaImporterUIResult:
	var error: MediaImporterUIError
	func _init(_error: MediaImporterUIError) -> void:
		error = _error

signal import_finished(result: MediaImporterUIResult)

func _ready() -> void:
	add_child(error_dialog)
	dialog_text = "Importing media..."
	get_ok_button().hide()
	hide()
	exclusive = true

func show_error(error: String):
	error_dialog.dialog_text = error
	error_dialog.size = Vector2.ZERO
	error_dialog.popup_centered(Vector2(500, 100))
	hide()

func do_import(song_meta: HBSong, video_import: MediaImportDialog.MediaImportDialogResult, variant := -1):
	popup_centered()
	
	var editor_song_folder = HBUtils.join_path(UserSettings.get_content_directories(true)[0], "editor_songs/%s")
	editor_song_folder = editor_song_folder % song_meta.id
	
	if video_import:
		if not DirAccess.dir_exists_absolute(editor_song_folder):
			var mkdir_result := DirAccess.make_dir_recursive_absolute(editor_song_folder)
			if mkdir_result != OK:
				show_error("Error creating song dir, error code %d" % mkdir_result)
		
		var import_task := MediaImportTask.new(video_import)
		var result: MediaImportTask.MediaImportTaskResult = await import_task.finished
		if result.error != MediaImportTask.ImportError.OK:
			show_error("Error importing media for song:\n%s" % [result.error_message])
			import_finished.emit(MediaImporterUIResult.new(MediaImporterUIError.IMPORT_FAILED))
			return
		
		var apply_result := MediaImportTask.apply_import(song_meta, editor_song_folder, result, variant)
		if apply_result.error != MediaImportTask.MediaApplyImportError.OK:
			show_error("Error copying media for song:\n%s" % [apply_result.error_message])
			import_finished.emit(MediaImporterUIResult.new(MediaImporterUIError.APPLY_FAILED))
			return
	import_finished.emit(MediaImporterUIResult.new(MediaImporterUIError.OK))
