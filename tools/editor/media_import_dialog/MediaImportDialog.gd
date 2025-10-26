extends AcceptDialog

class_name MediaImportDialog

class MediaImportDialogResult:
	var canceled := false
	var has_video_stream := false
	var selected_video_stream_format := FFmpegStreamInfo.VideoCodec.VIDEO_CODEC_UNKNOWN
	var has_audio_stream := false
	var selected_audio_stream_format := FFmpegStreamInfo.AudioCodec.AUDIO_CODEC_UNKNOWN
	var selected_video_path := ""

var result := MediaImportDialogResult.new()

@onready var status_label: RichTextLabel = %StatusLabel

signal media_selected(result: MediaImportDialogResult)

func _on_confirmed():
	media_selected.emit(result)

func _ready() -> void:
	confirmed.connect(_on_confirmed)
	canceled.connect(func():
		result.canceled = true
		_on_confirmed()
	)
	_update_status()
	exclusive = true
	transient = true

func _parse_video_stream_info(path: String):
	result.has_video_stream = false
	result.has_audio_stream = false
	result.selected_video_path = ""
	get_ok_button().disabled = true
	
	var info := FFmpegStreamInfo.new()
	if info.load(path) != OK:
		return
	
	result.has_video_stream = info.get_video_stream_count() > 0
	result.has_audio_stream = info.get_audio_stream_count() > 0
	
	result.selected_video_path = path
	
	if result.has_video_stream:
		result.selected_video_stream_format = info.get_video_stream_codec(0)
	
	if result.has_audio_stream:
		result.selected_audio_stream_format = info.get_audio_stream_codec(0)
	_update_status()
	
func _update_status():
	status_label.hide()
	get_ok_button().disabled = true
	if result.selected_video_path.is_empty():
		return
	status_label.show()
	status_label.clear()
	
	const ALLOWED_CODECS := [FFmpegStreamInfo.VideoCodec.VIDEO_CODEC_H264, FFmpegStreamInfo.VideoCodec.VIDEO_CODEC_H265, FFmpegStreamInfo.VideoCodec.VIDEO_CODEC_VP9]
	var is_importable := true
	if not result.selected_video_stream_format in ALLOWED_CODECS or not result.has_video_stream:
		is_importable = false
		status_label.push_color(Color.RED)
		status_label.append_text("Error:")
		status_label.pop()
		if not result.has_video_stream:
			status_label.append_text(" Selected file had no video stream")
		else:
			status_label.append_text(" Video doesn't use an allowed codec (h264, h265, VP9)")
		status_label.newline()
	if result.selected_audio_stream_format == FFmpegStreamInfo.AudioCodec.AUDIO_CODEC_UNKNOWN or not result.has_audio_stream:
		is_importable = false
		status_label.push_color(Color.RED)
		status_label.append_text("Error:")
		status_label.pop()
		if not result.has_audio_stream:
			status_label.append_text(" Selected file had no audio stream")
		else:
			status_label.append_text(" Video audio doesn't use an allowed codec (Vorbis, AAC)")
		status_label.newline()
	if is_importable:
		status_label.append_text("Ready to import!")
		if result.has_audio_stream:
			status_label.newline()
			status_label.append_text("Audio codec: %s" % [FFmpegStreamInfo.audio_codec_to_string(result.selected_audio_stream_format)])
		if result.has_video_stream:
			status_label.newline()
			status_label.append_text("Video codec: %s" % [FFmpegStreamInfo.video_codec_to_string(result.selected_video_stream_format)])
		get_ok_button().disabled = false
