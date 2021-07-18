# User settings file class
extends HBSerializable

class_name HBUserSettings

var visualizer_enabled = true
var visualizer_resolution = 32
var lag_compensation = 0
var note_size = 1.0
var icon_pack = "playstation"
var resource_pack = "playstation"
# User can select a resource pack to get icons from instead of the selected one
var note_icon_override = "__resource_pack"
var romanized_titles_enabled = false
var left_arrow_override_enabled = false
var right_arrow_override_enabled = false
var up_arrow_override_enabled = false
var down_arrow_override_enabled = false
var show_latency = true
var enable_voice_fade = true
var controller_guid = ""
var input_poll_more_than_once_per_frame = true
var input_map = {}
var fps_limit: int = 180 # 0 is unlimited
var display_mode = "borderless"
var display_mode__possibilities = [
	"borderless",
	"fullscreen",
	"windowed"
]
var display := 0
var desired_video_resolution = 1080
var desired_video_fps = 60
var show_visualizer_on_video = true
var disable_video = false
var disable_ppd_video = false
var use_visualizer_with_video = true
var filter_mode = "all"
var filter_mode__possibilities = [
	"all",
	"official",
	"local",
	"workshop",
	"ppd",
	"folders",
	"dsc"
]
var sort_mode = "title"
var leading_trail_enabled = false
var use_timing_arm = true
var last_game_info: HBGameInfo = HBGameInfo.new()
var per_song_settings = {}
var analog_deadzone = 0.75
var enable_multi_hint = true
var disable_menu_music = false
var use_explicit_rating = true

var master_volume = 1.0
var music_volume = 1.0
var sfx_volume = 1.0

var content_path = "user://"

var background_dim = 0.0

var load_all_notes_on_song_start = true

var vsync_enabled = false

var root_folder = HBFolder.new()

var last_folder_path = []

var button_prompt_override = "default"
var vibration_enabled = true

var button_prompt_override__possibilities = [
	"default",
	"xbox",
	"playstation",
	"nintendo"
]

var lyrics_enabled: bool = true

var lyrics_position = "top_center"
var lyrics_position__possibilities = [
	"top_left",
	"top_center",
	"top_right",
	"bottom_left",
	"bottom_center",
	"bottom_right",
]

var lyrics_color = "orange"

var lyrics_color__possibilities = [
	"orange",
	"purple",
	"blue",
	"red",
	"green",
]

const DEFAULT_SOUNDS = {
	"note_hit": preload("res://sounds/sfx/tmb3.wav"),
	"slide_hit": preload("res://sounds/sfx/slide_note.wav"),
	"slide_empty": preload("res://sounds/sfx/360835__tec-studio__fantasy-sfx-006.wav"),
	"heart_hit": preload("res://sounds/sfx/slide_note.wav"),
	"slide_chain_start": preload("res://sounds/sfx/slide_hold_start.wav"),
	"slide_chain_loop": preload("res://sounds/sfx/slide_hold_loop.wav"),
	"slide_chain_ok": preload("res://sounds/sfx/slide_hold_ok.wav"),
	"slide_chain_fail": preload("res://sounds/sfx/slide_hold_fail.wav"),
	"double_note_hit": preload("res://sounds/sfx/double_note.wav")
}

var custom_sounds = {}
var custom_sound_volumes = {}

var locale = "auto-detect"
var locale__possibilities = [
	"auto-detect",
	"en",
	"es",
	"ca"
]

enum TIMING_METHOD {
	SYSTEM_CLOCK,
	SOUND_HARDWARE_CLOCK,
	SOUND_HARDWARE_CLOCK_FALLBACK
}

var timing_method = TIMING_METHOD.SYSTEM_CLOCK

var workshop_download_audio_only = false

var multi_laser_opacity = 1.0

var show_note_types_before_playing = true

enum COLORBLIND_COLOR_REMAP {
	NONE,
	GBR,
	BRG,
	BGR
}

var color_remap: int = COLORBLIND_COLOR_REMAP.NONE

var ppd_songs_directory: String = ""
var hide_ppd_ex_songs: bool = false

var editor_first_time_message_acknowledged: bool = false

var show_console: bool = false

var use_direct_joystick_access: bool = false

