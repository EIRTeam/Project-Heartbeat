# User settings file class
extends HBSerializable

class_name HBUserSettings

var visualizer_enabled = true
var visualizer_resolution = 32
var lag_compensation = 0
var note_size = 1.0
var icon_pack = "playstation"
var romanized_titles_enabled = false
var left_arrow_override_enabled = false
var right_arrow_override_enabled = false
var up_arrow_override_enabled = false
var down_arrow_override_enabled = false
var show_latency = false
var enable_voice_fade = true
var last_controller_guid = ""
var input_poll_more_than_once_per_frame = true
var input_map = {}
var fps_limit: int = 0 # 0 is unlimited
var fullscreen = true
var desired_video_resolution = 1080
var desired_video_fps = 60
var show_visualizer_on_video = true
var disable_video = false
var disable_ppd_video = false
var use_visualizer_with_video = true
var filter_mode = "all"
var filter_mode__possibilities = [
	"all",
	"community",
	"ppd",
	"folders"
]
var sort_mode = "title"
var leading_trail_enabled = false
var use_timing_arm = true
var last_game_info: HBGameInfo = HBGameInfo.new()
var per_song_settings = {}
var analog_deadzone = 0.75
var enable_multi_hint = true
var disable_menu_music = false

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

var button_prompt_override__possibilities = [
	"default",
	"xbox",
	"playstation",
	"nintendo"
]

const DEFAULT_SOUNDS = {
	"note_hit": preload("res://sounds/sfx/tmb3.wav"),
	"slide_hit": preload("res://sounds/sfx/slide_note.wav"),
	"slide_chain_start": preload("res://sounds/sfx/slide_hold_start.wav"),
	"slide_chain_loop": preload("res://sounds/sfx/slide_hold_loop.wav"),
	"slide_chain_ok": preload("res://sounds/sfx/slide_hold_ok.wav"),
	"slide_chain_fail": preload("res://sounds/sfx/slide_hold_fail.wav"),
	"double_note_hit": preload("res://sounds/sfx/double_note.wav")
}

var custom_sounds = {}

func _init():

	serializable_fields += ["visualizer_enabled", "left_arrow_override_enabled",
	"left_arrow_override_enabled", "right_arrow_override_enabled", "up_arrow_override_enabled", 
	"down_arrow_override_enabled", "visualizer_resolution", "lag_compensation", 
	"icon_pack", "romanized_titles_enabled", "show_latency", "enable_voice_fade",
	"note_size", "last_controller_guid", "input_map", "input_poll_more_than_once_per_frame",
	"fps_limit", "fullscreen", "desired_video_fps", "desired_video_resolution", "disable_video",
	"disable_ppd_video", "use_visualizer_with_video", "filter_mode", "sort_mode", "leading_trail_enabled",
	"use_timing_arm", "last_game_info", "per_song_settings", "analog_deadzone",
	"enable_multi_hint", "master_volume", "music_volume", "sfx_volume", "content_path",
	"background_dim", "disable_menu_music", "load_all_notes_on_song_start", "vsync_enabled", "root_folder", 
	"custom_sounds", "last_folder_path", "button_prompt_override" ]
	
	merge_dict_fields += [
		"custom_sounds"
	]

	for sound_name in DEFAULT_SOUNDS:
		custom_sounds[sound_name] = "default"

static func deserialize(data: Dictionary):
	var result = .deserialize(data)
	result.input_map = {}
	if data.has("input_map"):
		for action_name in data.input_map:
			result.input_map[action_name] = []
			for action in data.input_map[action_name]:
				result.input_map[action_name].append(str2var(action))
	if data.has("last_game_info"):
		result.last_game_info = HBGameInfo.deserialize(data.last_game_info)
	var pss = {}
	if data.has("per_song_settings"):
		for song in data.per_song_settings:
			pss[song] = HBPerSongSettings.deserialize(data.per_song_settings[song])
	result.per_song_settings = pss
	
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
