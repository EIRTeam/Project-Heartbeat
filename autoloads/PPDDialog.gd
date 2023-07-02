extends Window

@onready var use_youtube_button = get_node("MarginContainer/VBoxContainer/HBoxContainer/UseYouTube")
@onready var file_dialog = get_node("../PPDFileDialog")
@onready var youtube_url_line_edit = get_node("MarginContainer/VBoxContainer/HBoxContainer/LineEdit")
@onready var error_dialog = get_node("AcceptDialog")
signal youtube_url_selected(url)

signal file_selected(file_path)
signal file_selector_hidden
func _ready():
	use_youtube_button.connect("pressed", Callable(self, "_on_use_youtube_button_pressed"))
	file_dialog.connect("file_selected", Callable(self, "_on_file_selected"))
	file_dialog.connect("visibility_changed", Callable(self, "_on_file_selector_visbility_changed"))
	connect("about_to_popup", Callable(self, "_on_about_to_show"))
	
func _on_file_selector_visbility_changed():
	if not file_dialog.visible:
		emit_signal("file_selector_hidden")
	
func _on_use_youtube_button_pressed():
	if YoutubeDL.get_video_id(youtube_url_line_edit.text):
		emit_signal("youtube_url_selected", youtube_url_line_edit.text)
		hide()
	else:
		error_dialog.dialog_text = "Invalid URL, ensure you are using a YouTube URL and that it is valid."
		error_dialog.popup_centered()
func _on_file_selected(file):
	var err = HBUtils.verify_ogg(file)
	if err == HBUtils.OGG_ERRORS.OK:
		emit_signal("file_selected", file)
		hide()
	else:
		if err == HBUtils.OGG_ERRORS.NOT_AN_OGG:
			error_dialog.dialog_text = "The file you selected is not an OGG file."
		else:
			error_dialog.dialog_text = "The file you selected is an OGG file, but it doesn't use the vorbis codec."
		error_dialog.popup_centered()
	
	UserSettings.user_settings.last_audio_dir = file.get_base_dir()
	UserSettings.save_user_settings()
	
	

func ask_for_file(youtube_only=false):
	file_dialog.mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.ogg ; OGG"]
	file_dialog.set_current_dir(UserSettings.user_settings.last_audio_dir)
	$MarginContainer/VBoxContainer/Button.disabled = youtube_only
	popup_centered()
func _on_about_to_show():
	youtube_url_line_edit.text = ""
