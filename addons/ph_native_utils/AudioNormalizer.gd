@uid("uid://uyf44os0u460") # Generated automatically, do not modify.
class_name HBAudioNormalizer

const TARGET_VOLUME = -14.0

static func get_offset_from_loudness(loudness: float) -> float:
	return TARGET_VOLUME - loudness

