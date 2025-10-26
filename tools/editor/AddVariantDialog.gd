extends ConfirmationDialog

class_name HBAddVariantDialog

enum AddVariantDialogError {
	OK,
	CANCELED
}

class AddVariantDialogResult:
	var error := AddVariantDialogError.OK
	var media_info: MediaImportDialog.MediaImportDialogResult
	var variant_name: String

var result: AddVariantDialogResult

@onready var variant_name_line_edit: LineEdit = get_node("%VariantNameLineEdit")
@onready var import_variant_media_button: Button = get_node("%ImportVariantMediaButton")

signal dialog_finished(result: AddVariantDialogResult)

func _on_about_to_popup():
	result = AddVariantDialogResult.new()
	get_ok_button().disabled = true

func _update_ok_button():
	var has_media := result.media_info and result.media_info.has_audio_stream
	var has_variant_name := not result.variant_name.is_empty()
	get_ok_button().disabled = not has_media or not has_variant_name

func _ready() -> void:
	about_to_popup.connect(_on_about_to_popup)
	
	variant_name_line_edit.text_changed.connect(
		func(new_text: String):
			result.variant_name = new_text.strip_edges()
			_update_ok_button()
	)
	
	canceled.connect(func():
		result.error = AddVariantDialogError.CANCELED
		dialog_finished.emit(result)
	)
	
	confirmed.connect(func():
		dialog_finished.emit(result)
	)
	
	import_variant_media_button.pressed.connect(func():
		var media_import_dialog := preload("res://tools/editor/media_import_dialog/MediaImportDialog.tscn").instantiate() as MediaImportDialog
		add_child(media_import_dialog)
		media_import_dialog.popup_centered()
		var import_dialog_result: MediaImportDialog.MediaImportDialogResult = await media_import_dialog.media_selected
		if import_dialog_result.has_audio_stream or import_dialog_result.has_video_stream:
			result.media_info = import_dialog_result
		media_import_dialog.queue_free()
		_update_ok_button()
	)
