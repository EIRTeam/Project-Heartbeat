extends PanelContainer

@onready var download_audio_button: Button = %DownloadAudioButton
@onready var download_combined_button: Button = %DownloadCombinedButton
@onready var url_line_edit: LineEdit = %URLLineEdit
@onready var console_text: RichTextLabel = %ConsoleText
@onready var save_combined_file_dialog: FileDialog = %SaveCombinedFileDialog
@onready var save_audio_file_dialog: FileDialog = %SaveAudioFileDialog
@onready var success_dialog: AcceptDialog = %SuccessDialog
@onready var use_configured_command_line_args_checkbox: CheckBox = %UseConfiguredCommandLineArgumentsCheckbox

enum State {
	IDLING,
	DOWNLOADING_META,
	DOWNLOADING_MEDIA
}

var current_process: Process

func _start_download(url: String, save_to: String, download_video: bool):
	var yt_dlp_path := YoutubeDL.get_ytdl_executable() as String
	var shared_params := YoutubeDL.get_ytdl_shared_params(false, false) as Array
	
	var media_format := "bestvideo[vcodec!^=av01][height<=%d][fps<=%d]+bestaudio" % [1080, 60]

	if not download_video:
		media_format = "bestaudio"
	
	var video_params = shared_params + [
		"-P", save_to,
		"-f", media_format, "-o", save_to.get_basename() + ".%(ext)s", url]
	
	if use_configured_command_line_args_checkbox.pressed:
		video_params += YoutubeDL.get_ytdl_user_params()
	
	if not download_video:
		video_params.push_back("--extract-audio")
		video_params.push_back("--audio-format")
		video_params.push_back("vorbis")
	
	var json_params := video_params as Array
	
	current_process = PHNative.create_process(yt_dlp_path, json_params)
	console_text.clear()
	
func _process_upd():
	if not current_process:
		return
	var exit_status = current_process.get_exit_status()
	
	for i in range(current_process.get_available_stderr_lines()):
		console_text.push_color(Color.RED)
		console_text.append_text("ERROR: ")
		console_text.pop()
		console_text.append_text(current_process.get_stderr_line())
	for i in range(current_process.get_available_stdout_lines()):
		console_text.append_text(current_process.get_stdout_line())
	
	if exit_status == OK:
		success_dialog.popup_centered()
		current_process = null
func _ready() -> void:
	download_combined_button.pressed.connect(save_combined_file_dialog.popup_centered_ratio)
	download_audio_button.pressed.connect(save_audio_file_dialog.popup_centered_ratio)
	save_combined_file_dialog.file_selected.connect(
		func(save_to: String):
			_start_download(url_line_edit.text, save_to, true)
	)
	save_audio_file_dialog.file_selected.connect(
		func(save_to: String):
			_start_download(url_line_edit.text, save_to, false)
	)
	(get_viewport() as Window).content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	

func _process(delta: float) -> void:
	_process_upd()
