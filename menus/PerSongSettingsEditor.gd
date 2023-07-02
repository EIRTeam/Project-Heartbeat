extends Control

var current_song: HBSong: set = set_current_song
signal back

@onready var editor = get_node("PerSongSettingsOptionSection")

var ingame := false

var section_data = {
	"lag_compensation": {
		"name": tr("Latency compensation"),
		"description": tr("Delay applied to note timing, in miliseconds. Higher values means notes come later. Keep in mind the game already somewhat compensates for hardware delay (by, for example, already compensating for pulseaudio latency)."),
		"minimum": -30000,
		"maximum": 30000,
		"step": 1,
		"debounce_step": 9,
		"postfix": " ms",
		"default_value": 0
	},
	"volume": {
		"name": tr("Song volume"),
		"description": tr("Volume of the song, relative."),
		"minimum": 0.1,
		"maximum": 2.0,
		"step": 0.05,
		"percentage": true,
		"postfix": " %",
		"default_value": 0
	},
	"video_enabled": {
		"name": tr("Video enabled"),
		"description": tr("Enables or disables video for this song."),
		"default_value": true
	},
	"use_song_skin": {
		"name": tr("Use the song's recommended skin"),
		"description": tr("When enabled, makes the game use the skin chosen by the song's creator for this particular song, will download it if it is not installed already."),
		"default_value": true
	}
}

func set_current_song(val):
	current_song = val
	if not current_song.id in UserSettings.user_settings.per_song_settings:
		var song_settings = HBPerSongSettings.new()
		UserSettings.user_settings.per_song_settings[current_song.id] = song_settings
	editor.settings_source = UserSettings.user_settings.per_song_settings[current_song.id]
	var sec_data_dupl = section_data.duplicate(true)
	if ingame:
		sec_data_dupl.erase("video_enabled")
		sec_data_dupl.erase("use_song_skin")
	else:
		if not current_song.use_youtube_for_video or not current_song.youtube_url:
			sec_data_dupl.erase("video_enabled")
		if current_song.skin_ugc_id == 0:
			sec_data_dupl.erase("use_song_skin")
	editor.section_data = sec_data_dupl

func _ready():
	editor.connect("back", Callable(self, "_on_back"))
	editor.connect("back", Callable(editor, "hide"))
	editor.connect("changed", Callable(self, "_on_per_song_setting_changed"))
	editor.hide()
	
func _on_back():
	emit_signal("back")
	
func show_editor():
	editor.show()
	editor.grab_focus()
	
func hide_editor():
	editor.hide()
	
func _on_per_song_setting_changed(property_name, new_value):
	UserSettings.user_settings.per_song_settings[current_song.id].set(property_name, new_value)
	UserSettings.save_user_settings()

func toggle_input():
	editor.toggle_input()
