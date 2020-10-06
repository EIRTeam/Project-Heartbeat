extends HBPlatformSettings

class_name HBPlatformSettingsSwitch

func _init():
	texture_mode = 0
	timing_mode = TIMING_MODE.NAIVE
	supports_rich_presence = true
	Engine.singlet

func user_dir_redirect(original_path: String) -> String:
	return original_path.replace("user://", "sdmc:/switch/Project Heartbeat/")
