extends Control

onready var download_confirm_popup = get_node("DownloadConfirmPopup")
onready var downloading_prompt = get_node("DownloadingPrompt")
onready var error_prompt = get_node("ErrorPrompt")
signal done
var current_song_downloading: HBSong

func _ready():
	download_confirm_popup.connect("accept", self, "_on_download_prompt_accepted")
	download_confirm_popup.connect("cancel", self, "emit_signal", ["user_rejected"])

func show_download_prompt(song: HBSong):
	current_song_downloading = song
	var messages = {
		YoutubeDL.CACHE_STATUS.MISSING: "This song requires downloading video/audio files from YouTube, would you like to download them?",
		YoutubeDL.CACHE_STATUS.VIDEO_MISSING: "The video for this song appears to be missing, would you like to download it?",
		YoutubeDL.CACHE_STATUS.AUDIO_MISSING: "The audio for this song appears to be missing, would you like to download it?"
	}
	download_confirm_popup.text = messages[song.get_cache_status()]
	download_confirm_popup.popup_centered_ratio(0.5)
func _on_error_prompt_accepted():
	emit_signal("done")
	
func _on_download_prompt_accepted():
	var result = current_song_downloading.cache_data()
	download_confirm_popup.hide()
	emit_signal("done")
