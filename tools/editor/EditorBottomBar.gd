extends HBoxContainer

func _ready():
	$HBoxContainer/VersionLabel.text = HBVersion.get_version_string().split("-", true, 1)[1].rsplit("-", true, 1)[0]

func _process(delta):
	$HBoxContainer/FPSLabel.text = "%d FPS" % [Engine.get_frames_per_second()]