func _init():

	serializable_fields += ["visualizer_enabled", "left_arrow_override_enabled",
	"left_arrow_override_enabled", "right_arrow_override_enabled", "up_arrow_override_enabled", 
	"down_arrow_override_enabled", "visualizer_resolution", "lag_compensation", 
	"icon_pack", "resource_pack", "note_icon_override", "romanized_titles_enabled", "show_latency", "enable_voice_fade",
	"note_size", "controller_guid", "input_map", "input_poll_more_than_once_per_frame",
	"fps_limit", "display_mode", "display", "desired_video_fps", "desired_video_resolution", "disable_video",
	"disable_ppd_video", "use_visualizer_with_video", "filter_mode", "sort_mode", "leading_trail_enabled",
	"use_timing_arm", "last_game_info", "per_song_settings", "analog_deadzone",
	"enable_multi_hint", "master_volume", "music_volume", "sfx_volume", "content_path",
	"background_dim", "disable_menu_music", "load_all_notes_on_song_start", "vsync_enabled", "root_folder", 
	"custom_sounds", "custom_sound_volumes", "last_folder_path", "button_prompt_override", "enable_vibration", "lyrics_enabled", "lyrics_position",
	"lyrics_color", "locale", "timing_method", "workshop_download_audio_only", "multi_laser_opacity",
	"show_note_types_before_playing", "color_remap", "ppd_songs_directory", "hide_ppd_ex_songs", "editor_first_time_message_acknowledged",
	"show_console", "use_direct_joystick_access", "use_explicit_rating"]
	
	merge_dict_fields += [
		"custom_sounds",
		"custom_sound_volumes"
	]

	for sound_name in DEFAULT_SOUNDS:
		custom_sounds[sound_name] = "default"
	for sound_name in DEFAULT_SOUNDS:
		custom_sound_volumes[sound_name] = 1.0

func get_lyrics_color() -> Color:
	var color = Color("#ffaa00")
	match lyrics_color:
		"purple":
			color = Color("#6F14FF")
		"blue":
			color = Color("#00a2ff")
		"red":
			color = Color("#ff0000")
		"green":
			color = Color("6EFF1F")
	return color

func get_lyrics_halign():
	var alignment = Label.ALIGN_LEFT
	if lyrics_position.ends_with("center"):
		alignment = Label.ALIGN_CENTER
	if lyrics_position.ends_with("right"):
		alignment = Label.ALIGN_RIGHT
	return alignment
	
func get_lyrics_valign():
	var alignment = Label.VALIGN_TOP
	if lyrics_position.begins_with("bottom"):
		alignment = Label.VALIGN_BOTTOM
	return alignment

static func deserialize(data: Dictionary):
	var result = .deserialize(data)
	result.input_map = {}
	if data.has("input_map"):
		for action_name in data.input_map:
			result.input_map[action_name] = []
			for action in data.input_map[action_name]:
				result.input_map[action_name].append(str2var(action))
#	var pss = {}
#	if data.has("per_song_settings"):
#		for song in data.per_song_settings:
#			pss[song] = HBPerSongSettings.deserialize(data.per_song_settings[song])
#	result.per_song_settings = pss
	
	result.root_folder.folder_name = "Root"
	
	# Legacy favorite migration
	if data.has("favorite_songs"):
		if data.favorite_songs.size() > 0:
			var favorites_folder = HBFolder.new()
			favorites_folder.folder_name = "Legacy Favourites"
			favorites_folder.songs = data.favorite_songs
			result.root_folder.subfolders.append(favorites_folder)
	
	return result
	
func serialize(serialize_defaults=false):
	var base_data = .serialize()
	var new_input_map = {}
	for action_name in base_data.input_map:
		new_input_map[action_name] = []
		for action in base_data.input_map[action_name]:
			new_input_map[action_name].append(var2str(action))
	base_data.input_map = new_input_map
	
	var pss = {}
	
	for song in per_song_settings:
		pss[song] = per_song_settings[song].serialize()
	base_data.per_song_settings = pss

	var sounds = {}

	for sound_name in custom_sounds:
		if custom_sounds[sound_name] != "default":
			sounds[sound_name] = custom_sounds[sound_name]

	base_data["custom_sounds"] = sounds

	return base_data
func get_serialized_type():
	return "UserSettings"

func get_sound_volume_db(sound_name: String) -> float:
	return linear2db(UserSettings.user_settings.custom_sound_volumes[sound_name])
