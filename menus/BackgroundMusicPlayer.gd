extends Node

class_name HBBackgroundMusicPlayer

# Audio playback shit

const FADE_OUT_VOLUME = -70
var target_volume = 0
var next_audio: AudioStreamOGGVorbis
var next_voice: AudioStreamOGGVorbis
var current_song: HBSong
var song_queued = false

var player = AudioStreamPlayer.new()
var voice_player = AudioStreamPlayer.new()

var background_song_assets_loader = HBBackgroundSongAssetsLoader.new()

signal stream_time_changed
signal song_started(song, assets)

func _ready():
	player.volume_db = FADE_OUT_VOLUME
	player.bus = "Music"
	voice_player.volume_db = FADE_OUT_VOLUME
	voice_player.bus = "Voice"
	add_child(player)
	add_child(voice_player)
	background_song_assets_loader.connect("song_assets_loaded", self, "_on_song_assets_loaded")

func play_random_song():
	var song = HBSong.new()
	while song.audio == "":
		randomize()
		song = SongLoader.songs.values()[randi() % SongLoader.songs.keys().size()]
	play_song(song)
	
func _process(delta):
	player.volume_db = lerp(player.volume_db, target_volume, 4.0*delta)
	voice_player.volume_db = lerp(player.volume_db, target_volume, 4.0*delta)

	if abs(FADE_OUT_VOLUME) - abs(player.volume_db) < 3.0 and song_queued:
		target_volume = 0
		if next_audio:
			player.stream = next_audio
			player.play()
			player.seek(current_song.preview_start/1000.0)
			if next_voice:
				voice_player.stream = next_voice
				voice_player.play()
				voice_player.seek(current_song.preview_start/1000.0)
				song_queued = false
			else:
				voice_player.stream = null
	if player.stream:
		emit_signal("stream_time_changed", player.get_playback_position())
		if player.get_playback_position() >= player.stream.get_length():
			var curr = current_song
			# Ensure random song will always be different from current
			if SongLoader.songs.size() > 1:
				while curr == current_song:
					play_random_song()
			else:
				play_random_song()
			
func _on_song_assets_loaded(song, assets):
	if song.audio != "":
		if not current_song:
			player.stream = assets.audio
			player.play()
			player.seek(song.preview_start/1000.0)
			if song.voice:
				voice_player.stream = assets.voice
				voice_player.play()
				voice_player.seek(song.preview_start/1000.0)
			player.volume_db = FADE_OUT_VOLUME
			voice_player.volume_db = FADE_OUT_VOLUME
			target_volume = 0
		else:
			next_audio = assets.audio
			if song.voice:
				next_voice = assets.voice
			else:
				next_voice = null
			target_volume = FADE_OUT_VOLUME
			song_queued = true
		current_song = song
		emit_signal("song_started", song, assets)
			
func play_song(song: HBSong):
	if song == current_song:
		return
	background_song_assets_loader.load_song_assets(song, ["audio", "voice", "background", "preview", "background", "circle_logo"])


		
func get_song_length():
	return player.stream.get_length()
