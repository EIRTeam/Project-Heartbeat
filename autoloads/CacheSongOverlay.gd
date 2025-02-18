extends Control

class_name HBCacheSongOverlay

@onready var download_confirm_popup = get_node("DownloadConfirmPopup")
@onready var error_prompt = get_node("ErrorPrompt")
@onready var accept_button_audio = get_node("%AcceptButtonAudio")
@onready var button_menu = $DownloadConfirmPopup.get_node("%ButtonContainer")
signal done
var current_song_downloading: HBSong
var current_variant = -1
enum DownloadPromptResult {
	CANCELLED,
	CACHING_STARTED
}
signal download_prompt_done(result: DownloadPromptResult)

func _ready():
	disable_mouse_filter()
	download_confirm_popup.connect("accept", Callable(self, "_on_download_prompt_accepted"))
	download_confirm_popup.connect("cancel", Callable(self, "emit_signal").bind("done"))
	error_prompt.connect("accept", Callable(self, "_on_error_prompt_accepted"))
	accept_button_audio.pressed.connect(self.disable_mouse_filter)
	download_confirm_popup.accept.connect(self.disable_mouse_filter)
	download_confirm_popup.cancel.connect(self.disable_mouse_filter)
	accept_button_audio.connect("pressed", Callable(download_confirm_popup, "disable_mouse_filter"))
	accept_button_audio.connect("pressed", Callable(self, "_on_download_prompt_accepted").bind(true))
	
func disable_mouse_filter():
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE
	
func show_download_prompt(song: HBSong, variant_n := -1, force_disable_audio_option = false):
	mouse_filter = MouseFilter.MOUSE_FILTER_STOP
	HBGame.fire_and_forget_sound(HBGame.menu_validate_sfx, HBGame.sfx_group)
	var variant = song.get_variant_data(variant_n)
	if YoutubeDL.is_already_downloading(song, variant_n):
		error_prompt.popup_centered_ratio(0.5)
		download_prompt_done.emit(DownloadPromptResult.CANCELLED)
		return
	current_song_downloading = song
	current_variant = variant_n
	var messages = {
		YoutubeDL.CACHE_STATUS.MISSING: tr("This song requires downloading video/audio files from YouTube, would you like to download them?", &"yt-dlp cache status missing"),
		YoutubeDL.CACHE_STATUS.VIDEO_MISSING: tr("The video for this song appears to be missing, would you like to download it?", &"yt-dlp video missing"),
		YoutubeDL.CACHE_STATUS.AUDIO_MISSING: tr("The audio for this song appears to be missing, would you like to download it?", &"yt-dlp audio missing")
	}
	download_confirm_popup.text = messages[variant.get_cache_status()]
	accept_button_audio.visible = !variant.audio_only and not force_disable_audio_option
	download_confirm_popup.popup_centered()
	button_menu.select_button(0)
	
func _on_error_prompt_accepted():
	disable_mouse_filter()
	emit_signal("done")
	
func _on_download_prompt_accepted(audio_only=false):
	if audio_only:
		if not UserSettings.user_settings.per_song_settings.has(current_song_downloading.id):
			UserSettings.user_settings.per_song_settings[current_song_downloading.id] = HBPerSongSettings.new()
		UserSettings.user_settings.per_song_settings[current_song_downloading.id].video_enabled = false
		UserSettings.save_user_settings()
	current_song_downloading.cache_data(current_variant)
	download_confirm_popup.hide()
	emit_signal("done")
	download_prompt_done.emit(DownloadPromptResult.CACHING_STARTED)
	disable_mouse_filter()
