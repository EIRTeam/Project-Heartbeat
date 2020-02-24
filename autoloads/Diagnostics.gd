extends CanvasLayer

var _seconds_since_startup = 0.0
var _frames_drawn_offset = 0.0
var _max_fps = 0.0
var _min_fps = 10000000

var enable_autoplay = false setget set_autoplay
func set_autoplay(value):
	enable_autoplay = value

onready var frame_rate_label = get_node("WindowDialog/TabContainer/Game/VBoxContainer/HBoxContainer/VBoxContainer/FrameRateLabel")
onready var average_frame_rate_label = get_node("WindowDialog/TabContainer/Game/VBoxContainer/HBoxContainer/VBoxContainer/AVGFrameRateLabel")
onready var min_frame_rate_label = get_node("WindowDialog/TabContainer/Game/VBoxContainer/HBoxContainer/VBoxContainer/MinFrameRateLabel")
onready var max_frame_rate_label = get_node("WindowDialog/TabContainer/Game/VBoxContainer/HBoxContainer/VBoxContainer/MaxFrameRateLabel")
onready var autoplay_checkbox = get_node("WindowDialog/TabContainer/Game/VBoxContainer/AutoplayCheckbox")
func _ready():
	autoplay_checkbox.connect("toggled", self, "set_autoplay")
	
func _input(event):
	if event.is_action_pressed("toggle_diagnostics"):
		$WindowDialog.popup_centered_ratio(0.75)
	if event.is_action_pressed("take_screenshot"):
		var img = get_viewport().get_texture().get_data()
		# Flip it on the y-axis (because it's flipped).
		img.flip_y()
		img.save_png("user://debug_screenshot/%d.png" % [OS.get_unix_time()])
func _process(delta):
	_seconds_since_startup += delta
	frame_rate_label.text = "FPS: %f" % Engine.get_frames_per_second()
	if Engine.get_frames_drawn() - _frames_drawn_offset > 0:
		average_frame_rate_label.text = "Avg: %f" % (float(Engine.get_frames_drawn() - _frames_drawn_offset) / (_seconds_since_startup))
	if Engine.get_frames_per_second() > _max_fps:
		_max_fps = Engine.get_frames_per_second()
		max_frame_rate_label.text = "Max: %f" % _max_fps
	if Engine.get_frames_per_second() < _min_fps and Engine.get_frames_per_second() > 10:
		_min_fps = Engine.get_frames_per_second()
		min_frame_rate_label.text = "Min: %f" %_min_fps

func _on_ResetButton_pressed():
	_seconds_since_startup = 0.0
	_frames_drawn_offset = Engine.get_frames_drawn()
	_min_fps = 10000000
	_max_fps = 0.0

func hide_WIP_label():
	$"WIP Label".hide()
func show_WIP_label():
	$"WIP Label".show()
