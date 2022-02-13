extends CanvasLayer

var _seconds_since_startup = 0.0
var _frames_drawn_offset = 0.0
var _max_fps = 0.0
var _min_fps = 10000000
var enable_autoplay = false setget set_autoplay
var known_log_names = []
# LogCaller : message dict
var log_messages = {}
func set_autoplay(value):
	enable_autoplay = value

onready var frame_rate_label = get_node("WindowDialog/TabContainer/Game/VBoxContainer/HBoxContainer/VBoxContainer/FrameRateLabel")
onready var average_frame_rate_label = get_node("WindowDialog/TabContainer/Game/VBoxContainer/HBoxContainer/VBoxContainer/AVGFrameRateLabel")
onready var min_frame_rate_label = get_node("WindowDialog/TabContainer/Game/VBoxContainer/HBoxContainer/VBoxContainer/MinFrameRateLabel")
onready var max_frame_rate_label = get_node("WindowDialog/TabContainer/Game/VBoxContainer/HBoxContainer/VBoxContainer/MaxFrameRateLabel")
onready var autoplay_checkbox = get_node("WindowDialog/TabContainer/Game/VBoxContainer/AutoplayCheckbox")
onready var log_filter_option_button = get_node("WindowDialog/TabContainer/Logs/VBoxContainer/HBoxContainer/LogFilterOptionButton")
onready var log_rich_text_label = get_node("WindowDialog/TabContainer/Logs/VBoxContainer/ScrollContainer/RichTextLabel")
onready var log_level_filter_option_button = get_node("WindowDialog/TabContainer/Logs/VBoxContainer/HBoxContainer/LogLevelFilterOptionButton")
onready var fps_label = get_node("FPSLabel")
onready var gamepad_visualizer = get_node("GamepadVisualizer")
onready var network_tree = get_node("WindowDialog/TabContainer/Network/VBoxContainer/HSplitContainer/Tree")
onready var tree_root = network_tree.create_item()
onready var network_body_RTL = get_node("WindowDialog/TabContainer/Network/VBoxContainer/HSplitContainer/RichTextLabel")
onready var auth_token_button = get_node("WindowDialog/TabContainer/Network/VBoxContainer/AuthTokenButton")
onready var instance_id_spinbox = get_node("WindowDialog/TabContainer/Game/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/InstanceID")
onready var property_name_line_edit = get_node("WindowDialog/TabContainer/Game/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/PropertyName")

var logging_enabled: bool = "--logging-enabled" in OS.get_cmdline_args()

func _ready():
	Log.connect("message_logged", self, "_on_message_logged")
	autoplay_checkbox.connect("toggled", self, "set_autoplay")
	$WindowDialog.hide()
	fps_label.hide()
	gamepad_visualizer.hide()
	network_tree.hide_root = true
	network_tree.connect("item_selected", self, "_on_network_item_selected")
	HBBackend.connect("diagnostics_response_received", self, "_on_response_received")
	HBBackend.connect("diagnostics_created_request", self, "_on_request_created")
	auth_token_button.connect("pressed", self, "_on_auth_token_button_pressed")
	$WindowDialog.connect("visibility_changed", self, "_on_visibility_changed")
	
func _on_visibility_changed():
	if $WindowDialog.visible:
		show_log_messages()
	
func _on_auth_token_button_pressed():
	OS.clipboard = HBBackend.jwt_token
	
func _on_request_created(request_data: HBBackend.RequestData):
	var item = network_tree.create_item(tree_root)
	item.set_text(0, "%s - %s"  % [request_data.method, request_data.url])
	item.set_meta("request", request_data)
	
func _on_response_received(response_data: HBBackend.ResponseData):
	var response_name = "%d - %s" % [response_data.code, HBUtils.find_key(HBBackend.REQUEST_TYPE, response_data.request_type)]
	var item = network_tree.create_item(tree_root)
	item.set_text(0, response_name)
	item.set_meta("response_body", response_data.body)
