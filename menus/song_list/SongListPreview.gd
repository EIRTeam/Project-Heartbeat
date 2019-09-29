extends Control

var load_queue = HBResourceQueue.new()

var loading_audio
var queued_audio
var current_song
func _ready():
	load_queue.start()

func fade_out():
	$AudioFadeTween.stop_all()
	$AudioFadeTween.interpolate_property($AudioStreamPlayer, "volume_db", $AudioStreamPlayer.volume_db, -40, 1, Tween.TRANS_SINE, Tween.EASE_IN, 0)
	$AudioFadeTween.start()
	$AudioFadeTween.connect("tween_all_completed", self, "_on_previous_song_fade_out", [], CONNECT_ONESHOT)

func fade_in():
	$AudioFadeTween.stop_all()
	$AudioFadeTween.interpolate_property($AudioStreamPlayer, "volume_db", -40, 0, 1, Tween.TRANS_SINE, Tween.EASE_IN, 0)
	$AudioFadeTween.start()

func _on_previous_song_fade_out():
	$AudioStreamPlayer.stream = null

func _process(delta):
	if loading_audio:
		if load_queue.is_ready(loading_audio):
			queued_audio = loading_audio
			loading_audio = null
	if queued_audio and not $AudioStreamPlayer.stream:
		$AudioStreamPlayer.stream = load_queue.get_resource(queued_audio)
		$AudioStreamPlayer.volume_db = -40
		fade_in()
		$AudioStreamPlayer.play()
		if current_song.data.has("preview_start"):
			$AudioStreamPlayer.seek(current_song.data.preview_start/1000.0)
		else:
			$AudioStreamPlayer.seek(0)
		queued_audio = null
			

func select_song(song: HBSong):
	if song == current_song:
		return
	current_song = song
	print("SEL")
	var bpm = "UNK"
	if song.data.has("bpm"):
		bpm = song.data.bpm
	$VBoxContainer/BPMLabel.text = "%s BPM" % bpm

	var song_meta = song.get_meta_string()

	$VBoxContainer/SongMetaLabel.text = PoolStringArray(song_meta).join('\n')

	load_queue.queue_resource(song.get_song_audio_res_path())
	
	if loading_audio:
		load_queue.cancel_resource(song.get_song_audio_res_path())
	
	loading_audio = song.get_song_audio_res_path()
	if $AudioStreamPlayer.stream:
		fade_out()
