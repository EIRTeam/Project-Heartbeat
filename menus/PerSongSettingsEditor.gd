extends Control

var current_song setget set_current_song
signal back

onready var editor = get_node("PerSongSettingsOptionSection")

var section_data = {
	"lag_compensation": {
		"name": tr("Latency compensation"),
		"description": "Delay applied to this chart's note timing, in miliseconds, higher values means notes come later.",
		"minimum": -300,
		"maximum": 300,
		"step": 1,
		"postfix": " ms",
		"default_value": 0
	},
	"volume": {
		"name": tr("Song volume"),
		"description": "Volume of the song, relative.",
		"minimum": 0.1,
		"maximum": 1.5,
		"step": 0.05,
		"percentage": true,
		"postfix": " %",
		"default_value": 0
	}
}

func set_current_song(val):
	current_song = val
	if not current_song.id in UserSettings.user_settings.per_song_settings:
		var song_settings = HBPerSongSettings.new()
		UserSettings.user_settings.per_song_settings[current_song.id] = song_settings
	editor.settings_source = UserSettings.user_settings.per_song_settings[current_song.id]
	editor.section_data = section_data

func _ready():
	editor.connect("back", self, "emit_signal", ["back"])
	editor.connect("back", editor, "hide")
	editor.connect("changed", self, "_on_per_song_setting_changed")
	editor.hide()
func show_editor():
	print("SHOW ED")
	editor.show()
	editor.grab_focus()
	
func _on_per_song_setting_changed(property_name, new_value):
	print("CHANGED!!")
	UserSettings.user_settings.per_song_settings[current_song.id].set(property_name, new_value)
	UserSettings.save_user_settings()
