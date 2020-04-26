extends HBSerializable

class_name HBUserSettings

var visualizer_enabled = true
var visualizer_resolution = 32
var lag_compensation = 0
var note_size = 1.0
var icon_pack = "xbox"
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
var sort_mode = "title"
var leading_trail_enabled = true
var use_timing_arm = false
func _init():

	serializable_fields += ["visualizer_enabled", "left_arrow_override_enabled",
	"left_arrow_override_enabled", "right_arrow_override_enabled", "up_arrow_override_enabled", 
	"down_arrow_override_enabled", "visualizer_resolution", "lag_compensation", 
	"icon_pack", "romanized_titles_enabled", "show_latency", "enable_voice_fade",
	"note_size", "last_controller_guid", "input_map", "input_poll_more_than_once_per_frame",
	"fps_limit", "fullscreen", "desired_video_fps", "desired_video_resolution", "disable_video",
	"disable_ppd_video", "use_visualizer_with_video", "filter_mode", "sort_mode", "leading_trail_enabled",
	"use_timing_arm"]

static func deserialize(data: Dictionary):
	var result = .deserialize(data)
	result.input_map = {}
	if data.has("input_map"):
		for action_name in data.input_map:
			result.input_map[action_name] = []
			for action in data.input_map[action_name]:
				result.input_map[action_name].append(str2var(action))
	return result
	
func serialize():
	var base_data = .serialize()
	var new_input_map = {}
	for action_name in base_data.input_map:
		new_input_map[action_name] = []
		for action in base_data.input_map[action_name]:
			new_input_map[action_name].append(var2str(action))
	base_data.input_map = new_input_map
	return base_data
func get_serialized_type():
	return "UserSettings"
