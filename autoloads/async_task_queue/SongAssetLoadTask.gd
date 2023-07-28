class_name SongAssetLoadTask

enum ASSET_TYPES {
	PREVIEW,
	BACKGROUND,
	NOTE_USAGE,
	AUDIO,
	VOICE,
	CIRCLE_IMAGE,
	CIRCLE_LOGO,
	AUDIO_LOUDNESS,
	ASSET_TYPE_MAX
}

var assets_to_load: Array[ASSET_TYPES]
var flags: int

func _init(_assets_to_load: Array[ASSET_TYPES], _flags := 0):
	assets_to_load = _assets_to_load
	flags = _flags
