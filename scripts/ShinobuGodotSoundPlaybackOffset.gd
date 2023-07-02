extends Node

class_name ShinobuGodotSoundPlaybackOffset

var playback: ShinobuSoundPlayer
var volume := 0.0: get = get_volume, set = set_volume
var pitch_scale : get = get_pitch_scale, set = set_pitch_scale

func set_pitch_scale(val):
	playback.pitch_scale = val
func get_pitch_scale():
	return playback.pitch_scale

func set_volume(val):
	playback.volume = val
func get_volume():
	return playback.volume

func get_length_msec():
	return playback.get_length_msec()

var offset = 0.0

func _init(_playback: ShinobuSoundPlayer):
	playback = _playback
	add_child(playback)

func seek_real(seek_pos: int):
	playback.seek(seek_pos)
func seek(seek_pos: int):
	playback.seek(seek_pos - offset)

func is_playing() -> bool:
	return playback.is_playing()
	
func is_at_stream_end() -> bool:
	return playback.is_at_stream_end()

func get_playback_position_msec() -> int:
	return playback.get_playback_position_msec() + offset

func get_playback_position_nsec() -> int:
	return playback.get_playback_position_nsec() + offset * 1000_000

func stop():
	playback.stop()
func start():
	playback.start()
func schedule_start_time(start: int):
	playback.schedule_start_time(start)
func schedule_stop_time(stop: int):
	playback.schedule_stop_time(stop)

func get_channel_count():
	return playback.get_channel_count()
	
func connect_sound_to_effect(effect):
	playback.connect_sound_to_effect(effect)
