extends Control
onready var main_label = get_node("Label")

onready var info_label = get_node("Label2")

func _ready():
	update_label()
	HBBackend.connect("connection_status_changed", self, "update_label")
	var is_ppd_ext_enabled = HBGame.has_mp4_support
	info_label.text = HBVersion.get_version_string(true).split("\n")[2]
	
func update_label():
	if HBBackend.connected:
		main_label.add_color_override("font_color", Color.green)
		main_label.text = "HeartbeatNET: Connected (%s)" % [HBBackend.service_env_name]
	else:
		main_label.add_color_override("font_color", Color.red)
		main_label.text = "HeartbeatNET: Not connected"
	
