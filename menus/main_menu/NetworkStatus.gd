extends Label

func _ready():
	update_label()
	HBBackend.connect("connection_status_changed", self, "update_label")

func update_label():
	if HBBackend.connected:
		add_color_override("font_color", Color.green)
		text = "HeartbeatNET: Connected"
	else:
		add_color_override("font_color", Color.red)
		text = "HeartbeatNET: Not connected"
