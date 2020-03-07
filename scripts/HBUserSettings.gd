extends HBSerializable

class_name HBUserSettings

var visualizer_enabled = true
var visualizer_resolution = 32
var lag_compensation = 0
var icon_pack = "xbox"
var romanized_titles_enabled = false
var left_arrow_override_enabled = false
var right_arrow_override_enabled = false
var up_arrow_override_enabled = false
var down_arrow_override_enabled = false
var show_latency = false
var enable_voice_fade = true
func _init():
	serializable_fields += ["visualizer_enabled", "left_arrow_override_enabled",
	"left_arrow_override_enabled", "right_arrow_override_enabled", "up_arrow_override_enabled", 
	"down_arrow_override_enabled", "visualizer_resolution", "lag_compensation", 
	"icon_pack", "romanized_titles_enabled", "show_latency", "enable_voice_fade"]

func get_serialized_type():
	return "UserSettings"
