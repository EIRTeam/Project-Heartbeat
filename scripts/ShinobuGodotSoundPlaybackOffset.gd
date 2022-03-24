class_name ShinobuGodotSoundPlaybackOffset

var playback: ShinobuGodotSoundPlayback
var volume := 0.0 setget set_volume, get_volume

func set_volume(val):
	playback.volume = val
func get_volume():
	return playback.volume

func get_length_msec():
	return playback.get_length_msec()

var offset = 0.0

func _init(_playback: ShinobuGodotSoundPlayback):
	playback = _playback

func seek_real(seek_pos: int):
	playback.seek(seek_pos)
func seek(seek_pos: int):
	prints("SEEK", seek_pos, offset)
	playback.seek(seek_pos - offset)

func is_playing() -> bool:
	return playback.is_playing()

func get_playback_position_msec() -> int:
	return playback.get_playback_position_msec() + offset

func stop():
	playback.stop()
func start():
	playback.start()
func schedule_start_time(start: int):
	playback.schedule_start_time(start)
func schedule_stop_time(stop: int):
	playback.schedule_stop_time(stop)
