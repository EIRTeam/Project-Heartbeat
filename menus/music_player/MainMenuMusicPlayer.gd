extends HBMenu

var current_song_length
onready var image_preview_texture_rect = get_node("MarginContainer/VBoxContainer/HBoxContainer/TextureRect")
const DEFAULT_IMAGE_TEXTURE = preload("res://graphics/no_preview.png")
func format_time(secs: float) -> String:
	return HBUtils.format_time(secs*1000.0, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS)
func set_song(song: HBSong, length: float):
	var playback_max_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/PlaybackMaxLabel")


	var song_title_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/SongLabel")
	var song_artist_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/ArtistLabel")
	var image_preview_texture_rect = get_node("MarginContainer/VBoxContainer/HBoxContainer/TextureRect")
	var circle_logo_texture_rect = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/CircleLogo")
	current_song_length = length
	song_title_label.text = song.get_visible_title()
	if song.artist_alias != "":
		song_artist_label.text = song.artist_alias
	else:
		song_artist_label.text = song.artist
	playback_max_label.text = format_time(length)
	var image_path = song.get_song_preview_res_path()
	if image_path:
		image_preview_texture_rect.texture = ImageTexture.new()
		var image = HBUtils.image_from_fs(image_path)
		image_preview_texture_rect.texture.create_from_image(image, Texture.FLAGS_DEFAULT)
	else:
		image_preview_texture_rect.texture = DEFAULT_IMAGE_TEXTURE
	var circle_logo_path = song.get_song_circle_logo_image_res_path()
	if circle_logo_path:
		song_artist_label.hide()
		circle_logo_texture_rect.show()
		var image = HBUtils.image_from_fs(circle_logo_path)
		var it = ImageTexture.new()
		it.create_from_image(image, Texture.FLAGS_DEFAULT)
		circle_logo_texture_rect.texture = it	
	else:
		song_artist_label.show()
		circle_logo_texture_rect.hide()
func set_time(time: float):
	var playback_current_time_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/PlaybackCurrentTimeLabel")
	playback_current_time_label.text = format_time(time)
	var playback_progress_bar = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ProgressBar")
	playback_progress_bar.value = time / current_song_length
