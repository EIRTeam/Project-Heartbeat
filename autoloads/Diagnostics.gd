extends Panel

var _seconds_since_startup = 0.0
var _frames_drawn_offset = 0.0
var _max_fps = 0.0
var _min_fps = 10000000
func _ready():
	hide()
	if not OS.is_debug_build():
		set_process(false)
	
func _input(event):
	if event.is_action_pressed("toggle_diagnostics"):
		visible = !visible
func _process(delta):
	_seconds_since_startup += delta
	$MarginContainer/VBoxContainer/FrameRateLabel.text = "FPS: %f" % Engine.get_frames_per_second()
	if Engine.get_frames_drawn() - _frames_drawn_offset > 0:
		$MarginContainer/VBoxContainer/AVGFrameRateLabel.text = "Avg: %f" % (float(Engine.get_frames_drawn() - _frames_drawn_offset) / (_seconds_since_startup))
	if Engine.get_frames_per_second() > _max_fps:
		_max_fps = Engine.get_frames_per_second()
		$MarginContainer/VBoxContainer/MaxFrameRateLabel.text = "Max: %f" % _max_fps
	if Engine.get_frames_per_second() < _min_fps and Engine.get_frames_per_second() > 10:
		_min_fps = Engine.get_frames_per_second()
		$MarginContainer/VBoxContainer/MinFrameRateLabel.text = "Min: %f" %_min_fps


func _on_ResetButton_pressed():
	_seconds_since_startup = 0.0
	_frames_drawn_offset = Engine.get_frames_drawn()
	_min_fps = 10000000
	_max_fps = 0.0
