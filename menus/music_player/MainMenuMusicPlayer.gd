extends HBMenu

var current_song_length
onready var image_preview_texture_rect = get_node("MarginContainer/VBoxContainer/HBoxContainer/TextureRect")
var DEFAULT_IMAGE_TEXTURE = preload("res://graphics/no_preview_texture.png")
var background_song_assets_loader = HBBackgroundSongAssetsLoader.new()

func _init():

	background_song_assets_loader.connect("song_assets_loaded", self, "_on_song_assets_loaded")

func _on_song_assets_loaded(song, assets):
	var song_artist_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/ArtistLabel")
	var image_preview_texture_rect = get_node("MarginContainer/VBoxContainer/HBoxContainer/TextureRect")
	var circle_logo_texture_rect = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/CircleLogo")
	
	var image_path = song.get_song_preview_res_path()
	if image_path:
		image_preview_texture_rect.texture = assets.preview
	else:
		image_preview_texture_rect.texture = DEFAULT_IMAGE_TEXTURE
		
	var circle_logo_path = song.get_song_circle_logo_image_res_path()
	if circle_logo_path:
		song_artist_label.hide()
		circle_logo_texture_rect.show()
		circle_logo_texture_rect.texture = assets.circle_logo
	else:
		song_artist_label.show()
		circle_logo_texture_rect.hide()

func format_time(secs: float) -> String:
	return HBUtils.format_time(secs*1000.0, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS)
func set_song(song: HBSong, length: float):
	var playback_max_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/PlaybackMaxLabel")


	var song_title_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/SongLabel")
	var song_artist_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/ArtistLabel")
	current_song_length = length
	song_title_label.text = song.get_visible_title()
	if song.artist_alias != "":
		song_artist_label.text = song.artist_alias
	else:
		song_artist_label.text = song.artist
	playback_max_label.text = format_time(length)
	
	background_song_assets_loader.load_song_assets(song, ["preview", "circle_logo", "circle_image"])
func set_time(time: float):
	var playback_current_time_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/PlaybackCurrentTimeLabel")
	playback_current_time_label.text = format_time(time)
	var playback_progress_bar = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ProgressBar")
	playback_progress_bar.value = time / current_song_length
