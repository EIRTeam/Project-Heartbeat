extends ConfirmationDialog

class_name HBCreateSongDialog

@onready var title_line_edit: LineEdit = get_node("%Title")
@onready var error_dialog: AcceptDialog = get_node("%ErrorDialog")
@onready var no_video_audio_dialog: AcceptDialog = get_node("%NoVideoAudioDialog")
@onready var select_video_button: Button = get_node("%SelectVideoButton")
var selected_video_info: MediaImportDialog.MediaImportDialogResult

signal accepted(song_title: String, media_info: MediaImportDialog.MediaImportDialogResult)

func _update_ok_button_disabled():
	var has_title := not title_line_edit.text.is_empty()
	get_ok_button().disabled = not has_title

func _show_error(error: String):
	error_dialog.dialog_text = error
	error_dialog.popup_centered()

func _validate() -> bool:
	var title_validated := HBUtils.get_valid_filename(title_line_edit.text)
	if title_validated.is_empty():
		_show_error(tr(&"Invalid title provided!"))
		return false
		
	return true

func _emit_accepted():
	accepted.emit(title_line_edit.text, selected_video_info)
	hide()
func _on_ok_pressed():
	if not _validate():
		return
	if not selected_video_info or (not selected_video_info.has_audio_stream and not selected_video_info.has_video_stream):
		no_video_audio_dialog.dialog_text = "You're about to create a song without video or audio, are you sure about this?"
		no_video_audio_dialog.popup_centered()
		return
	elif not selected_video_info.has_audio_stream:
		no_video_audio_dialog.dialog_text = "You're about to create a song without audio, are you sure about this?"
		no_video_audio_dialog.popup_centered()
		return
	_emit_accepted()

func _on_select_video_button_pressed():
	var media_import_dialog := preload("res://tools/editor/media_import_dialog/MediaImportDialog.tscn").instantiate() as MediaImportDialog
	add_child(media_import_dialog)
	media_import_dialog.popup_centered()
	var result: MediaImportDialog.MediaImportDialogResult = await media_import_dialog.media_selected
	if (result.has_audio_stream or result.has_video_stream) and not result.canceled:
		selected_video_info = result
	else:
		selected_video_info = null
	media_import_dialog.queue_free()
	
func _ready() -> void:
	dialog_hide_on_ok = false
	
	title_line_edit.text_changed.connect(func(_new_text: String): _update_ok_button_disabled())
	confirmed.connect(_on_ok_pressed)
	_update_ok_button_disabled()
	no_video_audio_dialog.confirmed.connect(_emit_accepted)
	
	select_video_button.pressed.connect(_on_select_video_button_pressed)
