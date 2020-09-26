extends Node

class_name HBBackgroundMusicPlayer

# Audio playback shit

const FADE_OUT_VOLUME = -70
var target_volume = 0
var next_audio: AudioStreamOGGVorbis
var next_voice: AudioStreamOGGVorbis
var current_song: HBSong
var song_queued = false
var waiting_for_song_assets = false
var player = AudioStreamPlayer.new()
var voice_player = AudioStreamPlayer.new()

var background_song_assets_loader = HBBackgroundSongAssetsLoader.new()

var _volume_offset = 0.0

signal stream_time_changed
signal song_started(song, assets)
signal assets_loaded(song, assets)
func _ready():
	player.volume_db = FADE_OUT_VOLUME
	player.bus = "Music"
	voice_player.volume_db = FADE_OUT_VOLUME
	voice_player.bus = "Voice"
	add_child(player)
	add_child(voice_player)
	background_song_assets_loader.connect("song_assets_loaded", self, "_on_song_assets_loaded")
	player.connect("finished", self, "_on_current_song_finished")
	
	if UserSettings.user_settings.disable_menu_music:
		set_process(false)

func _on_current_song_finished():
	play_song(current_song)

func play_random_song():
	# Ensure random song will always be different from current
	var song = current_song
	var possible_songs = []
	for possible_song in SongLoader.songs.values():
		if possible_song.has_audio() and not possible_song == current_song:
			possible_songs.append(possible_song)
	if possible_songs.size() > 0:
		randomize()
		song = possible_songs[randi() % possible_songs.size()]
	play_song(song, true)
	
func _process(delta):
	player.volume_db = lerp(player.volume_db, target_volume, 7.0*delta)
	voice_player.volume_db = lerp(player.volume_db, target_volume, 7.0*delta)


	if abs(FADE_OUT_VOLUME) - abs(player.volume_db) < 3.0 and song_queued and not waiting_for_song_assets:
		target_volume = current_song.get_volume_db() + _volume_offset
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
	if player.stream and not waiting_for_song_assets:
		emit_signal("stream_time_changed", player.get_playback_position())
			
func _on_song_assets_loaded(song: HBSong, assets):
	if "preview" in assets:
		emit_signal("assets_loaded", song, assets)
	else:
		waiting_for_song_assets = false
		_volume_offset = SongDataCache.get_song_volume_offset(song)
		if UserSettings.user_settings.disable_menu_music:
			emit_signal("song_started", song, assets)
		else:
			if song.has_audio():
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
					target_volume = song.get_volume_db() + _volume_offset
				else:
					next_audio = assets.audio
					if song.voice:
						next_voice = assets.voice
					else:
						next_voice = null
					song_queued = true
				current_song = song
	emit_signal("song_started", song, assets)
			
func play_song(song: HBSong, force = false):
	waiting_for_song_assets = true
	if song == current_song and not force:
		return
#	if player.stream:
#		# Sometimes, when doing this normally we would 
#		if player.stream.get_length() - player.get_playback_position() < 5.0:
#			player.stream = null
#			player.volume_db = FADE_OUT_VOLUME
		
	_volume_offset = 0.0
	target_volume = FADE_OUT_VOLUME
	background_song_assets_loader.load_song_assets(song, ["background", "preview", "background", "circle_logo"])
	if SongDataCache.is_song_audio_loudness_cached(song):
		background_song_assets_loader.load_song_assets(song, ["audio", "voice"])
	else:
		background_song_assets_loader.load_song_assets(song, ["audio", "audio_loudness", "voice"])
	
func get_song_length():
	return player.stream.get_length()
