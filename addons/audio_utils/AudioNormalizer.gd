class_name HBAudioNormalizer

const TARGET_VOLUME = -14.0

var normalizer = null

func _init():
	var AudioNormalizer = preload("res://addons/audio_utils/AudioUtils.gdns") as NativeScript
	if not AudioNormalizer.library.get_current_library_path().empty():
		normalizer = AudioNormalizer.new()
		normalizer.set_target_loudness(TARGET_VOLUME)
static func get_offset_from_loudness(loudness: float) -> float:
	return TARGET_VOLUME - loudness

func set_target_ogg(stream: AudioStreamOGGVorbis):
	if normalizer:
		normalizer.set_target_ogg(stream.data)

func work_on_normalization() -> bool:
	if normalizer:
		return normalizer.work_on_normalization()
	else:
		return true
func get_normalization_result():
	if normalizer:
		return normalizer.get_normalization_result()
	else:
		return TARGET_VOLUME
