class_name HBPlatformSettings

enum TIMING_MODE {
	PRECISE,
	NAIVE
}

var timing_mode = TIMING_MODE.PRECISE
var supports_rich_presence = true

func user_dir_redirect(original_path: String) -> String:
	return original_path
