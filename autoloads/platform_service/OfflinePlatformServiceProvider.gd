extends PlatformServiceProvider

func init_platform() -> int:
	if OS.has_environment("USERNAME"):
		friendly_username = OS.get_environment("USERNAME")
	user_id = friendly_username
	return OK

