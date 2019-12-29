extends CanvasLayer

var _seconds_since_startup = 0.0
var _frames_drawn_offset = 0.0
var _max_fps = 0.0
var _min_fps = 10000000

var enable_autoplay = false setget set_autoplay

func set_autoplay(value):
	enable_autoplay = value

func _ready():
	$Panel.hide()
	$Panel/MarginContainer/VBoxContainer/AutoplayCheckbox.connect("toggled", self, "set_autoplay")
	$"Version Label".text = HBVersion.get_version_string()
func _input(event):
	if event.is_action_pressed("toggle_diagnostics"):
		$Panel.visible = !$Panel.visible
func _process(delta):
	_seconds_since_startup += delta
	$Panel/MarginContainer/VBoxContainer/FrameRateLabel.text = "FPS: %f" % Engine.get_frames_per_second()
	if Engine.get_frames_drawn() - _frames_drawn_offset > 0:
		$Panel/MarginContainer/VBoxContainer/AVGFrameRateLabel.text = "Avg: %f" % (float(Engine.get_frames_drawn() - _frames_drawn_offset) / (_seconds_since_startup))
	if Engine.get_frames_per_second() > _max_fps:
		_max_fps = Engine.get_frames_per_second()
		$Panel/MarginContainer/VBoxContainer/MaxFrameRateLabel.text = "Max: %f" % _max_fps
	if Engine.get_frames_per_second() < _min_fps and Engine.get_frames_per_second() > 10:
		_min_fps = Engine.get_frames_per_second()
		$Panel/MarginContainer/VBoxContainer/MinFrameRateLabel.text = "Min: %f" %_min_fps

func _on_ResetButton_pressed():
	_seconds_since_startup = 0.0
	_frames_drawn_offset = Engine.get_frames_drawn()
	_min_fps = 10000000
	_max_fps = 0.0

func hide_WIP_label():
	$"WIP Label".hide()
func show_WIP_label():
	$"WIP Label".show()
