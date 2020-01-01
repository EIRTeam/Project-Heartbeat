extends HBMenu

var current_song_length
func format_time(secs: float) -> String:
	return HBUtils.format_time(secs*1000.0, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS)
func set_song(song: HBSong, length: float):
	var playback_max_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/PlaybackMaxLabel")


	var song_title_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/SongLabel")
	var song_artist_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/ArtistLabel")
	current_song_length = length
	song_title_label.text = song.title
	if song.artist_alias != "":
		song_artist_label.text = song.artist_alias
	else:
		song_artist_label.text = song.artist
	playback_max_label.text = format_time(length)
	
func set_time(time: float):
	var playback_current_time_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/PlaybackCurrentTimeLabel")
	playback_current_time_label.text = format_time(time)
	var playback_progress_bar = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ProgressBar")
	playback_progress_bar.value = time / current_song_length
