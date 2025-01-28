extends ConfirmationDialog

class_name HBCreateSongDialog

@onready var no_workshop_checkbox: CheckBox = get_node("%NoWorkshopCheckbox")
@onready var youtube_url_line_edit: LineEdit = get_node("%YoutubeURL")
@onready var title_line_edit: LineEdit = get_node("%Title")
@onready var error_dialog: AcceptDialog = get_node("%ErrorDialog")

signal accepted(song_title: String, use_youtube_url: bool, youtube_url: String)

func _update_ok_button_disabled():
	var has_title := not title_line_edit.text.is_empty()
	var has_youtube_url := not youtube_url_line_edit.text.is_empty()
	var has_check_no_workshop := no_workshop_checkbox.button_pressed
	get_ok_button().disabled = not has_title or (not has_youtube_url and not has_check_no_workshop)

func _show_error(error: String):
	error_dialog.dialog_text = error
	error_dialog.popup_centered()

func _validate() -> bool:
	var title_validated := HBUtils.get_valid_filename(title_line_edit.text)
	if title_validated.is_empty():
		_show_error(tr(&"Invalid title provided!"))
		return false
		
	if not no_workshop_checkbox.button_pressed and not YoutubeDL.validate_video_url(youtube_url_line_edit.text):
		_show_error(&"Invalid YouTube URL provided!")
		return false
	return true

func _on_ok_pressed():
	if not _validate():
		return
	accepted.emit(title_line_edit.text, not no_workshop_checkbox.button_pressed, youtube_url_line_edit.text)
	hide()

func _ready() -> void:
	dialog_hide_on_ok = false
	no_workshop_checkbox.pressed.connect(_update_ok_button_disabled)
	title_line_edit.text_changed.connect(func(_new_text: String): _update_ok_button_disabled())
	youtube_url_line_edit.text_changed.connect(func(_new_text: String): _update_ok_button_disabled())
	confirmed.connect(_on_ok_pressed)
	_update_ok_button_disabled()