func _on_network_item_selected():
	var item = network_tree.get_selected()
	if item.has_meta("request"):
		var request = item.get_meta("request")
		var headers = ""
		if request.headers is String:
			headers = request.headers
		elif request.headers is Array:
			headers = PoolStringArray(request.headers).join("\n")
		network_body_RTL.text = "%s\n%s" % [headers, request.body]
	else:
		var body = item.get_meta("response_body")
		network_body_RTL.text = body
func _input(event):
	if event.is_action_pressed("toggle_diagnostics"):
		var window_size = get_viewport().size * 0.75
		$WindowDialog.rect_size = window_size
		$WindowDialog.rect_position = get_viewport().size / 8.0
		$WindowDialog.visible = !$WindowDialog.visible
	if event.is_action_pressed("toggle_fps"):
		fps_label.visible = !fps_label.visible
	if event.is_action_pressed("take_screenshot"):
		var img = get_viewport().get_texture().get_data()
		# Flip it on the y-axis (because it's flipped).
		img.flip_y()
		img.convert(Image.FORMAT_RGBA8)
		var dir = Directory.new()
		if not dir.dir_exists("user://debug_screenshot"):
			dir.make_dir("user://debug_screenshot")
		img.save_png("user://debug_screenshot/%d.png" % [OS.get_unix_time()])
	if event.is_action_pressed("toggle_gamepad_view"):
		gamepad_visualizer.visible = !gamepad_visualizer.visible 
func _process(delta):
	_seconds_since_startup += delta
	frame_rate_label.text = "FPS: %f" % Engine.get_frames_per_second()
	fps_label.text = "FPS: %.0f\nAudio Latency: %.2f ms" % [Engine.get_frames_per_second(), AudioServer.get_output_latency() * 1000.0]
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

func show_log_messages():
	if not $WindowDialog.visible:
		return
	yield(get_tree(), "idle_frame")
	var messages_to_show = []
	var selected_log_filter = log_filter_option_button.get_item_text(log_filter_option_button.selected)
	if log_filter_option_button.selected > 0:
		messages_to_show = log_messages[selected_log_filter]
	else:
		for log_values in log_messages.values():
			messages_to_show += log_values
			
	var messages = ""
	
	for message in messages_to_show:
		var log_level = log_level_filter_option_button.selected
		if message.log_level <= log_level:
			var color = "aqua"
			if message.log_level == Log.LogLevel.ERROR:
				color = "red"
			elif message.log_level == Log.LogLevel.WARN:
				color = "yellow"
			messages += "[color=%s][%s][/color] %s: %s\n" % [color, HBUtils.find_key(Log.LogLevel, message.log_level), message.caller, message.message]
	var text_label_text = "[code]%s[/code]" % messages
	log_rich_text_label.bbcode_text = text_label_text
func _on_message_logged(logger_name, message, log_level):
	if not logger_name in known_log_names:
		known_log_names.append(logger_name)
		log_filter_option_button.add_item(logger_name)
	if not log_messages.has(logger_name):
		log_messages[logger_name] = []
	log_messages[logger_name].append({"caller": logger_name, "message": message, "log_level": log_level})
	show_log_messages()

func _on_LogFilterOptionButton_item_selected(id):
	show_log_messages()


func _on_PrintOrphanedNodesButton_pressed():
	print_stray_nodes()


func _on_PrintPropertyValue_pressed():
	print(instance_from_id(int(instance_id_spinbox.value)).get(property_name_line_edit.text))


func _on_OpenStrayNodeTester_pressed():
		var scene = preload("res://tools/MemoryLeakTester.tscn").instance()
		get_tree().current_scene.queue_free()
		get_tree().root.add_child(scene)
		get_tree().current_scene = scene


func _on_TransparentViewport_toggled(button_pressed):
	get_viewport().transparent_bg = button_pressed
