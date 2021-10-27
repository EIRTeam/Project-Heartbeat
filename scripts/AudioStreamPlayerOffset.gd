extends AudioStreamPlayer

class_name AudioStreamPlayerOffset

var offset = 0.0

func seek_real(seek_pos: float):
	.seek(seek_pos)
func seek(seek_pos: float):
	.seek(seek_pos - offset)

func get_playback_position() -> float:
	return .get_playback_position() + offset
