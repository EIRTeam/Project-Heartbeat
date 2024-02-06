extends Control

@onready var status_label = get_node("VBoxContainer/StatusLabel")
const MAIN_MENU = preload("res://menus/MainMenu3D.tscn")

const LOADINGU_SPEED = 0.5
var loadingu_t = 0
@onready var timer = Timer.new()

var loading_editor = false

func _ready():
	if "--song-editor" in OS.get_cmdline_args():
		loading_editor = true
	
	SongLoader.connect("all_songs_loaded", Callable(timer, "start"))
	if SongLoader.initial_load_done:
		call_deferred("_on_songs_finished_loading")
	set_status("Loadingu...")
	add_child(timer)
	timer.wait_time = 0.3
	timer.connect("timeout", Callable(self, "_on_songs_finished_loading"))
#	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
#		RenderingServer.viewport_set_hdr(get_viewport().get_viewport_rid(), false)
func set_status(status: String):
	status_label.text = status

func _process(delta):
	loadingu_t += delta * LOADINGU_SPEED
	
	status_label.percent_visible = fmod(loadingu_t, 1.5)

func _on_main_scene_finished_loading(scene):
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene

func _on_songs_finished_loading():
	set_status("Loading main menu...")
	if loading_editor:
		set_status("Loading editor...")
		
	var main_path = "res://menus/MainMenu3D.tscn"
		
	if loading_editor:
		main_path = "res://tools/editor/Editor.tscn"
		
#	var main_scene_load_task = HBLoadMainMenuTask.new(main_path)
#
#	main_scene_load_task.connect("task_done", self, "_on_main_scene_finished_loading")
#
#	AsyncTaskQueue.queue_task(main_scene_load_task)

	_on_main_scene_finished_loading(load(main_path).instantiate())
