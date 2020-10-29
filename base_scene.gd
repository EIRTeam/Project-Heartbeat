extends Control

onready var status_label = get_node("VBoxContainer/StatusLabel")
const MAIN_MENU = preload("res://menus/MainMenu3D.tscn")

const LOADINGU_SPEED = 0.5
var loadingu_t = 0
var timer = Timer.new()
func _ready():
	SongLoader.connect("all_songs_loaded", timer, "start")
	if SongLoader.initial_load_done:
		call_deferred("_on_songs_finished_loading")
	set_status("Loadingu...")
	add_child(timer)
	timer.wait_time = 0.3
	timer.connect("timeout", self, "_on_songs_finished_loading")
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		VisualServer.viewport_set_hdr(get_viewport().get_viewport_rid(), false)
func set_status(status: String):
	status_label.text = status

func _process(delta):
	loadingu_t += delta * LOADINGU_SPEED
	
	status_label.percent_visible = fmod(loadingu_t, 1.5)

func _on_songs_finished_loading():
	set_status("Loading main menu...")
	var new_scene = MAIN_MENU.instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
