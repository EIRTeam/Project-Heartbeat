extends VideoStreamPlayer

var offset = -10.0
var _song_clock: Callable

func set_song_clock(clock: Callable) -> void:
	_song_clock = clock

func _get_video_clock_time() -> float:
	return float(_song_clock.call()) + offset

func play():
	# Keep older engine builds usable; only the new FFmpeg playback supports
	# an external clock. Configure before play so embedded audio is never mixed.
	if has_method("get_stream_playback"):
		var playback = call("get_stream_playback")
		if playback and playback.has_method("set_playback_clock"):
			if _song_clock.is_valid() or playback.get_playback_clock().is_valid():
				super.stop()
				playback.set_playback_clock(_get_video_clock_time if _song_clock.is_valid() else Callable())
	super.play()

func _ready():
	add_to_group("song_backgrounds")
	_background_dim_changed(UserSettings.user_settings.background_dim)
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_while_paused = true

func _background_dim_changed(new_dim: float):
	modulate = Color.WHITE - (Color.BLACK * new_dim)

func set_stream_position(pos: float):
	super.set_stream_position(pos + offset)
			
	
