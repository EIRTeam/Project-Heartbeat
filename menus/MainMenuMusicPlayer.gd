extends Panel

onready var player = get_node("AudioStreamPlayer")
onready var playback_max_label = get_node("MarginContainer/VBoxContainer/HBoxContainer2/PlaybackMaxLabel")
onready var playback_current_time_label = get_node("MarginContainer/VBoxContainer/HBoxContainer2/PlaybackCurrentTimeLabel")
onready var playback_progress_bar = get_node("MarginContainer/VBoxContainer/ProgressBar")
onready var song_title_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SongLabel")
onready var song_artist_label = get_node("MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ArtistLabel")
const FADE_OUT_VOLUME = -40
var target_volume = 0
var next_audio: AudioStreamOGGVorbis
var current_song: HBSong
var song_queued = false

func _ready():
	player.volume_db = FADE_OUT_VOLUME
	play_random_song()
func format_time(secs: float) -> String:
	return HBUtils.format_time(secs*1000.0, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS)
	
func play_random_song():
	randomize()
	var default_song = SongLoader.songs.values()[randi() % SongLoader.songs.keys().size()]
	play_song(default_song)
	
func _process(delta):
	player.volume_db = lerp(player.volume_db, target_volume, 4.0*delta)
	playback_current_time_label.text = format_time(player.get_playback_position())
	if player.stream:
		playback_progress_bar.value = player.get_playback_position() / player.stream.get_length()
	if abs(FADE_OUT_VOLUME) - abs(player.volume_db) < 3.0 and song_queued:
		target_volume = 0
		if next_audio:
			player.stream = next_audio
			player.play()
			player.seek(current_song.preview_start/1000.0)
			song_title_label.text = current_song.title
			if current_song.artist_alias != "":
				song_artist_label.text = current_song.artist_alias
			else:
				song_artist_label.text = current_song.artist
			playback_max_label.text = format_time(next_audio.get_length())
			song_queued = false
			
	if player.get_playback_position() >= player.stream.get_length():
		var curr = current_song
		# Ensure random song will always be different from current
		while curr == current_song:
			play_random_song()
		player.play()
func play_song(song: HBSong):
	if song == current_song:
		target_volume = 0
		return
	next_audio = HBUtils.load_ogg(song.get_song_audio_res_path())
	target_volume = FADE_OUT_VOLUME
	current_song = song
	song_queued = true
