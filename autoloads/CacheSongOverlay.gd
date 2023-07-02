extends Control

@onready var download_confirm_popup = get_node("DownloadConfirmPopup")
@onready var downloading_prompt = get_node("DownloadingPrompt")
@onready var error_prompt = get_node("ErrorPrompt")
@onready var accept_button_audio = get_node("DownloadConfirmPopup/Panel/HBoxContainer/AcceptButtonAudio")
@onready var button_menu = get_node("DownloadConfirmPopup/Panel/HBoxContainer")
signal done
var current_song_downloading: HBSong
var current_variant = -1

func _ready():
	download_confirm_popup.connect("accept", Callable(self, "_on_download_prompt_accepted"))
	download_confirm_popup.connect("cancel", Callable(self, "emit_signal").bind("done"))
	error_prompt.connect("accept", Callable(self, "_on_error_prompt_accepted"))
	accept_button_audio.connect("pressed", Callable(download_confirm_popup, "hide"))
	accept_button_audio.connect("pressed", Callable(self, "_on_download_prompt_accepted").bind(true))
func show_download_prompt(song: HBSong, variant_n := -1, force_disable_audio_option = false):
	HBGame.fire_and_forget_sound(HBGame.menu_validate_sfx, HBGame.sfx_group)
	var variant = song.get_variant_data(variant_n)
	if YoutubeDL.is_already_downloading(song, variant_n):
		error_prompt.popup_centered_ratio(0.5)
		return
	current_song_downloading = song
	current_variant = variant_n
	var messages = {
		YoutubeDL.CACHE_STATUS.MISSING: "This song requires downloading video/audio files from YouTube, would you like to download them?",
		YoutubeDL.CACHE_STATUS.VIDEO_MISSING: "The video for this song appears to be missing, would you like to download it?",
		YoutubeDL.CACHE_STATUS.AUDIO_MISSING: "The audio for this song appears to be missing, would you like to download it?"
	}
	download_confirm_popup.text = messages[variant.get_cache_status()]
	accept_button_audio.visible = !variant.audio_only and not force_disable_audio_option
	download_confirm_popup.popup_centered_ratio(0.5)
	button_menu.select_button(0)
	
func _on_error_prompt_accepted():
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
