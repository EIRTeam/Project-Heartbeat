extends Node

var user_settings: HBUserSettings = HBUserSettings.new()

const USER_SETTINGS_PATH = "user://user_settings.json"
const LOG_NAME = "UserSettings"

func _ready():
	load_user_settings()
	save_user_settings()
func load_user_settings():
	var file := File.new()
	if file.file_exists(USER_SETTINGS_PATH):
		if file.open(USER_SETTINGS_PATH, File.READ) == OK:
			var result = JSON.parse(file.get_as_text())
			if result.error == OK:
				user_settings = HBSerializable.deserialize(result.result)
				Log.log(self, "Successfully loaded user settings from " + USER_SETTINGS_PATH)
			else:
				Log.log(self, "Error loading user settings, on line %d: %s" % [result.error_line, result.error_string], Log.LogLevel.ERROR)

func save_user_settings():
	var file := File.new()
	if file.open(USER_SETTINGS_PATH, File.WRITE) == OK:
		var contents = JSON.print(user_settings.serialize(), "  ")
		file.store_string(contents)
		PlatformService.service_provider.write_remote_file_async(USER_SETTINGS_PATH.get_file(), contents.to_utf8())
