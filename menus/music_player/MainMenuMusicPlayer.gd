extends HBMenu

var current_song_length
onready var image_preview_texture_rect = get_node("MarginContainer/VBoxContainer/HBoxContainer/TextureRect")
var DEFAULT_IMAGE_TEXTURE = preload("res://graphics/no_preview_texture.png")

func _ready():
	if UserSettings.user_settings.disable_menu_music:
		hide()

func format_time(secs: float) -> String:
	return HBUtils.format_time(secs*1000.0, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS)
func set_song(song: HBSong, length: float):
	var playback_max_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/PlaybackMaxLabel")


	var song_title_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SongTitle")
	current_song_length = length
	song_title_label.set_song(song)
	playback_max_label.text = format_time(length)
func set_time(time: float):
	var playback_current_time_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/PlaybackCurrentTimeLabel")
	playback_current_time_label.text = format_time(time)
	var playback_progress_bar = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/VBoxContainer/ProgressBar")
	playback_progress_bar.value = time / current_song_length
