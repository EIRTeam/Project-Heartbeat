extends Control
@onready var main_label = get_node("Label")

@onready var info_label = get_node("Label2")

func _ready():
	update_label()
	HBBackend.connect("connection_status_changed", Callable(self, "update_label"))
	info_label.text = HBVersion.get_version_string(true).split("\n")[2]
	
func update_label():
	if HBBackend.connected:
		main_label.add_theme_color_override("font_color", Color.GREEN)
		main_label.text = "HeartbeatNET: Connected (%s)" % [HBBackend.service_env_name]
	else:
		main_label.add_theme_color_override("font_color", Color.RED)
		main_label.text = "HeartbeatNET: Not connected"
	
