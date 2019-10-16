extends Control

var queued_audio
var current_song

onready var audio_fade_tween = get_node("SongListPreview/AudioFadeTween")
onready var audio_stream_player = get_node("SongListPreview/AudioStreamPlayer")

func fade_out():
	if audio_fade_tween.is_connected("tween_all_completed", self, "_on_previous_song_fade_out"):
		audio_fade_tween.disconnect("tween_all_completed", self, "_on_previous_song_fade_out")
#		return
	audio_fade_tween.stop_all()
	audio_fade_tween.interpolate_property(audio_stream_player, "volume_db", audio_stream_player.volume_db, -40, 1, Tween.TRANS_SINE, Tween.EASE_IN, 0)
	audio_fade_tween.start()
	audio_fade_tween.connect("tween_all_completed", self, "_on_previous_song_fade_out", [], CONNECT_ONESHOT)

func fade_in():
	audio_fade_tween.stop_all()
	audio_fade_tween.interpolate_property(audio_stream_player, "volume_db", -40, 0, 1, Tween.TRANS_SINE, Tween.EASE_IN, 0)
	audio_fade_tween.start()

func _on_previous_song_fade_out():
	if queued_audio:
		audio_stream_player.stream = queued_audio
		audio_stream_player.volume_db = -40
		fade_in()
		audio_stream_player.play()
		if current_song.preview_start:
			audio_stream_player.seek(current_song.preview_start/1000.0)
		else:
			audio_stream_player.seek(0)
		queued_audio = null
func _process(delta):
	pass


func select_song(song: HBSong):
	if song == current_song:
		return
	current_song = song
	print("SEL")
	var bpm = "UNK"
	bpm = song.bpm
	$SongListPreview/VBoxContainer/BPMLabel.text = "%s BPM" % bpm

	var song_meta = song.get_meta_string()

	$SongListPreview/VBoxContainer/SongMetaLabel.text = PoolStringArray(song_meta).join('\n')

	#load_queue.queue_resource(song.get_song_audio_res_path())
	
	#if loading_audio:
		#load_queue.cancel_resource(song.get_song_audio_res_path())
	
	var audio_path = song.get_song_audio_res_path()
	queued_audio = HBUtils.load_ogg(audio_path)
	if audio_fade_tween.is_active():
		queued_audio = HBUtils.load_ogg(audio_path)
	elif audio_stream_player.stream:
		fade_out()
	else:
		_on_previous_song_fade_out()
		
