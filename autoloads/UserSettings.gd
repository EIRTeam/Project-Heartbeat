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
				Log.log(self, "Error loading user settings, error code: " + result.error, Log.LogLevel.ERROR)

func save_user_settings():
	var file := File.new()
	if file.open(USER_SETTINGS_PATH, File.WRITE) == OK:
		file.store_string(JSON.print(user_settings.serialize(), "  "))
