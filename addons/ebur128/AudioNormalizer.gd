class_name HBAudioNormalizer

const TARGET_VOLUME = -14.0

var normalizer = null

func _init():
	var AudioNormalizer = preload("res://addons/ebur128/AudioNormalizer.gdns") as NativeScript
	if not AudioNormalizer.library.get_current_library_path().empty():
		normalizer = AudioNormalizer.new()
		normalizer.set_target_loudness(TARGET_VOLUME)
static func get_offset_from_loudness(loudness: float) -> float:
	return TARGET_VOLUME - loudness

func get_loudness_for_stream(stream: AudioStreamOGGVorbis) -> float:
	if normalizer:
		var loudness = normalizer.get_loudness_gobal(stream.data)
		return loudness
	else:
		return TARGET_VOLUME
