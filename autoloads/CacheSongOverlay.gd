extends Control

onready var download_confirm_popup = get_node("DownloadConfirmPopup")
onready var downloading_prompt = get_node("DownloadingPrompt")
onready var error_prompt = get_node("ErrorPrompt")
signal video_downloaded(id, result, song)
signal user_rejected
signal download_error
var current_song_downloading: HBSong

func _ready():
	download_confirm_popup.connect("accept", self, "_on_download_prompt_accepted")
	download_confirm_popup.connect("cancel", self, "emit_signal", ["user_rejected"])
	error_prompt.connect("accept", self, "_on_error_prompt_accepted")
	YoutubeDL.connect("video_downloaded", self, "_on_video_downloaded")
func show_download_prompt(song: HBSong):
	current_song_downloading = song
	download_confirm_popup.popup_centered_ratio(0.5)
func _on_video_downloaded(id, results):
	if current_song_downloading:
		if YoutubeDL.get_video_id(current_song_downloading.youtube_url) == id:
			if current_song_downloading.use_youtube_for_audio:
				if not results.audio:
					show_error("Error downloading audio: " + results.audio_out)
					return
			if current_song_downloading.use_youtube_for_video:
				if not results.audio:
					show_error("Error downloading video: " + results.video_out)
					return
			downloading_prompt.hide()
			emit_signal("video_downloaded", id, results, current_song_downloading)
func show_error(error: String):
	error_prompt.text = error
	error_prompt.popup_centered_ratio(0.5)
func _on_error_prompt_accepted():
	emit_signal("download_error")
	
func _on_download_prompt_accepted():
	var result = YoutubeDL.download_video(current_song_downloading.youtube_url)
	if result == ERR_FILE_NOT_FOUND:
		show_error("Error downloading song, YouTube video not found")
	else:
		download_confirm_popup.hide()
		downloading_prompt.popup_centered_ratio(0.5)
