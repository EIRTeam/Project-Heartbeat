extends HBSerializable

class_name HBSongVariantData

var variant_name := ""
var variant_url := ""
var variant_audio := ""
var variant_video := ""
var variant_offset := 0
var has_audio_normalization := false
var variant_normalization := 0.0
var audio_only := false

func _init():
	serializable_fields += [
		"variant_name",
		"variant_url",
		"variant_audio",
		"variant_video",
		"variant_offset",
		"variant_normalization",
		"audio_only"
	]

func is_cached(song_use_video: bool):
	var use_video = song_use_video
	if audio_only:
		use_video = false
	return YoutubeDL.get_cache_status(variant_url, use_video, true) == YoutubeDL.CACHE_STATUS.OK

func get_serialized_type():
	return "HBSongVariantData"

func get_cache_status():
	return YoutubeDL.get_cache_status(variant_url, !audio_only, true)

func get_volume() -> float:
	return HBAudioNormalizer.get_offset_from_loudness(variant_normalization)
